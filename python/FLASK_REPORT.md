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
python flask_app/seed_sqlite.py   # builds skyroute.db (35 departures, ~3.4k bookings)
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
- `UNIQUE(departure_id, seat_number)`: the app pre-checks taken seats and also
  catches the database IntegrityError, so a double booking fails with words,
  never a crash page.
- Booking + payment insert run in one transaction: both or neither.
- Baggage fee: 20 kg free, Rs 500 per excess kg (one constant, used everywhere).
- SQLite adaptation of the MySQL schema: ENUM to TEXT+CHECK, AUTO_INCREMENT
  to INTEGER PRIMARY KEY AUTOINCREMENT, DATETIME to sortable TEXT.

## Privacy model (simulated login)
No classroom demo carries real auth, so identity is explicit: the bookings
page shows nobody's tickets until a traveler is picked ("Who's traveling?").
Every mutating route then checks ownership server-side — a traveler can only
touch their own tickets, and the full list is a read-only, clearly-labeled
admin view. The test suite proves a stranger's delete is refused and the row
survives.

## Realism rules in the demo data
600 travelers take 1-4 trips each, at most one departure per day: nobody boards
two flights at once and nobody lives on planes. Verified by query: zero
same-departure doubles, zero same-day doubles. Adding a timetable flight
auto-opens its next 7 dated departures, so new flights appear in search.

## Verification
`test_app.py` passes 19 checks: privacy gate, search, guards, seat map, create,
duplicate refusal, edit, fee math, bad-weight refusal, pay, check-in, cancel,
cascade delete, passenger add/delete, admin, travel-as filter, admin view,
network chips, cross-user refusal.

## Demo script (2–3 min)
1. Search HYD to BLR on 2026-11-03, open 6E-501.
2. Book seat 12A for a passenger; show it on the bookings page.
3. Try booking 12A again; show the refusal message.
4. Add a 25 kg bag; show the Rs 2500 fee. Mark Paid, check in.
5. Admin dashboard counts; cancel the booking.
