-- ============================================================================
-- Queries 03 : admin - structure + row counts (health check + screenshot set)
-- ============================================================================
USE skyroute_db;

SHOW TABLES;

SELECT 'Airports' AS tbl, COUNT(*) AS rows FROM Airports
UNION ALL SELECT 'Airlines', COUNT(*) FROM Airlines
UNION ALL SELECT 'Aircraft', COUNT(*) FROM Aircraft
UNION ALL SELECT 'Flights', COUNT(*) FROM Flights
UNION ALL SELECT 'Flight_Instances', COUNT(*) FROM Flight_Instances
UNION ALL SELECT 'Terminals', COUNT(*) FROM Terminals
UNION ALL SELECT 'Gates', COUNT(*) FROM Gates
UNION ALL SELECT 'Runways', COUNT(*) FROM Runways
UNION ALL SELECT 'Passengers', COUNT(*) FROM Passengers
UNION ALL SELECT 'Bookings', COUNT(*) FROM Bookings
UNION ALL SELECT 'Baggage', COUNT(*) FROM Baggage
UNION ALL SELECT 'Payments', COUNT(*) FROM Payments
UNION ALL SELECT 'Check_Ins', COUNT(*) FROM Check_Ins
UNION ALL SELECT 'Employees', COUNT(*) FROM Employees
UNION ALL SELECT 'Pilots', COUNT(*) FROM Pilots
UNION ALL SELECT 'Crew_Members', COUNT(*) FROM Crew_Members
UNION ALL SELECT 'Ground_Staff', COUNT(*) FROM Ground_Staff
UNION ALL SELECT 'Crew_Assignments', COUNT(*) FROM Crew_Assignments;

-- Spot-check structures (mirrors the photo workflow: DESC + SELECT per table).
DESC Flights;
SELECT * FROM Flights LIMIT 5;
DESC Flight_Instances;
SELECT * FROM Flight_Instances LIMIT 5;
DESC Bookings;
SELECT * FROM Bookings LIMIT 5;
