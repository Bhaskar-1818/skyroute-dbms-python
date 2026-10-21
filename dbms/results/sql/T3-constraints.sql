-- T4 : constraint refusals. Run with --force so every check still executes.
-- Each statement is expected to FAIL; the error line is the evidence.
USE skyroute_db;

-- C-a  duplicate (departure_id, seat_number)  -> ERROR 1062
INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
SELECT passenger_id, departure_id, seat_number, travel_class, price
FROM Bookings LIMIT 1;

-- C-b  departure airport = arrival airport      -> ERROR 1644 (trigger)
INSERT INTO Flights (flight_number, airline_id, departure_airport_id,
                     arrival_airport_id, sched_departure, sched_arrival)
VALUES ('XX-000', 1, 1, 1, '10:00:00', '12:00:00');

-- C-c  bag weight zero                          -> CHECK violation
INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (1, 99, 0);

-- C-d  delete an airport that still has flights -> ERROR 1451 RESTRICT
DELETE FROM Airports WHERE airport_id = 1;
