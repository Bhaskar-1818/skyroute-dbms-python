-- Queries 01 v2 : JOIN pack - every module joined at least once (MySQL 8.0)
-- Run from dbms/ after the seed :  SOURCE queries/01-joins.sql;
USE skyroute_db;

-- J1: Full flight board - timetable + airports + airline (INNER JOIN core).
SELECT f.flight_number, al.airline_name,
       dep.iata_code AS from_airport, arr.iata_code AS to_airport,
       f.sched_departure, f.sched_arrival, f.flight_status
FROM Flights f
JOIN Airlines al ON f.airline_id = al.airline_id
JOIN Airports dep ON f.departure_airport_id = dep.airport_id
JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
ORDER BY f.flight_number LIMIT 20;

-- J2: Dated departures with aircraft, gate, terminal (multi JOIN).
SELECT d.departure_id, f.flight_number, d.scheduled_departure,
       ac.tail_number, ac.model, g.gate_number, t.terminal_code,
       d.departure_status
FROM Departures d
JOIN Flights f   ON d.flight_id = f.flight_id
JOIN Aircraft ac ON d.aircraft_id = ac.aircraft_id
JOIN Gates g     ON d.gate_id = g.gate_id
JOIN Terminals t ON g.terminal_id = t.terminal_id
ORDER BY d.scheduled_departure LIMIT 20;

-- J3: Passenger manifest for one departure (booking bridge).
SELECT b.seat_number, p.first_name, p.last_name, b.travel_class,
       b.price, b.booking_status
FROM Bookings b
JOIN Passengers p ON b.passenger_id = p.passenger_id
WHERE b.departure_id = 1
ORDER BY b.seat_number;

-- J4: Booking money trail - booking + payment + check-in + bags (LEFT JOIN:
-- a booking may have no bags or no check-in yet, and must still appear).
SELECT b.booking_id, b.seat_number, b.price,
       pay.pay_status, pay.pay_method,
       c.boarding_status,
       COUNT(bg.baggage_seq) AS bags,
       COALESCE(SUM(bg.weight_kg), 0) AS total_bag_kg
FROM Bookings b
LEFT JOIN Payments pay ON b.booking_id = pay.booking_id
LEFT JOIN Check_Ins c ON b.booking_id = c.booking_id
LEFT JOIN Baggage bg  ON b.booking_id = bg.booking_id
WHERE b.departure_id = 1
GROUP BY b.booking_id
ORDER BY b.seat_number LIMIT 20;

-- J5: Pilots with licence (supertype + subtype JOIN).
SELECT e.full_name, pl.license_number, pl.license_type, a.iata_code AS base
FROM Employees e
JOIN Pilots pl ON e.employee_id = pl.employee_id
LEFT JOIN Airports a ON e.base_airport = a.airport_id
ORDER BY e.full_name;

-- J6: Ground staff by airport (who works where).
SELECT a.iata_code, e.full_name, gs.ground_role
FROM Ground_Staff gs
JOIN Employees e ON gs.employee_id = e.employee_id
JOIN Airports a  ON gs.airport_id = a.airport_id
ORDER BY a.iata_code, e.full_name;

-- J7: Airport infrastructure map - terminal and gates per airport.
SELECT a.iata_code, t.terminal_code, g.gate_number, g.gate_status
FROM Airports a
JOIN Terminals t ON a.airport_id = t.airport_id
JOIN Gates g     ON t.terminal_id = g.terminal_id
ORDER BY a.iata_code, g.gate_number;

-- J8: Aircraft fleet per airline with capacity.
SELECT al.airline_name, ac.tail_number, ac.model, ac.capacity
FROM Aircraft ac
JOIN Airlines al ON ac.airline_id = al.airline_id
ORDER BY al.airline_name, ac.tail_number;

-- J9: Overweight bags with owner + flight (fee demo source rows).
SELECT p.first_name, p.last_name, f.flight_number, d.scheduled_departure,
       bg.baggage_seq, bg.weight_kg,
       ROUND((bg.weight_kg - 20) * 500, 2) AS excess_fee_rs
FROM Baggage bg
JOIN Bookings b   ON bg.booking_id = b.booking_id
JOIN Passengers p ON b.passenger_id = p.passenger_id
JOIN Departures d ON b.departure_id = d.departure_id
JOIN Flights f    ON d.flight_id = f.flight_id
WHERE bg.weight_kg > 20
ORDER BY bg.weight_kg DESC LIMIT 20;

-- J10: Crew directory - everyone with their role in one list.
SELECT e.full_name, e.email,
       COALESCE(pl.license_number, cm.crew_role, gs.ground_role) AS credential,
       a.iata_code AS base
FROM Employees e
LEFT JOIN Pilots pl       ON e.employee_id = pl.employee_id
LEFT JOIN Crew_Members cm ON e.employee_id = cm.employee_id
LEFT JOIN Ground_Staff gs ON e.employee_id = gs.employee_id
LEFT JOIN Airports a      ON e.base_airport = a.airport_id
ORDER BY e.full_name;
