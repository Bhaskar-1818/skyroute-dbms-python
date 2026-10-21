# Capture guide - screenshots for the report

Everything below is copy-paste ready and was run against the live database
(`skyroute_db`, 34,708 bookings / 4,000 passengers / 336 departures /
43,314 bags). Save each screenshot into `dbms/docs/evidence/screenshots/` using the
filename given, because the PDF builder picks up that folder automatically.

Every group in this guide has already been executed and its raw output saved in
dbms/results/ (see dbms/results/INDEX.md). Screenshots are now optional: they
are the visual duplicate for the PDF, not the only evidence.

Windows client:

    "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -p skyroute_db

Or open MySQL Workbench, connect as root, select `skyroute_db`, and screenshot
the result grid after each statement.

---

## T1 - Joins (Step 8)

    SOURCE dbms/queries/01-joins.sql;

**Expected:** ten result sets, all non-empty. J4 must include bookings with
`bags = 0`. Save as `T1.png`. Also save a second shot `T1b.png` zoomed on the
J10 overweight list.

---

## T2 - Analytics (Step 8)

    SOURCE dbms/queries/02-analytics.sql;

**Expected, verified against the live data:**

| Query | Result |
|---|---|
| A1 top route | **MAA -> BOM, 2,688 bookings** (HYD -> BOM is second at 2,664) |
| A2 load factor | between **53.7%** and **62.6%** |
| A4 overweight bags | **8,704 bags**, fee revenue **Rs 2,69,74,740.00** |
| A8 unpaid bookings | **2,748** pending payments |

Save as `T2.png`.

Note: the old TESTING.md said the busiest route would be a HYD route. That was
wrong; the data says MAA -> BOM. It has been corrected.

---

## T3 - Constraints (Steps 6-7)

Run each line separately and screenshot the error, one shot per failure.

    -- C-a duplicate seat: expect ERROR 1062
    INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
    SELECT passenger_id, departure_id, seat_number, travel_class, price
    FROM Bookings LIMIT 1;

    -- C-b same airport on both ends: expect ERROR 1644 (trigger)
    INSERT INTO Flights (flight_number, airline_id, departure_airport_id,
                         arrival_airport_id, sched_departure, sched_arrival)
    VALUES ('XX-000', 1, 1, 1, '10:00:00', '12:00:00');

    -- C-c zero-weight bag: expect CHECK violation
    INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (1, 99, 0);

    -- C-d delete an airport that still has flights: expect RESTRICT refusal
    DELETE FROM Airports WHERE airport_id = 1;

    -- C-e cascade: counts before and after deleting one booking
    SELECT (SELECT COUNT(*) FROM Baggage  WHERE booking_id = 5) AS bags_before,
           (SELECT COUNT(*) FROM Payments WHERE booking_id = 5) AS pay_before;
    DELETE FROM Bookings WHERE booking_id = 5;
    SELECT (SELECT COUNT(*) FROM Baggage  WHERE booking_id = 5) AS bags_after,
           (SELECT COUNT(*) FROM Payments WHERE booking_id = 5) AS pay_after;
    -- bags_after = 0, pay_after = 0

Save as `T3a.png` to `T3e.png`.

---

## T4 - Procedure and trigger (Steps 8-9)

Pick a departure that still has seats, then book one:

    SET @d := (SELECT departure_id FROM v_departure_board
               WHERE sold < capacity ORDER BY departure_id LIMIT 1);
    CALL MakeBooking(1, @d, '99Z', 'Economy', 4500.00, @id);
    SELECT @id AS new_booking_id;
    SELECT * FROM Bookings  WHERE booking_id = @id;
    SELECT * FROM Payments  WHERE booking_id = @id;   -- Pending row, same id

Booking the same seat again must fail atomically:

    CALL MakeBooking(1, @d, '99Z', 'Economy', 4500.00, @id2);  -- ERROR 1062
    SELECT COUNT(*) FROM Bookings WHERE seat_number = '99Z' AND departure_id = @d;
    -- still exactly 1 row: the failed call inserted nothing

Capacity trigger - deterministic version, no need to fill a flight by hand:

    -- shrink one aircraft to exactly the seats already sold on one departure
    SET @dep := (SELECT departure_id FROM v_departure_board LIMIT 1);
    SET @ac  := (SELECT aircraft_id FROM Departures WHERE departure_id = @dep);
    SET @sold := (SELECT sold FROM v_departure_board WHERE departure_id = @dep);
    UPDATE Aircraft SET capacity = @sold WHERE aircraft_id = @ac;
    INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
    VALUES (1, @dep, '98Z', 'Economy', 4500.00);   -- ERROR 45000 'fully booked'
    UPDATE Aircraft SET capacity = 180 WHERE aircraft_id = @ac;   -- restore

Save as `T4a.png` to `T4c.png`.

---

## T5 - Transactions (Step 9)

    SOURCE dbms/advanced/04-transactions.sql;

- Demo A commits: screenshot the booking row and its payment row.
- Demo B must show **ERROR 1062** on the second INSERT, then
  `rows_left_behind = 0` after ROLLBACK.

Demo C needs two mysql windows. Open both, run in this order:

| Step | Window 1 | Window 2 |
|---|---|---|
| 1 | `START TRANSACTION;` | |
| 2 | `SELECT price FROM Bookings WHERE booking_id = 1 FOR UPDATE;` | |
| 3 | | `UPDATE Bookings SET price = price + 1 WHERE booking_id = 1;` (this **hangs**) |
| 4 | `ROLLBACK;` | (window 2 completes immediately) |
| 5 | | `COMMIT;` |

Screenshot window 2 while it is hanging in step 3 - that frozen prompt is the
proof of the row lock. Save as `T5a.png`, `T5b.png`, `T5c.png`.

---

## T6 - Indexes and query cost (Step 10)

Before/after pairs, one index at a time:

    EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';
    DROP INDEX idx_bookings_status ON Bookings;
    EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';
    CREATE INDEX idx_bookings_status ON Bookings (booking_status);
    EXPLAIN SELECT * FROM Bookings WHERE booking_status = 'Refunded';

Capture the first EXPLAIN (index used), the one after the drop (full scan),
and the one after re-creating. Repeat for `idx_departures_date`,
`idx_passengers_name` and `idx_baggage_weight`.

    SHOW INDEX FROM Bookings;

Save as `T6a.png` to `T6d.png`.

---

## T7 - Access control (Step 7 DCL)

    SHOW GRANTS FOR 'sky_admin'@'localhost';
    SHOW GRANTS FOR 'sky_staff'@'localhost';
    SHOW GRANTS FOR 'sky_viewer'@'localhost';

Viewer is denied a write - screenshot the error:

    mysql -u sky_viewer -p skyroute_db
    INSERT INTO Airports (iata_code, airport_name, city) VALUES ('ZZZ','Test','Test');
    -- ERROR 1142 command denied

REVOKE demonstration:

    REVOKE INSERT, UPDATE ON skyroute_db.* FROM 'sky_staff'@'localhost';
    SHOW GRANTS FOR 'sky_staff'@'localhost';      -- SELECT only
    GRANT SELECT, INSERT, UPDATE ON skyroute_db.* TO 'sky_staff'@'localhost';
    FLUSH PRIVILEGES;
    SHOW GRANTS FOR 'sky_staff'@'localhost';      -- restored

Save as `T7a.png` to `T7c.png`.

---

## T8 - Scale (Step 10)

    SELECT COUNT(*) FROM Bookings;     -- 34708
    SELECT COUNT(*) FROM Passengers;   -- 4000
    SELECT COUNT(*) FROM Departures;   -- 336
    SELECT COUNT(*) FROM Baggage;      -- 43314

    SOURCE dbms/queries/03-admin.sql;

Save as `T8.png` and `T8b.png`.

---

## After capturing

Put the PNGs in `dbms/docs/evidence/screenshots/`, then rebuild the report:

    cd "C:\D Drive Folders\Projects\bhaskar\skyroute-dbms-python"
    uv run --with fpdf2 python dbms/tools/build_pdf.py

The builder embeds the ER diagram automatically and appends every screenshot
it finds in that folder, in filename order.

