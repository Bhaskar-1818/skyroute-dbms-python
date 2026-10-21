-- T5 : ROLLBACK proof (Step 9). Run with --force.
-- The first INSERT succeeds, the second breaks UNIQUE(passport_number),
-- then ROLLBACK removes the successful row too.
USE skyroute_db;

START TRANSACTION;
INSERT INTO Passengers (first_name, last_name, passport_number, phone, email)
VALUES ('Demo', 'Rollback', 'DEMO-PP-1', '9000000000', 'demo.rollback@example.com');
SET @p = LAST_INSERT_ID();
SELECT @p AS inserted_before_failure,
       (SELECT COUNT(*) FROM Passengers WHERE passport_number = 'DEMO-PP-1') AS visible_now;

-- expected: ERROR 1062 duplicate entry 'DEMO-PP-1'
INSERT INTO Passengers (first_name, last_name, passport_number, phone, email)
VALUES ('Demo', 'Duplicate', 'DEMO-PP-1', '9000000001', 'demo.dup@example.com');

ROLLBACK;

SELECT COUNT(*) AS rows_left_behind
FROM Passengers WHERE passport_number = 'DEMO-PP-1';
