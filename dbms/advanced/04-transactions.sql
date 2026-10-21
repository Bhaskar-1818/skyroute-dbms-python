-- Advanced 04 v3 : transaction demos - ACID you can watch (MySQL 8.0, InnoDB)
-- Run each block by hand in the mysql client and screenshot the results.
-- v3: every block is runnable exactly as written. Demo B now performs a real
--     constraint violation then ROLLBACK (v2 left ROLLBACK commented out), and
--     Demo C adds the lock-based concurrency demo Step 9 asks for.
USE skyroute_db;

-- DEMO A (success): booking + payment commit together. Both appear or neither.
START TRANSACTION;
INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
  VALUES (1, 2, '29A', 'Economy', 4500.00);
SET @demo_a = LAST_INSERT_ID();
INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference, paid_at)
  VALUES (@demo_a, 4500.00, 'UPI', 'Paid', 'TXN-DEMO-A', NOW());
COMMIT;
SELECT * FROM Bookings WHERE booking_id = @demo_a;
SELECT * FROM Payments WHERE booking_id = @demo_a;

-- ---------------------------------------------------------------------------
-- DEMO B (failure -> ROLLBACK). Nothing to edit: the second INSERT breaks
-- UNIQUE(passport_number) with ERROR 1062, the transaction is then rolled
-- back, and the first (successful) INSERT disappears with it.
-- Expected: the final SELECT returns 0. The passenger does not exist.
-- ---------------------------------------------------------------------------
START TRANSACTION;
INSERT INTO Passengers (first_name, last_name, passport_number, phone, email)
  VALUES ('Demo', 'Rollback', 'DEMO-PP-1', '9000000000', 'demo.rollback@example.com');
SET @demo_pax = LAST_INSERT_ID();
-- this statement fails: ERROR 1062 duplicate entry 'DEMO-PP-1'
INSERT INTO Passengers (first_name, last_name, passport_number, phone, email)
  VALUES ('Demo', 'Duplicate', 'DEMO-PP-1', '9000000001', 'demo.dup@example.com');
ROLLBACK;
-- Expected after ROLLBACK: 0 rows. The transaction left nothing behind.
SELECT COUNT(*) AS rows_left_behind
  FROM Passengers WHERE passport_number = 'DEMO-PP-1';

-- ---------------------------------------------------------------------------
-- DEMO C (LOCK-BASED concurrency). Step 9 asks for locks; this is a real row
-- lock, not just an isolation narrative. Use TWO mysql sessions.
--
-- Session 1:  USE skyroute_db;
--             START TRANSACTION;
--             SELECT booking_id, price FROM Bookings WHERE booking_id = 1 FOR UPDATE;
--             (lock held; do NOT commit yet)
--
-- Session 2:  USE skyroute_db;
--             UPDATE Bookings SET price = price + 1 WHERE booking_id = 1;
--             -> BLOCKS. The prompt does not return; InnoDB is waiting for
--                session 1's exclusive row lock (innodb_lock_wait_timeout 50s).
--
-- Session 1:  ROLLBACK;          -> session 2 immediately proceeds.
-- Session 2:  COMMIT;
--             SELECT price FROM Bookings WHERE booking_id = 1;  -> +1 applied.
--
-- That wait-then-resume sequence is lock-based concurrency control, visible
-- in real time. To show the other outcome, let session 2 wait past the
-- timeout and it fails with ERROR 1205 (lock wait timeout exceeded).
-- ---------------------------------------------------------------------------
