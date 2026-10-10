# SkyRoute Web App — brief project report (ES202 Industry Coding Practices)

## Objective
A working Python web application over the airline ticket-and-baggage domain:
search scheduled flights, book seats, log baggage with overweight fees, record
payments and check-ins, and administer flights — with full CRUD.

## Stack (per approved choices)
Flask (no Django), stdlib `sqlite3` (no ORM — every query is visible SQL),
plain HTML/CSS (sufficient per the notice), SQLite file `skyroute.db`.

## Setup and run
```
python flask_app/seed_sqlite.py   # builds skyroute.db (35 instances, ~3.4k bookings)
python flask_app/app.py           # serves http://127.0.0.1:5000
python flask_app/test_app.py      # end-to-end test, no server needed
```

## CRUD coverage (notice requirement)
| Operation | Where |
|-----------|-------|
| Create | book a seat (+ auto payment row), add passenger, add flight, add bag |
| Read | flight search, bookings list with receipt + fee, admin dashboard counts |
| Update | edit booking seat/class/price, cancel booking, mark Paid, check-in, suspend flight |
| Delete | delete booking (bags/payment/check-in vanish via CASCADE), delete passenger |

## Key rules reused from the database design
- `UNIQUE(instance_id, seat_number)`: the app pre-checks taken seats and also
  catches the database IntegrityError, so a double booking fails with words,
  never a crash page.
- Booking + payment insert run in one transaction: both or neither.
- Baggage fee: 20 kg free, Rs 500 per excess kg (one constant, used everywhere).
- SQLite adaptation of the MySQL schema: ENUM to TEXT+CHECK, AUTO_INCREMENT
  to INTEGER PRIMARY KEY AUTOINCREMENT, DATETIME to sortable TEXT.

## Verification
`test_app.py` passes 10 checks: search, create, duplicate refusal, edit,
baggage fee math (25 kg -> Rs 2500), payment, check-in, cancel, delete with
cascade, passenger add/delete, admin page.

## Demo script (2–3 min)
1. Search HYD to BLR on 2026-11-03, open 6E-501.
2. Book seat 12A for a passenger; show it on the bookings page.
3. Try booking 12A again; show the refusal message.
4. Add a 25 kg bag; show the Rs 2500 fee. Mark Paid, check in.
5. Admin dashboard counts; cancel the booking.
