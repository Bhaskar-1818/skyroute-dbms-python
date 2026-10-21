# DBMS viva notes — learn with this open, then without it
Read one answer, close the file, say it out loud in your own words, check.

## The decisions (say WHY for each — examiners ask "why did you…?")
- Airports is the root master; integer PK keeps every FK small at scale.
- Airline/Aircraft are tables, not text — "all IndiGo aircraft" is a JOIN.
- Flight = timetable template; Departure = one dated departure
  ("6E-501 on Nov 3, gate G2"). One flight owns unlimited departures.
- Flights carry departure AND arrival airports; a BEFORE INSERT/UPDATE trigger
  (trg_flights_route) blocks HYD→HYD rows with ERROR 1644 — a CHECK cannot sit
  on these columns because MySQL rejects CHECKs on FK referential-action
  columns (ERROR 3823).
- Airports use RESTRICT, never CASCADE — deleting an airport must not wipe flights.
- Composite UNIQUEs (terminal+gate) make gate clashes impossible in storage.
- UNIQUE(departure, seat) kills double booking inside the engine (problem #1).
- Baggage is weak: PK (booking_id, seq); deleting a booking wipes its bags.
- Staff roles share one employee_id across role tables (1-1) — a licence can't dangle.
- Three least-privilege roles, SHOW GRANTS proof on the exact database name.
- Defence in depth: UNIQUE stops duplicate seats, the TRIGGER stops overselling.
- Only workload filters got new indexes; FK columns are auto-indexed already.

## Q&A (3–4 sentences each)
1. Two users book seat 12A on the same departure in the same second?
   Both INSERTs race; UNIQUE(departure_id, seat_number) admits the first and
   rejects the second with ERROR 1062. Correctness lives in the database, so no
   application timing trick can break it.
2. Why does MakeBooking wrap two inserts in a transaction with an exit handler?
   Booking + payment are atomic: both or neither. Any error rolls back and
   re-signals, so failures never leave half-written rows.
3. Why no indexes on foreign-key columns?
   InnoDB auto-indexes single-column FKs. New indexes went only on workload
   filters (status, departure date, surname, bag weight), each with a
   before/after EXPLAIN pair.
4. A reference project has more tables. Defend 16.
   Count modules, not tables: timetable, dated operations, infrastructure,
   passengers, money, staff, access control — all present. Then attack upward:
   trigger, procedure, views, transaction demos, measured indexes — which the
   bigger schema lacks. Fewer tables, more behavior.
5. Flight vs Departure — why two tables?
   A timetable row and a dated departure are different facts with different
   lifecycles. One Flight owns unlimited dated Departures — the scaling story.
6. Weak entity example? Baggage: "bag 2 of booking 817". No booking, no bag.
7. Normalisation in one breath? Masters remove repeating groups (1NF);
   attributes depend on whole keys (2NF); no transitive dependencies (3NF —
   city lives once in Airports); every determinant is a key (BCNF).
8. Isolation, demonstrated how? Two sessions: session 2 keeps seeing the old
   booking status while session 1's update is uncommitted (REPEATABLE READ),
   then sees the new value after COMMIT.
9. Scale? Schema-wise unlimited; demonstrated 336 departures and ~34k bookings;
   NUM_DAYS / ROUTES knobs raise volume with zero design change.
10. Baggage fee rule? 20 kg free per bag, Rs 500 per excess kg, computed in
    booking_receipt_view so every receipt agrees.
