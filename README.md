# SkyRoute — Airline Booking, Baggage & Staff Operations System

Two projects, one airline design, separate folders:

- `dbms/` — DBMS mini project (MySQL 8.0, database `skyroute_db`).
  16 tables, deterministic generator (~14k bookings), 18 queries,
  views + trigger + procedure, transaction demos, indexes, report, slides.
- `python/` — ES202 web project (Flask + stdlib sqlite3, full CRUD booking site).

## DBMS track (run from `dbms/`, mysql client as root)

```sql
SOURCE schema/01-travel-core.sql;   -- 12 travel tables
SOURCE schema/02-staff-roles.sql;   -- staff hierarchy + 3 DB users
SOURCE data/seed_data.sql;          -- 336 departures, ~34k bookings
SOURCE queries/01-joins.sql;        -- 10 join queries
SOURCE queries/02-analytics.sql;    -- 8 analytics queries
SOURCE queries/03-admin.sql;        -- counts + structure spot-checks
SOURCE advanced/03-advanced.sql;    -- 2 views + trigger + procedure
SOURCE advanced/04-transactions.sql;-- ACID demos (run blocks by hand)
SOURCE advanced/05-indexes.sql;     -- 4 indexes + EXPLAIN checks
```

Fresh seed any time (deterministic, seed 42): `python data/generate.py`
Docs: `dbms/docs/REPORT_TEXT.md` (paste into Word), `SkyRoute_Report.pdf`,
`SkyRoute_Slides.pptx`, `SkyRoute_ER.drawio` (open in diagrams.net, export PNG),
`TESTING.md`, `VIVA_DBMS.md`.

## Python track (run from repo root)

```
python python/flask_app/seed_sqlite.py   # builds skyroute.db
python python/flask_app/app.py           # http://127.0.0.1:5000
python python/flask_app/test_app.py      # 13 end-to-end checks
```

Docs: `python/FLASK_REPORT.md`, `python/VIVA_FLASK.md`.

## DB users (MySQL, least privilege)

sky_admin (all) / sky_staff (read-write) / sky_viewer (read-only).
Passwords: Admin@123, Staff@123, Viewer@123. Verify with SHOW GRANTS.

## Rules the database enforces

- One seat per departure: `UNIQUE(departure_id, seat_number)`.
- No overselling: `trg_booking_capacity` vs aircraft capacity.
- No gate clash: `UNIQUE(terminal_id, gate_number)`.
- No HYD→HYD route: `CHECK (departure_airport_id <> arrival_airport_id)`.
- Baggage fee: 20 kg free, Rs 500 per excess kg (`booking_receipt_view`).
- Baggage is weak: PK `(booking_id, baggage_seq)`, cascade delete.
