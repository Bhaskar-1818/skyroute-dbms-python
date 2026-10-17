-- SkyRoute Flask demo : database-side views + booking procedure (MySQL 8.0).
-- Loaded by seed_mysql.py right after schema_mysql.sql. Statements are
-- separated by marker lines (see the two dashes + at-signs below); each
-- block is sent to MySQL as ONE statement (that is how the stored procedure
-- keeps its internal semicolons). Why this file exists: the multi-table
-- JOINs behind search, my-bookings, the booking page and the staff
-- manifest live here as views, and booking creation is the stored
-- procedure sp_make_booking, so those app.py routes only run plain
-- single-table SQL.
DROP PROCEDURE IF EXISTS sp_make_booking;

-- @@

CREATE OR REPLACE VIEW v_departure_board AS
SELECT d.departure_id,
       f.flight_number,
       al.airline_name,
       d.scheduled_departure,
       d.scheduled_arrival,
       g.gate_number,
       d.departure_status,
       (SELECT COUNT(*) FROM Bookings b
         WHERE b.departure_id = d.departure_id
           AND b.booking_status != 'Cancelled') AS sold,
       ac.capacity,
       ac.model,
       dep.iata_code AS from_airport,
       arr.iata_code AS to_airport,
       dep.city AS from_city,
       arr.city AS to_city
  FROM Departures d
  JOIN Flights f ON d.flight_id = f.flight_id
  JOIN Airlines al ON f.airline_id = al.airline_id
  JOIN Airports dep ON f.departure_airport_id = dep.airport_id
  JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
  LEFT JOIN Aircraft ac ON d.aircraft_id = ac.aircraft_id
  LEFT JOIN Gates g ON d.gate_id = g.gate_id;

-- @@

CREATE OR REPLACE VIEW v_departure_detail AS
SELECT d.departure_id,
       d.flight_id,
       f.flight_number,
       al.airline_name,
       d.scheduled_departure,
       d.scheduled_arrival,
       d.departure_status,
       g.gate_number,
       ac.capacity,
       ac.model,
       dep.iata_code AS from_airport,
       arr.iata_code AS to_airport
  FROM Departures d
  JOIN Flights f ON d.flight_id = f.flight_id
  JOIN Airlines al ON f.airline_id = al.airline_id
  JOIN Airports dep ON f.departure_airport_id = dep.airport_id
  JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
  LEFT JOIN Aircraft ac ON d.aircraft_id = ac.aircraft_id
  LEFT JOIN Gates g ON d.gate_id = g.gate_id;

-- @@

CREATE OR REPLACE VIEW v_booking_list AS
SELECT b.booking_id,
       b.passenger_id,
       p.first_name,
       p.last_name,
       f.flight_number,
       d.scheduled_departure,
       d.scheduled_arrival,
       dep.iata_code AS from_airport,
       arr.iata_code AS to_airport,
       g.gate_number,
       b.seat_number,
       b.travel_class,
       b.price,
       b.booking_status,
       pay.pay_status,
       (SELECT COUNT(*) FROM Baggage bg
         WHERE bg.booking_id = b.booking_id) AS bags,
       COALESCE((SELECT SUM(bg.weight_kg) FROM Baggage bg
                 WHERE bg.booking_id = b.booking_id), 0) AS bag_kg,
       COALESCE((SELECT ROUND(SUM(GREATEST(bg.weight_kg - 20, 0)) * 500, 2)
                 FROM Baggage bg
                 WHERE bg.booking_id = b.booking_id), 0) AS fee,
       (SELECT ci.boarding_status FROM Check_Ins ci
         WHERE ci.booking_id = b.booking_id) AS boarding
  FROM Bookings b
  JOIN Passengers p ON b.passenger_id = p.passenger_id
  JOIN Departures d ON b.departure_id = d.departure_id
  JOIN Flights f ON d.flight_id = f.flight_id
  JOIN Airports dep ON f.departure_airport_id = dep.airport_id
  JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
  LEFT JOIN Gates g ON d.gate_id = g.gate_id
  LEFT JOIN Payments pay ON b.booking_id = pay.booking_id;

-- @@

CREATE OR REPLACE VIEW v_manifest AS
SELECT b.booking_id,
       b.seat_number,
       b.travel_class,
       b.price,
       b.booking_status,
       b.passenger_id,
       p.first_name,
       p.last_name,
       pay.pay_status,
       (SELECT ci.boarding_status FROM Check_Ins ci
         WHERE ci.booking_id = b.booking_id) AS boarding,
       (SELECT COUNT(*) FROM Baggage bg
         WHERE bg.booking_id = b.booking_id) AS bags,
       COALESCE((SELECT SUM(bg.weight_kg) FROM Baggage bg
                 WHERE bg.booking_id = b.booking_id), 0) AS bag_kg,
       COALESCE((SELECT ROUND(SUM(GREATEST(bg.weight_kg - 20, 0)) * 500, 2)
                 FROM Baggage bg
                 WHERE bg.booking_id = b.booking_id), 0) AS fee,
       b.departure_id
  FROM Bookings b
  JOIN Passengers p ON b.passenger_id = p.passenger_id
  LEFT JOIN Payments pay ON b.booking_id = pay.booking_id;

-- @@

CREATE OR REPLACE VIEW v_flight_list AS
SELECT f.*, al.airline_name
  FROM Flights f
  JOIN Airlines al ON f.airline_id = al.airline_id;

-- @@

-- One call books a seat AND opens its payment, atomically (all-or-nothing).
-- A cancelled booking still holds its (departure_id, seat_number) key until
-- it is cleared, so the DELETE below frees the seat first; the old payment,
-- bags and check-in vanish with it via ON DELETE CASCADE. The EXIT handler
-- rolls everything back and re-raises the original error, so a duplicate
-- seat reaches the app as a plain integrity error - which app.py already
-- reports as "seat was just taken".
CREATE PROCEDURE sp_make_booking(
  IN p_passenger_id INT,
  IN p_departure_id INT,
  IN p_seat VARCHAR(8),
  IN p_class VARCHAR(24),
  IN p_price DOUBLE,
  OUT p_booking_id INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  DELETE FROM Bookings
   WHERE departure_id = p_departure_id
     AND seat_number = p_seat
     AND booking_status = 'Cancelled';
  INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
  VALUES (p_passenger_id, p_departure_id, p_seat, p_class, p_price);
  SET p_booking_id = LAST_INSERT_ID();
  INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference)
  VALUES (p_booking_id, p_price, 'UPI', 'Pending', CONCAT('TXNAPP', 100000 + p_booking_id));
END;
