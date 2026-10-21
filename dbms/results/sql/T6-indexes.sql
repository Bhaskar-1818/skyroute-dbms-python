-- T7 : query cost before and after each index (Step 10 evidence).
USE skyroute_db;

-- I1 booking_status -----------------------------------------------------
EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';
DROP INDEX idx_bookings_status ON Bookings;
EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';
CREATE INDEX idx_bookings_status ON Bookings (booking_status);
EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';

-- I2 scheduled_departure ------------------------------------------------
EXPLAIN SELECT * FROM Departures
 WHERE scheduled_departure BETWEEN '2026-11-03 00:00:00' AND '2026-11-03 23:59:59';
DROP INDEX idx_departures_date ON Departures;
EXPLAIN SELECT * FROM Departures
 WHERE scheduled_departure BETWEEN '2026-11-03 00:00:00' AND '2026-11-03 23:59:59';
CREATE INDEX idx_departures_date ON Departures (scheduled_departure);
EXPLAIN SELECT * FROM Departures
 WHERE scheduled_departure BETWEEN '2026-11-03 00:00:00' AND '2026-11-03 23:59:59';

-- I3 passengers name ----------------------------------------------------
EXPLAIN SELECT * FROM Passengers WHERE last_name = 'Sharma';
DROP INDEX idx_passengers_name ON Passengers;
EXPLAIN SELECT * FROM Passengers WHERE last_name = 'Sharma';
CREATE INDEX idx_passengers_name ON Passengers (last_name, first_name);
EXPLAIN SELECT * FROM Passengers WHERE last_name = 'Sharma';

-- I4 baggage weight -----------------------------------------------------
EXPLAIN SELECT * FROM Baggage WHERE weight_kg > 20;
DROP INDEX idx_baggage_weight ON Baggage;
EXPLAIN SELECT * FROM Baggage WHERE weight_kg > 20;
CREATE INDEX idx_baggage_weight ON Baggage (weight_kg);
EXPLAIN SELECT * FROM Baggage WHERE weight_kg > 20;

SHOW INDEX FROM Bookings;
