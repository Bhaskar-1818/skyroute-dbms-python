-- ============================================================================
-- Advanced 03 : views + trigger + stored procedure  (MySQL 8.0)
-- Run : SOURCE 03-advanced.sql;
-- C12: Defence in depth. UNIQUE stops duplicate SEATS, the TRIGGER stops
-- over-CAPACITY sales. Two different rules, two different enforcers.
-- ============================================================================
USE skyroute_db;

-- V1: Departure board - one view serving the whole "search flights" need.
CREATE OR REPLACE VIEW flight_board_view AS
SELECT fi.instance_id, f.flight_number, al.airline_name,
       dep.iata_code AS from_airport, arr.iata_code AS to_airport,
       fi.scheduled_departure, fi.scheduled_arrival,
       ac.tail_number, g.gate_number, t.terminal_code,
       fi.instance_status
FROM Flight_Instances fi
JOIN Flights f   ON fi.flight_id = f.flight_id
JOIN Airlines al ON f.airline_id = al.airline_id
JOIN Airports dep ON f.departure_airport_id = dep.airport_id
JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
LEFT JOIN Aircraft ac ON fi.aircraft_id = ac.aircraft_id
LEFT JOIN Gates g     ON fi.gate_id = g.gate_id
LEFT JOIN Terminals t ON g.terminal_id = t.terminal_id;

-- V2: Booking receipt - price plus computed baggage fee in one row.
-- Fee rule (problem statement #3): 20 kg free, Rs 500 per excess kg per bag.
CREATE OR REPLACE VIEW booking_receipt_view AS
SELECT b.booking_id,
       CONCAT(p.first_name, ' ', p.last_name) AS passenger,
       f.flight_number, fi.scheduled_departure,
       b.seat_number, b.travel_class, b.price, b.booking_status,
       pay.pay_status,
       COALESCE(
         (SELECT SUM(GREATEST(weight_kg - 20, 0)) * 500
          FROM Baggage WHERE booking_id = b.booking_id), 0
       ) AS baggage_fee_rs
FROM Bookings b
JOIN Passengers p      ON b.passenger_id = p.passenger_id
JOIN Flight_Instances fi ON b.instance_id = fi.instance_id
JOIN Flights f         ON fi.flight_id = f.flight_id
LEFT JOIN Payments pay ON b.booking_id = pay.booking_id;

DELIMITER //

-- T1: Capacity guard. Fires BEFORE every booking insert, including inserts
-- made by the procedure below and by any future app code. No app can
-- oversell a flight, because the rule lives in the database, not the app.
CREATE TRIGGER trg_booking_capacity
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
  DECLARE sold INT DEFAULT 0;
  DECLARE cap  INT DEFAULT NULL;
  SELECT COUNT(*) INTO sold FROM Bookings WHERE instance_id = NEW.instance_id;
  SELECT a.capacity INTO cap
  FROM Flight_Instances fi
  JOIN Aircraft a ON fi.aircraft_id = a.aircraft_id
  WHERE fi.instance_id = NEW.instance_id;
  IF cap IS NOT NULL AND sold >= cap THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Booking refused: flight is fully booked';
  END IF;
END//

-- P1: One call books a seat AND opens its payment together. If either fails,
-- the EXIT HANDLER rolls everything back: never a booking without payment,
-- never a payment without booking. Call it like:
--   CALL MakeBooking(1, 1, '1A', 'Economy', 4500.00, @id); SELECT @id;
CREATE PROCEDURE MakeBooking(
  IN  p_passenger_id INT,
  IN  p_instance_id  INT,
  IN  p_seat         VARCHAR(5),
  IN  p_class        VARCHAR(20),
  IN  p_price        DECIMAL(10,2),
  OUT p_booking_id   INT
)
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;
  START TRANSACTION;
  INSERT INTO Bookings (passenger_id, instance_id, seat_number, travel_class, price)
    VALUES (p_passenger_id, p_instance_id, p_seat, p_class, p_price);
  SET p_booking_id = LAST_INSERT_ID();
  INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference, paid_at)
    VALUES (p_booking_id, p_price, 'UPI', 'Pending',
            CONCAT('TXN-WEB-', p_booking_id, '-', UNIX_TIMESTAMP()), NOW());
  COMMIT;
END//

DELIMITER ;

-- Smoke tests (run these, screenshot the outputs):
-- SELECT * FROM flight_board_view LIMIT 5;
-- SELECT * FROM booking_receipt_view LIMIT 5;
-- CALL MakeBooking(1, 2, '30F', 'Economy', 4500.00, @id); SELECT @id;
-- INSERT INTO Bookings (passenger_id, instance_id, seat_number) VALUES (1, 1, '12A');
--    (re-run an existing seat: expect ERROR 1062 duplicate entry)
