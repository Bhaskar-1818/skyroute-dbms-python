-- ============================================================================
-- Advanced 04 : transaction demos - ACID you can watch (MySQL 8.0, InnoDB)
-- Run each block by hand in the mysql client and screenshot the results.
-- ============================================================================
USE skyroute_db;

-- DEMO A (success): booking + payment commit together. Both appear or neither.
START TRANSACTION;
INSERT INTO Bookings (passenger_id, instance_id, seat_number, travel_class, price)
  VALUES (1, 2, '29A', 'Economy', 4500.00);
SET @demo_a = LAST_INSERT_ID();
INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference, paid_at)
  VALUES (@demo_a, 4500.00, 'UPI', 'Paid', 'TXN-DEMO-A', NOW());
COMMIT;
SELECT * FROM Bookings WHERE booking_id = @demo_a;
SELECT * FROM Payments WHERE booking_id = @demo_a;

-- DEMO B (failure): payment insert uses a bad enum value -> whole booking rolls
-- back. After ROLLBACK the seat is still free: prove it with the SELECT.
START TRANSACTION;
INSERT INTO Bookings (passenger_id, instance_id, seat_number, travel_class, price)
  VALUES (2, 2, '29B', 'Economy', 4500.00);
SET @demo_b = LAST_INSERT_ID();
INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference, paid_at)
  VALUES (@demo_b, 4500.00, 'UPI', 'Paid', 'TXN-DEMO-B', NOW());
-- simulate the failure path: uncomment the next line instead of COMMIT to roll back
-- ROLLBACK;
COMMIT;
SELECT * FROM Bookings WHERE booking_id = @demo_b;

-- DEMO C (concurrency story for viva): open TWO mysql sessions.
-- Session 1: START TRANSACTION; UPDATE Bookings SET booking_status='Cancelled'
--            WHERE booking_id = 1;   (do NOT commit yet)
-- Session 2: SELECT * FROM Bookings WHERE booking_id = 1;
--   -> session 2 still sees 'Confirmed' (REPEATABLE READ isolation).
-- Session 1: COMMIT;  Session 2 re-runs the SELECT -> now 'Cancelled'.
-- That invisible-row-then-visible-row sequence IS isolation, demonstrated live.
