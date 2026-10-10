# SkyRoute — Airline Ticket & Baggage System (multi-airport)

DBMS mini project (MySQL 8.0) + Python web project (Flask + sqlite3).
Database: `skyroute_db`. Tested against MySQL 8.0.46.

## Run order (mysql client, root user)

```sql
SOURCE schema/01-travel-core.sql;   -- 13 travel tables
SOURCE schema/02-staff-roles.sql;   -- staff hierarchy + 3 DB users
SOURCE data/seed_data.sql;          -- ~14k bookings, ~17k bags (generated)
SOURCE queries/01-joins.sql;        -- 10 join queries
SOURCE queries/02-analytics.sql;    -- 8 analytics queries
SOURCE queries/03-admin.sql;        -- counts + structure spot-checks
SOURCE advanced/03-advanced.sql;    -- 2 views + trigger + procedure
SOURCE advanced/04-transactions.sql;-- ACID demos (run blocks by hand)
SOURCE advanced/05-indexes.sql;     -- 4 indexes + EXPLAIN checks
```

Regenerate seed data any time (deterministic, seed 42):

```
python data/generate.py        (from the project root)
```

Tune volume in `data/generate.py`: `NUM_DAYS`, `ROUTES`, `LOAD_MIN/LOAD_MAX`.

## DB users (least privilege)

| user        | password  | grants on skyroute_db.*      |
|-------------|-----------|------------------------------|
| sky_admin   | Admin@123 | ALL PRIVILEGES               |
| sky_staff   | Staff@123 | SELECT, INSERT, UPDATE       |
| sky_viewer  | Viewer@123| SELECT                       |

## Business rules enforced by the database

- One seat per dated flight: `UNIQUE(instance_id, seat_number)` (Bookings).
- No overselling: `trg_booking_capacity` refuses inserts past aircraft capacity.
- No gate clash: `UNIQUE(terminal_id, gate_number)` (Gates).
- No HYD→HYD route: `CHECK (departure_airport_id <> arrival_airport_id)`.
- Baggage fee: 20 kg free, Rs 500 per excess kg (`booking_receipt_view`).
- Baggage is a weak entity: PK is `(booking_id, baggage_seq)`, cascade delete.

## Layout

```
schema/     01-travel-core.sql  02-staff-roles.sql
data/       generate.py  seed_data.sql
queries/    01-joins.sql  02-analytics.sql  03-admin.sql
advanced/   03-advanced.sql  04-transactions.sql  05-indexes.sql
docs/       TESTING.md  build_report.py  build_slides.py + outputs
flask_app/  Flask + sqlite3 web project (Phase 5)
```

## Screenshot workflow (for the report)

Run each file, screenshot: SHOW TABLES + row-count table (03-admin),
one DESC+SELECT pair per core table, one view output, the duplicate-seat
ERROR 1062, one EXPLAIN before/after pair, transaction Demo A/B outputs.
