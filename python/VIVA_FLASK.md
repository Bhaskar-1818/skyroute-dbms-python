# Flask viva notes (ES202) — learn with this open, then without it

## Q&A
1. Why Flask, why mysql-connector-python, why no ORM?
    Approved stack; the connector is the Module-4 requirement — every
    insert/update/delete in the site lands in the MySQL server, which is
    exactly what the evaluation checks (open Workbench and watch the rows
    change). No ORM because every query stays visible SQL, which is the
    point while learning. SQLAlchemy would hide exactly what I need to show.
2. CRUD mapping? Create: book seat (+auto payment), register traveler, add
   flight, add bag. Read: route search, manifest, own bookings with receipt +
   fee, staff counts. Update: edit seat/class/price, edit traveler, cancel,
   mark paid, check in, suspend flight. Delete: booking (CASCADE takes
   bags/payment/check-in), traveler (bookings go too), empty flight.
3. Double booking on the site? Seat map greys taken seats; the POST re-checks
   AND catches IntegrityError from UNIQUE(departure_id, seat_number) — the
   pre-check is politeness, the key is correctness.
4. Fee rule location? One constant pair FREE_KG/FEE_PER_KG in app.py, mirrored
   from booking_receipt_view in MySQL. 25 kg → Rs 2,500.
5. Booking + payment atomicity? One MySQL transaction inserts both (see
    db.py transaction()); any failure rolls back both. Same idea as
    MakeBooking, in application code — and the seat can't double-sell
    because UNIQUE(departure_id, seat_number) lives in the server.
6. Placeholders and rows under the connector? `%s` instead of `?`
    (connector style), dict cursors so `r["seat_number"]` reads the same,
    `lastrowid` and commit/rollback like before. MySQL returns DATETIME
    objects, so db.py converts them to 'YYYY-MM-DD HH:MM:SS' strings —
    templates slice them exactly as with SQLite. Scalar MySQL differences
    met: `INSERT IGNORE` instead of `INSERT OR IGNORE`, `NOW()` instead of
    `datetime('now')`, `GREATEST()` instead of two-argument `MAX()`.
7. How was it tested? test_app.py reseeds a throwaway `skyroute_test`
    database, then runs 28 checks via Flask test client, no server
    needed — privacy gate, route search, empty-date search, guards, manifest
   staff gate, booking login wall, login and logout, seat map, create, refusal
   guards, edit, fee math, pay, check-in, cancel, cascade delete, staff-gated
   deletes and edits, admin PIN, travel-as filter, admin view, cross-user refusal.
8. Why ID + password instead of the old "pick a traveler" dropdown? A dropdown
   of all travelers lets anyone BE anyone — it defeats privacy. The numeric ID
   is unique per traveler and the demo password proves it; the bookings query
   then filters by session identity, and every mutation re-checks owner-or-staff
   server-side. Direct `?pax=` URLs bounce guests to login.
9. What can staff do that travelers can't? Open any departure manifest, check
   anyone in, mark any payment paid, add bags, edit or cancel any booking, add
   or delete flights, edit or delete travelers, preview as anyone. Staff is PIN
   `1234`; travelers use ID + `fly123`. Separate gates, separate powers.
10. Why do some route+date searches return nothing? The timetable is sparse by
    design: each flight operates a different random subset of days (fixed
    seed, so the demo is stable). Empty results get words, not an error page.
11. Why don't travelers hold absurd numbers of trips? The seeder budgets one
    trip for most, two at most, one departure per day — verified zero
    same-departure and zero same-day doubles. Names are real diverse Indian
    names pulled from the web (cached for stable reseeds), not a 10-name loop.
12. Booking for someone else as traveler? Impossible: the POST ignores the form
    passenger and books as the session identity; only staff's form choice is
    honored. Booking never changes who is logged in.

## Demo script (2–3 min, say while clicking)
1. Home: "Airplane Management System — staff portal plus traveler login."
2. Search HYD-BLR on 2026-11-03: "typed route, departure board with gates."
3. Log in as traveler 1: "ID plus demo password — only my tickets."
4. Book a green seat: "booking plus Pending payment, one transaction."
5. Book it again: "refused with words, not a crash."
6. Add 25 kg bag: "Rs 2,500 fee — 5 kg over at Rs 500."
7. Unlock Staff, open the manifest: "every passenger on this departure."
