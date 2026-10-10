-- ============================================================================
-- Queries 01 : JOIN pack - every module joined at least once (MySQL 8.0)
-- Run : SOURCE 01-joins.sql;   (after seed_data.sql)
-- ============================================================================
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

-- J2: Dated departures with aircraft, gate, terminal, runway (multi JOIN).
SELECT fi.instance_id, f.flight_number, fi.scheduled_departure,
       ac.tail_number, ac.model, g.gate_number, t.terminal_code,
       r.runway_code, fi.instance_status
FROM Flight_Instances fi
JOIN Flights f   ON fi.flight_id = f.flight_id
JOIN Aircraft ac ON fi.aircraft_id = ac.aircraft_id
JOIN Gates g     ON fi.gate_id = g.gate_id
JOIN Terminals t ON g.terminal_id = t.terminal_id
JOIN Runways r   ON fi.runway_id = r.runway_id
ORDER BY fi.scheduled_departure LIMIT 20;

-- J3: Passenger manifest for one instance (booking bridge).
SELECT b.seat_number, p.first_name, p.last_name, b.travel_class,
       b.price, b.booking_status
FROM Bookings b
JOIN Passengers p ON b.passenger_id = p.passenger_id
WHERE b.instance_id = 1
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
WHERE b.instance_id = 1
GROUP BY b.booking_id
ORDER BY b.seat_number LIMIT 20;

-- J5: Crew roster per flight (supertype + subtype + assignment JOINs).
SELECT f.flight_number, fi.scheduled_departure,
       e.full_name, cm.crew_role, ca.role_on_flight
FROM Crew_Assignments ca
JOIN Employees e     ON ca.employee_id = e.employee_id
JOIN Crew_Members cm ON e.employee_id = cm.employee_id
JOIN Flight_Instances fi ON ca.instance_id = fi.instance_id
JOIN Flights f       ON fi.flight_id = f.flight_id
ORDER BY fi.scheduled_departure LIMIT 20;

-- J6: Pilots with licence + their assigned flights.
SELECT e.full_name, pl.license_number, pl.license_type,
       f.flight_number, fi.scheduled_departure, ca.role_on_flight
FROM Employees e
JOIN Pilots pl ON e.employee_id = pl.employee_id
JOIN Crew_Assignments ca ON e.employee_id = ca.employee_id
JOIN Flight_Instances fi ON ca.instance_id = fi.instance_id
JOIN Flights f ON fi.flight_id = f.flight_id
ORDER BY fi.scheduled_departure LIMIT 20;

-- J7: Ground staff by airport (who works where).
SELECT a.iata_code, e.full_name, gs.ground_role
FROM Ground_Staff gs
JOIN Employees e ON gs.employee_id = e.employee_id
JOIN Airports a  ON gs.airport_id = a.airport_id
ORDER BY a.iata_code, e.full_name;

-- J8: Airport infrastructure map - terminal, gates, runway per airport.
SELECT a.iata_code, t.terminal_code, g.gate_number, g.gate_status,
       r.runway_code, r.runway_status
FROM Airports a
JOIN Terminals t ON a.airport_id = t.airport_id
JOIN Gates g     ON t.terminal_id = g.terminal_id
JOIN Runways r   ON a.airport_id = r.airport_id
ORDER BY a.iata_code, g.gate_number;

-- J9: Aircraft fleet per airline with capacity.
SELECT al.airline_name, ac.tail_number, ac.model, ac.capacity
FROM Aircraft ac
JOIN Airlines al ON ac.airline_id = al.airline_id
ORDER BY al.airline_name, ac.tail_number;

-- J10: Overweight bags with owner + flight (fee demo source rows).
SELECT p.first_name, p.last_name, f.flight_number, fi.scheduled_departure,
       bg.baggage_seq, bg.weight_kg,
       ROUND((bg.weight_kg - 20) * 500, 2) AS excess_fee_rs
FROM Baggage bg
JOIN Bookings b   ON bg.booking_id = b.booking_id
JOIN Passengers p ON b.passenger_id = p.passenger_id
JOIN Flight_Instances fi ON b.instance_id = fi.instance_id
JOIN Flights f    ON fi.flight_id = f.flight_id
WHERE bg.weight_kg > 20
ORDER BY bg.weight_kg DESC LIMIT 20;
