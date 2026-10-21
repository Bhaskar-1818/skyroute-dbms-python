# Demo video script - 2 min 30 s

Record at 1080p with MySQL Workbench (or the mysql client) open on the left and
the Flask app open on the right. Read the bold line, do the action, keep moving.
Total target: 2:20-2:50.

---

**0:00 - Intro (15 s)**

Say: "SkyRoute, an airline booking database. MySQL 8.0, sixteen tables,
34,708 bookings seeded across 336 departures. This demo shows database
operations, SQL queries and their output."

Show: `SELECT COUNT(*) FROM Bookings;` -> 34708.

**0:15 - Search and the order board (25 s)**

App: type HYD -> BLR, pick a date, press Search. Results appear.

Then switch to SQL:

    SELECT * FROM v_departure_board WHERE from_airport='HYD' AND to_airport='BLR';

Say: "The board is one view joining flights, airlines, both airports, aircraft,
gate and terminal."

**0:40 - Create: book a seat (25 s)**

App: click a green seat, fill the price, confirm. Note the booking id in the
flash message.

SQL:

    SELECT * FROM Bookings WHERE booking_id = <id>;
    SELECT * FROM Payments WHERE booking_id = <id>;

Say: "One stored procedure wrote both rows in one transaction. The payment row
was created at the same instant."

**1:05 - Integrity: double booking refused (20 s)**

App: try the same seat again. Show the red message.

SQL:

    INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
    SELECT passenger_id, departure_id, seat_number, travel_class, price
    FROM Bookings LIMIT 1;

Say: "The unique key on departure plus seat refuses this inside the storage
engine, not in application code."

**1:25 - Baggage fee rule (20 s)**

App: add a 32 kg bag to the booking, show the fee message.

SQL:

    SELECT * FROM booking_receipt_view WHERE booking_id = <id>;

Say: "Twenty kilograms free, five hundred rupees per excess kilogram, computed
once in the database view."

**1:45 - Update and delete (25 s)**

App: cancel the booking, then delete it.

SQL:

    SELECT booking_status FROM Bookings WHERE booking_id = <id>;   -- Cancelled
    DELETE FROM Bookings WHERE booking_id = <id>;
    SELECT COUNT(*) FROM Baggage WHERE booking_id = <id>;          -- 0
    SELECT COUNT(*) FROM Payments WHERE booking_id = <id>;         -- 0

Say: "Delete cascades to baggage, payment and check-in. No orphans."

**2:10 - Rollback (20 s)**

    SOURCE dbms/advanced/04-transactions.sql;

Run Demo B. Show ERROR 1062, then `rows_left_behind = 0`.

Say: "The first insert succeeded, the second violated the unique passport key,
and the rollback removed both. All or nothing."

**2:30 - Close (10 s)**

Show `SHOW TABLES;` and the row counts from `queries/03-admin.sql`.

Say: "Sixteen tables, constraints, views, triggers, a stored procedure,
transactions and four indexes, all enforced in MySQL."

---

## Checklist before you hit record

- Re-seed first so the numbers match the report: `SOURCE dbms/data/seed_data.sql;`
- Close Slack, Discord and browser tabs that show notifications.
- Zoom the SQL client so the font is readable at 720p.
- Record in one take if possible; if you restart, restart the whole thing so
  the counts and booking ids stay consistent.
- Export as MP4, name it `Section_RollNumber_SkyRoute.mp4`.

