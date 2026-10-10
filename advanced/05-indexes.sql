-- ============================================================================
-- Advanced 05 : indexing + query-cost check (MySQL 8.0, InnoDB)
-- C13: InnoDB already auto-indexes single-column FOREIGN KEYs, so we do NOT
-- re-index those. We index what the workload actually filters/sorts.
-- Method: run each EXPLAIN before the CREATE INDEX, screenshot, create the
-- index, re-run EXPLAIN, screenshot. That before/after pair is Step-10 proof.
-- ============================================================================
USE skyroute_db;

-- I1: booking_status is filtered by every operations query (refunds, pending).
CREATE INDEX idx_bookings_status ON Bookings (booking_status);

-- I2: the departure board sorts/filters by date on every search.
CREATE INDEX idx_instances_departure ON Flight_Instances (scheduled_departure);

-- I3: passenger lookup by family name (admin + check-in desk search).
CREATE INDEX idx_passengers_name ON Passengers (last_name, first_name);

-- I4: overweight-baggage fee report scans weight_kg with a range predicate.
CREATE INDEX idx_baggage_weight ON Baggage (weight_kg);

-- Cost checks (screenshot the `type` and `rows` columns before vs after):
EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';
EXPLAIN SELECT * FROM Flight_Instances
  WHERE scheduled_departure BETWEEN '2026-11-03 00:00:00' AND '2026-11-03 23:59:59';
EXPLAIN SELECT * FROM Passengers WHERE last_name = 'Sharma';
EXPLAIN SELECT * FROM Baggage WHERE weight_kg > 20;

SHOW INDEX FROM Bookings;
SHOW INDEX FROM Flight_Instances;
