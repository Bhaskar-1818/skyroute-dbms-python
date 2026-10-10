# Flask viva notes (ES202) — learn with this open, then without it

## Q&A
1. Why Flask, why sqlite3, why no ORM?
   Approved stack; sqlite3 is stdlib and every query stays visible SQL, which
   is the point while learning. SQLAlchemy would hide exactly what I need to show.
2. CRUD mapping? Create: book seat (+auto payment), add passenger/flight/bag.
   Read: search, bookings with receipt + fee, admin counts. Update: edit seat,
   cancel, mark paid, check in, suspend flight. Delete: booking (CASCADE takes
   bags/payment/check-in), passenger.
3. Double booking on the site? Seat map greys taken seats; the POST re-checks
   AND catches IntegrityError from UNIQUE(departure_id, seat_number) — the
   pre-check is politeness, the key is correctness.
4. Fee rule location? One constant pair FREE_KG/FEE_PER_KG in app.py, mirrored
   from booking_receipt_view in MySQL. 25 kg → Rs 2,500.
5. Booking + payment atomicity? `with db:` block inserts both; any failure rolls
   back both. Same idea as MakeBooking, in application code.
6. MySQL vs SQLite differences met? ENUM → TEXT+CHECK, AUTO_INCREMENT →
   INTEGER PRIMARY KEY AUTOINCREMENT, DATETIME → sortable TEXT.
7. How was it tested? test_app.py: 19 checks via Flask test client, no server
   needed — search, guards, seat map, create, duplicate refusal, edit, fee math,
   bad-weight refusal, pay, check-in, cancel, cascade delete, admin, travel-as
   filter, admin view, network chips, privacy gate, cross-user refusal.
8. Why does the bookings page hide everything until I pick a traveler?
   Privacy: tickets expose people's travel plans. No identity means no tickets
   and no actions; every mutation re-checks ownership server-side, so one
   traveler can never touch another's tickets. Single-user demo, production
   would add real auth.
9. Why don't travelers hold absurd numbers of trips?
   The seeder budgets 1-4 trips per traveler with at most one departure per
   day — verified zero same-departure and zero same-day doubles. The MySQL
   seeder uses the same rule at 4,000 travelers and a 14-trip cap.

## Demo script (2–3 min, say while clicking)
1. Home: "SkyRoute in three steps — search, seat, bookings."
2. Search HYD→BLR on 2026-11-03: "departure board with gates and seats sold."
3. Open 6E-501: "green seats free, grey taken — the UNIQUE key made visible."
4. Book 12A: "booking plus Pending payment, one transaction."
5. Book 12A again: "refused with words, not a crash."
6. Add 25 kg bag: "Rs 2,500 fee — 5 kg over at Rs 500."
7. Mark Paid, check in, admin counts. Done.
