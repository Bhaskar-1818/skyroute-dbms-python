# Viva + study notes — learn these WITH this file open, then without it

How to use: read one section, close the file, say the answer out loud in your
own words, reopen and check. If you can do all sections without peeking, you
are viva-ready. Total: 13 decisions (C1–C13) + 10 questions.

## The 13 decisions (your design journal — examiners love "why did you…?")

- C1 Airports is the root master; surrogate integer PK keeps FKs small at scale.
- C2 Airline/Aircraft are tables, not text columns — "all IndiGo aircraft" is a
  JOIN instead of a guess.
- C3 Flight = timetable template, Flight_Instance = one dated departure. This
  split is what holds unlimited flights.
- C4 Flights carry departure AND arrival airports; CHECK blocks HYD→HYD rows.
- C5 Airports use RESTRICT, not CASCADE — deleting an airport must never
  silently wipe flights.
- C6 Composite UNIQUEs on (terminal, gate) and (airport, runway/terminal) make
  gate clashes impossible in storage.
- C7 Instances carry actual times (NULL until flown) + assigned aircraft/gate/
  runway; status is a closed ENUM.
- C8 UNIQUE(instance, seat) kills double booking inside the engine itself.
- C9 Baggage is weak: PK is (booking_id, seq); deleting a booking wipes its bags.
- C10 Staff is supertype/subtype: one Employees row, role facts in Pilots /
  Crew_Members / Ground_Staff keyed by the same id — a licence can't dangle.
- C11 Three least-privilege roles; grants verified with SHOW GRANTS on the
  exact database name (a grant on a misspelled DB protects nothing).
- C12 Defence in depth: UNIQUE stops duplicate seats, the TRIGGER stops
  overselling past capacity. Different rules, different enforcers.
- C13 Only workload filters got new indexes; FK columns are already auto-indexed
  by InnoDB, so re-indexing them would be cargo cult.

## Core Q&A (say each in 3–4 sentences)

1. Two users book seat 12A on the same flight in the same second. What happens?
   Both INSERTs race; the UNIQUE(instance_id, seat_number) key admits the first
   and rejects the second with ERROR 1062. The Flask app pre-checks taken seats
   for a friendly message AND catches the IntegrityError, because the pre-check
   alone has a race window. Correctness lives in the database, politeness in
   the app.
2. Why does MakeBooking wrap two inserts in a transaction with an exit handler?
   So a booking and its payment are atomic: both or neither. Any error triggers
   ROLLBACK plus RESIGNAL, so failures never leave half-written rows and the
   caller still sees the real error.
3. Why no indexes on foreign-key columns?
   InnoDB auto-indexes single-column FKs at creation. New indexes went only on
   workload filters (status, departure date, surname, bag weight), each proven
   with a before/after EXPLAIN pair.
4. Your friend has 23 tables, you have 18. Defend it.
   Count the modules, not the tables: timetable, dated operations, infrastructure,
   passengers, money, staff, access control — all present. Then attack upward:
   ours has a trigger, a procedure, views, transaction demos and measured
   indexes; theirs has none of those. Fewer tables, more behavior.
5. Flight vs Flight_Instance — why two tables for "flights"?
   A timetable row ("6E-501 flies HYD→BLR daily 08:00") and a dated departure
   ("6E-501 on Nov 3, gate G2, departed 08:04") are different facts with
   different lifecycles. One row in Flights owns unlimited dated instances —
   that is the whole scaling story.
6. Weak entity — example and why?
   Baggage: identified only as "bag 2 of booking 817". No booking, no baggage,
   so its key starts with booking_id and deleting a booking cascades its bags.
7. MySQL project vs Flask project — same work twice?
   No. MySQL track proves depth (trigger/procedure/transactions/indexes on
   14k rows). Flask track proves application: the same design translated to
   SQLite (ENUM→TEXT+CHECK), full CRUD, fee rule in code, 10 passing tests.
8. Normalisation of your schema in one breath?
   Masters remove repeating groups (1NF); every attribute depends on the whole
   key (2NF — gate status depends on gate_id, never on a booking); no
   transitive dependencies (3NF — city lives in Airports, flights reference it).
   Every determinant is a key, so BCNF holds.
9. What is isolation, demonstrated how?
   REPEATABLE READ: session 2 keeps seeing the old booking status while session
   1's update is uncommitted, then sees the new value after COMMIT (Demo C).
10. Scale: how many flights can it hold?
    Schema-wise unlimited (integer keys, indexed FKs). Demonstrated: 10
    scheduled flights × 14 days = 140 instances, ~14k bookings. Turn NUM_DAYS /
    ROUTES knobs for more; nothing in the design changes.

## Flask track (ES202) quick answers
- Why Flask, why sqlite3, why no ORM? Approved stack; sqlite3 is stdlib and
  every query stays visible SQL, which is the point while learning.
- CRUD mapping: Create (book/passenger/flight/bag), Read (search/list/admin),
  Update (edit seat, cancel, pay, check-in, suspend), Delete (booking with
  CASCADE, passenger).
- Fee rule location: one constant FREE_KG/FEE_PER_KG in app.py, mirrored from
  booking_receipt_view in MySQL.
