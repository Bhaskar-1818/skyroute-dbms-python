# Screenshot pack - every query, in order

Open MySQL Workbench as `root`, select the `skyroute_db` schema (double-click it
in the left panel), then run each numbered block and screenshot the result grid
including the column headers.

Save each screenshot into `dbms/docs/evidence/screenshots/` with the exact
filename given. The PDF builder embeds everything in that folder, so save the
nine **PART A** figures there and keep any extras somewhere else, or your report
will run past 15 pages.

Errors are expected in several blocks - that is the point. Screenshot the red
error message.

---

# PART A - the nine figures for the report

## A1. Join queries (Figure 2) -> `A1-joins.png`

Open `dbms/queries/01-joins.sql` in Workbench and execute the whole file
(lightning icon). Ten result grids appear. Screenshot the tab bar plus the first
result, then scroll and capture J4 and J10.

If you prefer to paste one at a time:

```sql
-- J1
SELECT f.flight_number, al.airline_name,
       dep.iata_code AS from_airport, arr.iata_code AS to_airport,
       f.sched_departure, f.sched_arrival, f.flight_status
FROM Flights f
JOIN Airlines al ON f.airline_id = al.airline_id
JOIN Airports dep ON f.departure_airport_id = dep.airport_id
JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
ORDER BY f.flight_number LIMIT 20;

-- J4 (LEFT JOIN keeps bag-less bookings)
SELECT b.booking_id, b.seat_number, b.price,
       pay.pay_status, c.boarding_status,
       COUNT(bg.baggage_seq) AS bags,
       COALESCE(SUM(bg.weight_kg), 0) AS total_bag_kg
FROM Bookings b
LEFT JOIN Payments pay ON b.booking_id = pay.booking_id
LEFT JOIN Check_Ins c  ON b.booking_id = c.booking_id
LEFT JOIN Baggage bg   ON b.booking_id = bg.booking_id
WHERE b.departure_id = 1
GROUP BY b.booking_id
ORDER BY b.seat_number LIMIT 20;

-- J10 (crew directory, three role tables)
SELECT e.full_name, e.email,
       COALESCE(pl.license_number, cm.crew_role, gs.ground_role) AS credential,
       a.iata_code AS base
FROM Employees e
LEFT JOIN Pilots pl       ON e.employee_id = pl.employee_id
LEFT JOIN Crew_Members cm ON e.employee_id = cm.employee_id
LEFT JOIN Ground_Staff gs ON e.employee_id = gs.employee_id
LEFT JOIN Airports a      ON e.base_airport = a.airport_id
ORDER BY e.full_name;
```

**Expected:** ten grids, all non-empty.

---

## A2. Analytics (Figure 3) -> `A2-analytics.png`

Execute `dbms/queries/02-analytics.sql`. The four that matter:

```sql
-- A1 busiest routes
SELECT CONCAT(dep.iata_code, ' -> ', arr.iata_code) AS route,
       COUNT(*) AS bookings
FROM Bookings b
JOIN Departures d ON b.departure_id = d.departure_id
JOIN Flights f    ON d.flight_id = f.flight_id
JOIN Airports dep ON f.departure_airport_id = dep.airport_id
JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
GROUP BY route
ORDER BY bookings DESC;

-- A2 load factor with HAVING
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

-- A4 overweight baggage revenue
SELECT COUNT(*) AS overweight_bags,
       ROUND(SUM((weight_kg - 20) * 500), 2) AS fee_revenue_rs
FROM Baggage
WHERE weight_kg > 20;

-- A6 passengers above average spend (subquery)
SELECT p.first_name, p.last_name, SUM(b.price) AS total_spent_rs
FROM Bookings b
JOIN Passengers p ON b.passenger_id = p.passenger_id
GROUP BY p.passenger_id
HAVING total_spent_rs > (SELECT AVG(price) FROM Bookings)
ORDER BY total_spent_rs DESC LIMIT 15;
```

**Expected:** MAA -> BOM on top with **2,688**; load factor **53.7 to 62.6**;
**8,704** overweight bags worth **Rs 2,69,74,740.00**.

---

## A3. Duplicate seat refused (Figure 4) -> `A3-duplicate-seat.png`

```sql
INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
SELECT passenger_id, departure_id, seat_number, travel_class, price
FROM Bookings LIMIT 1;
```

**Expected:** `ERROR 1062 (23000): Duplicate entry '1-20B' for key 'bookings.uq_booking_seat'`

---

## A4. Stored procedure books seat and payment (Figure 5) -> `A4-procedure.png`

Run these as one script (they depend on each other):

```sql
SET @d := (SELECT d.departure_id
           FROM Departures d
           JOIN Aircraft a ON d.aircraft_id = a.aircraft_id
           WHERE (SELECT COUNT(*) FROM Bookings b
                  WHERE b.departure_id = d.departure_id) < a.capacity
           ORDER BY d.departure_id LIMIT 1);

CALL MakeBooking(1, @d, '99Z', 'Economy', 4500.00, @id);

SELECT @id AS new_booking_id;
SELECT seat_number, travel_class, price FROM Bookings  WHERE booking_id = @id;
SELECT pay_status, pay_method          FROM Payments   WHERE booking_id = @id;
```

**Expected:** booking id around 34711, seat `99Z`, and a `Pending` / `UPI`
payment row with the same booking id. Screenshot both grids.

**Do not clean up yet** - the next block needs this booking.

---

## A5. Capacity trigger refuses overselling (Figure 6) -> `A5-capacity.png`

```sql
SET @ac   := (SELECT aircraft_id FROM Departures WHERE departure_id = @d);
SET @sold := (SELECT COUNT(*) FROM Bookings WHERE departure_id = @d);
UPDATE Aircraft SET capacity = @sold WHERE aircraft_id = @ac;

INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
VALUES (1, @d, '98Z', 'Economy', 4500.00);
```

**Expected:** `ERROR 1644 (45000): Booking refused: flight is fully booked`

Now restore and clean up, and screenshot the last select as proof the data is
back to normal:

```sql
UPDATE Aircraft SET capacity = 180 WHERE aircraft_id = @ac;
DELETE FROM Bookings WHERE booking_id = @id;
SELECT COUNT(*) AS total_bookings FROM Bookings;
```

**Expected:** `34708`.

---

## A6. Rollback (Figure 7) -> `A6-rollback.png`

```sql
START TRANSACTION;

INSERT INTO Passengers (first_name, last_name, passport_number, phone, email)
VALUES ('Demo', 'Rollback', 'DEMO-PP-1', '9000000000', 'demo.rollback@example.com');

SELECT COUNT(*) AS visible_inside_txn
FROM Passengers WHERE passport_number = 'DEMO-PP-1';

INSERT INTO Passengers (first_name, last_name, passport_number, phone, email)
VALUES ('Demo', 'Duplicate', 'DEMO-PP-1', '9000000001', 'demo.dup@example.com');

ROLLBACK;

SELECT COUNT(*) AS rows_left_behind
FROM Passengers WHERE passport_number = 'DEMO-PP-1';
```

**Expected:** inside the transaction `1`, then `ERROR 1062`, then **0** after
the rollback. Screenshot the `1`, the error, and the `0` together.

---

## A7. Row lock blocks a competing update (Figure 8) -> `A7-lock.png`

This needs **two Workbench query tabs** (two connections).

| Step | Tab 1 | Tab 2 |
|---|---|---|
| 1 | `START TRANSACTION;` | |
| 2 | `SELECT price FROM Bookings WHERE booking_id = 1 FOR UPDATE;` | |
| 3 | | `UPDATE Bookings SET price = price + 1 WHERE booking_id = 1;` |
| 4 | screenshot Tab 2 - the spinner is the lock | |
| 5 | `ROLLBACK;` | (statement completes) |
| 6 | | `COMMIT;` |

**Expected:** Tab 2 hangs at step 3. That frozen statement is the proof.

---

## A8. Access control (Figure 9) -> `A8-grants.png`

```sql
SHOW GRANTS FOR 'sky_admin'@'localhost';
SHOW GRANTS FOR 'sky_staff'@'localhost';
SHOW GRANTS FOR 'sky_viewer'@'localhost';
```

**Expected:** ALL / SELECT+INSERT+UPDATE / SELECT respectively.

---

## A9. Scale (Figure 10) -> `A9-scale.png`

```sql
SELECT 'Bookings'   AS table_name, COUNT(*) AS row_count FROM Bookings
UNION ALL SELECT 'Passengers', COUNT(*) FROM Passengers
UNION ALL SELECT 'Departures', COUNT(*) FROM Departures
UNION ALL SELECT 'Baggage',    COUNT(*) FROM Baggage
UNION ALL SELECT 'Flights',    COUNT(*) FROM Flights
UNION ALL SELECT 'Payments',   COUNT(*) FROM Payments;
```

**Expected:** 34708, 4000, 336, 43314, 16, 34708.

---

# PART B - the rest of the evidence (optional, for the viva)

## B1. Remaining constraints -> `B1-constraints.png`

```sql
-- same airport on both ends: ERROR 1644
INSERT INTO Flights (flight_number, airline_id, departure_airport_id,
                     arrival_airport_id, sched_departure, sched_arrival)
VALUES ('XX-000', 1, 1, 1, '10:00:00', '12:00:00');

-- zero-weight bag: CHECK violation
INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (1, 99, 0);

-- airport with flights cannot be deleted: ERROR 1451
DELETE FROM Airports WHERE airport_id = 1;
```

## B2. Cascade proof -> `B2-cascade.png`

```sql
INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
VALUES (1, 2, '77Z', 'Economy', 1000.00);
SET @b = LAST_INSERT_ID();
INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (@b, 1, 10.00);
INSERT INTO Payments (booking_id, amount, pay_method, pay_status)
VALUES (@b, 1000.00, 'UPI', 'Paid');

SELECT (SELECT COUNT(*) FROM Baggage  WHERE booking_id = @b) AS bags_before,
       (SELECT COUNT(*) FROM Payments WHERE booking_id = @b) AS payments_before;

DELETE FROM Bookings WHERE booking_id = @b;

SELECT (SELECT COUNT(*) FROM Baggage  WHERE booking_id = @b) AS bags_after,
       (SELECT COUNT(*) FROM Payments WHERE booking_id = @b) AS payments_after;
```

**Expected:** 1 / 1 then 0 / 0.

## B3. Duplicate procedure call -> `B3-procedure-refused.png`

```sql
CALL MakeBooking(1, 1, '99Z', 'Economy', 4500.00, @id2);
SELECT COUNT(*) AS rows_with_99Z FROM Bookings WHERE seat_number = '99Z';
```

**Expected:** `ERROR 1062`, and the count stays at whatever it was.

## B4. Index before / after -> `B4-index-before.png`, `B5-index-after.png`

```sql
-- BEFORE: index present
EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';

DROP INDEX idx_bookings_status ON Bookings;

-- AFTER DROP: full table scan
EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';

CREATE INDEX idx_bookings_status ON Bookings (booking_status);

-- RESTORED
EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';
```

**Expected:** `ref` / 5,449 rows -> `ALL` / 33,904 rows -> `ref` / 5,449 rows.

Repeat for `idx_departures_date`, `idx_passengers_name`, `idx_baggage_weight` if
you want all four.

## B6. Viewer denied -> `B6-viewer-denied.png`

Open a second connection as the viewer (`sky_viewer` / `Viewer@123`), then:

```sql
USE skyroute_db;
INSERT INTO Airports (iata_code, airport_name, city)
VALUES ('ZZZ', 'Denied Test', 'Nowhere');
```

**Expected:** `ERROR 1142: INSERT command denied to user 'sky_viewer'@'localhost'`

## B7. REVOKE and restore -> `B7-revoke.png`

Back on the root connection:

```sql
REVOKE INSERT, UPDATE ON skyroute_db.* FROM 'sky_staff'@'localhost';
SHOW GRANTS FOR 'sky_staff'@'localhost';

GRANT SELECT, INSERT, UPDATE ON skyroute_db.* TO 'sky_staff'@'localhost';
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'sky_staff'@'localhost';
```

**Expected:** SELECT only, then SELECT+INSERT+UPDATE again.

## B8. Commit demo -> `B8-commit.png`

```sql
START TRANSACTION;
INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
VALUES (1, 2, '29A', 'Economy', 4500.00);
SET @demo_a = LAST_INSERT_ID();
INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference, paid_at)
VALUES (@demo_a, 4500.00, 'UPI', 'Paid', 'TXN-DEMO-A', NOW());
COMMIT;

SELECT * FROM Bookings WHERE booking_id = @demo_a;
SELECT * FROM Payments WHERE booking_id = @demo_a;
```

Clean up afterwards so the seed stays at 34,708:

```sql
DELETE FROM Bookings WHERE booking_id = @demo_a;
```

---

# After all screenshots

1. Put the nine PART A files in `dbms/docs/evidence/screenshots/`.
2. Rebuild the report:

```powershell
cd "C:\D Drive Folders\Projects\bhaskar\skyroute-dbms-python"
uv run --with fpdf2 python dbms/tools/build_pdf.py
```

3. Check the page count. Nine figures at roughly 40% of a page each adds about
3.5 pages to the current 10, which lands at 13-14. If it goes over 15, delete
`A2-analytics.png` and `A9-scale.png` first - the text already states those
results.
