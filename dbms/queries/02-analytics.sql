-- Queries 02 v2 : analytics - GROUP BY / HAVING / subqueries.
-- These only become interesting at volume: meaningless on 3 rows, decisive on 14k.
USE skyroute_db;

-- A1: Busiest routes by bookings (JOIN + GROUP BY + ORDER BY + LIMIT).
SELECT CONCAT(dep.iata_code, ' -> ', arr.iata_code) AS route,
       COUNT(*) AS bookings
FROM Bookings b
JOIN Departures d ON b.departure_id = d.departure_id
JOIN Flights f    ON d.flight_id = f.flight_id
JOIN Airports dep ON f.departure_airport_id = dep.airport_id
JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
GROUP BY route
ORDER BY bookings DESC;

-- A2: Load factor per flight (booked seats vs aircraft capacity, HAVING demo).
SELECT f.flight_number,
       COUNT(DISTINCT d.departure_id) AS departures,
       COUNT(b.booking_id) AS seats_sold,
       ROUND(COUNT(b.booking_id) /
             (COUNT(DISTINCT d.departure_id) * MAX(ac.capacity)) * 100, 1) AS load_pct
FROM Flights f
JOIN Departures d ON f.flight_id = d.flight_id
JOIN Aircraft ac ON d.aircraft_id = ac.aircraft_id
LEFT JOIN Bookings b ON d.departure_id = b.departure_id
GROUP BY f.flight_number
HAVING load_pct < 60
ORDER BY load_pct;

-- A3: Revenue per flight (SUM + GROUP BY).
SELECT f.flight_number, SUM(b.price) AS revenue_rs, COUNT(*) AS tickets
FROM Bookings b
JOIN Departures d ON b.departure_id = d.departure_id
JOIN Flights f ON d.flight_id = f.flight_id
WHERE b.booking_status = 'Confirmed'
GROUP BY f.flight_number
ORDER BY revenue_rs DESC;

-- A4: Overweight-baggage fee revenue (problem statement #3, in one query).
-- Free allowance 20 kg, Rs 500 per excess kg.
SELECT COUNT(*) AS overweight_bags,
       ROUND(SUM((weight_kg - 20) * 500), 2) AS fee_revenue_rs
FROM Baggage
WHERE weight_kg > 20;

-- A5: Gate utilisation per airport (which gates work hardest).
SELECT a.iata_code, g.gate_number, COUNT(*) AS departures_handled
FROM Departures d
JOIN Gates g ON d.gate_id = g.gate_id
JOIN Terminals t ON g.terminal_id = t.terminal_id
JOIN Airports a ON t.airport_id = a.airport_id
GROUP BY a.iata_code, g.gate_number
ORDER BY a.iata_code, departures_handled DESC;

-- A6: Passengers above the average spend (subquery demo).
SELECT p.first_name, p.last_name, SUM(b.price) AS total_spent_rs
FROM Bookings b
JOIN Passengers p ON b.passenger_id = p.passenger_id
GROUP BY p.passenger_id
HAVING total_spent_rs > (SELECT AVG(price) FROM Bookings)
ORDER BY total_spent_rs DESC LIMIT 15;

-- A7: Daily operations snapshot (date function + GROUP BY).
SELECT DATE(scheduled_departure) AS op_date,
       COUNT(*) AS departures,
       SUM(CASE WHEN departure_status = 'Arrived' THEN 1 ELSE 0 END) AS arrived,
       SUM(CASE WHEN departure_status = 'Scheduled' THEN 1 ELSE 0 END) AS upcoming
FROM Departures
GROUP BY op_date
ORDER BY op_date;

-- A8: Unpaid bookings needing follow-up (JOIN + filter).
SELECT b.booking_id, p.first_name, p.last_name, b.price, pay.pay_status
FROM Bookings b
JOIN Passengers p ON b.passenger_id = p.passenger_id
JOIN Payments pay ON b.booking_id = pay.booking_id
WHERE pay.pay_status = 'Pending'
ORDER BY b.price DESC LIMIT 15;
