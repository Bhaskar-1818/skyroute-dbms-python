-- T5 : stored procedure + capacity trigger. Run with --force.
-- Uses only objects that exist in skyroute_db (the DBMS schema).
USE skyroute_db;

-- T-a  a free seat books and opens a Pending payment in one call
SET @d := (SELECT d.departure_id
           FROM Departures d
           JOIN Aircraft a ON d.aircraft_id = a.aircraft_id
           WHERE (SELECT COUNT(*) FROM Bookings b
                  WHERE b.departure_id = d.departure_id) < a.capacity
           ORDER BY d.departure_id LIMIT 1);
SELECT @d AS chosen_departure;

CALL MakeBooking(1, @d, '99Z', 'Economy', 4500.00, @id);
SELECT @id AS new_booking_id;
SELECT seat_number, travel_class, price FROM Bookings WHERE booking_id = @id;
SELECT pay_status, pay_method FROM Payments WHERE booking_id = @id;

-- T-b  the same seat again must fail and insert nothing   -> ERROR 1062
CALL MakeBooking(1, @d, '99Z', 'Economy', 4500.00, @id2);
SELECT COUNT(*) AS rows_with_seat_99Z
FROM Bookings WHERE seat_number = '99Z' AND departure_id = @d;

-- T-c  capacity trigger: shrink the aircraft to the seats already sold
SET @ac   := (SELECT aircraft_id FROM Departures WHERE departure_id = @d);
SET @sold := (SELECT COUNT(*) FROM Bookings WHERE departure_id = @d);
UPDATE Aircraft SET capacity = @sold WHERE aircraft_id = @ac;
INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
VALUES (1, @d, '98Z', 'Economy', 4500.00);      -- ERROR 45000 'fully booked'
UPDATE Aircraft SET capacity = 180 WHERE aircraft_id = @ac;

-- cleanup: remove the booking T-a created so the seed stays untouched
DELETE FROM Bookings WHERE booking_id = @id;
SELECT COUNT(*) AS rows_with_seat_99Z_after_cleanup
FROM Bookings WHERE seat_number = '99Z' AND departure_id = @d;

SELECT COUNT(*) AS total_bookings_unchanged FROM Bookings;
