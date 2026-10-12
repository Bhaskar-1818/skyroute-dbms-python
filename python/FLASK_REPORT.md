# SkyRoute Ops — web app brief report (ES202 Industry Coding Practices)

## Objective
A working Python web application over the airline ticket-and-baggage domain,
run as an **Airplane Management System**: a staff portal plus a traveler login.
Staff pick any flight and see its full passenger manifest; travelers log in
with their unique ID and see only their own bookings. Full CRUD, per the notice.

## Stack (per approved choices)
Flask (no Django), stdlib `sqlite3` (no ORM — every query is visible SQL),
plain HTML/CSS/vanilla JS (sufficient per the notice), SQLite file `skyroute.db`.

## Setup and run
```
python flask_app/seed_sqlite.py   # builds skyroute.db (29 departures, ~725 bookings, 600 travelers)
python flask_app/app.py           # serves http://127.0.0.1:5000
python flask_app/test_app.py      # end-to-end test, no server needed (28 checks)
```

## Roles
| Role | How | Can do |
|------|-----|--------|
| Traveler | login with numeric traveler ID + demo password `fly123` | view own bookings; book seats as self |
| Staff | Staff page + demo PIN `1234` | everything: manifests, check-in, payments, bags, edits, cancels, flights, travelers |

## CRUD coverage (notice requirement, all staff-reachable)
| Operation | Where |
|-----------|-------|
| Create | book a seat (+ auto payment row), register traveler, add flight (+7 departures), add bag |
| Read | route search, manifest per departure, own bookings with receipt + fee, staff dashboard counts |
| Update | edit booking seat/class/price, edit traveler details, cancel booking, mark Paid, check in, suspend/activate flight |
| Delete | delete booking (bags/payment/check-in vanish via CASCADE), delete traveler (bookings go too), delete empty flight |

## Key rules reused from the database design
- `UNIQUE(departure_id, seat_number)`: the seat map greys taken seats, the app
  pre-checks, and also catches the database IntegrityError — a double booking
  fails with words, never a crash page.
- Booking + payment insert run in one transaction: both or neither.
- Baggage fee: 20 kg free, Rs 500 per excess kg (one constant pair, used everywhere).
- SQLite adaptation of the MySQL schema: ENUM to TEXT+CHECK, AUTO_INCREMENT
  to INTEGER PRIMARY KEY AUTOINCREMENT, DATETIME to sortable TEXT.

## Privacy model (ID + demo-password login)
No classroom demo carries real auth, so identity is explicit and minimal: a
traveler logs in with their unique numeric ID plus the shared demo password,
and the bookings page then shows only their tickets. No identity means no
tickets and no actions. Staff (PIN) can preview any traveler and manage
anything; every mutating route re-checks server-side (staff or owner).
Side doors are closed: direct `?pax=` URLs bounce guests to login, the
everyone-view needs the staff PIN, the manifest route is staff-only, and the
full traveler directory renders only inside the staff portal — never into
public page source. The suite proves a stranger's delete is refused, a guest's
manifest/bookings access is redirected, and login shows only owned tickets.

## Realism rules in the demo data
- Sparse randomized timetable: each of the 7 flights operates a different
  random subset of days (deterministic seed), so some route+date searches
  genuinely have no departures and the site answers with words.
- 600 travelers with real diverse Indian names pulled from the web
  (randomuser.me, cached for stable reseeds), 314 distinct first names.
- Trip budgets: most travelers fly once, some twice, nobody more; at most one
  departure per day — nobody boards two flights at once and nobody lives on
  planes. Adding a timetable flight auto-opens its next 7 dated departures.

## Verification
`test_app.py` passes 28 checks with zero server: privacy gate, route search,
MAA route, empty-date search, missing-field and same-route guards, manifest
staff gate, booking login wall, login (good ID, bad ID, bad password,
only-mine, logout), seat map, create, double-booking and bad-seat refusals,
edit, fee math (25 kg → Rs 2500), bad-weight refusal, pay, check-in, cancel,
cascade delete, staff-gated passenger delete, admin PIN gate, duplicate and
same-airport flight refusals, staff passenger add/delete/edit, travel-as
filter, admin view, network chips, cross-user refusal.

## Demo script (2–3 min)
1. Search HYD-BLR on 2026-11-03 (typed or picked), open 6E-501.
2. Log in as traveler ID 1 (password `fly123`); book a green seat — it lands
   in My bookings, still logged in as the same traveler.
3. Try the same seat again; show the refusal message.
4. Add a 25 kg bag; show the Rs 2500 fee. Mark Paid, check in.
5. Unlock Staff (`1234`); open the departure manifest — every passenger,
   seats, bags, payments; check one in from the manifest.
