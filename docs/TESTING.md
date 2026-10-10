# Test log — mapped to syllabus Steps 8–12 and the evaluation criteria

Date the run, paste the output or screenshot number next to each row.

## T1 — Joins (Step 8, eval: SQL Implementation)
| # | Check | Expected |
|---|-------|----------|
| J1–J10 | `SOURCE queries/01-joins.sql` runs with zero errors | 10 result sets, counts > 0 |
| J4 | bookings with no bags still appear | LEFT JOIN keeps bag-less rows, bags = 0 |
| J10 | overweight list non-empty | generator plants a ~20% overweight tail |

## T2 — Analytics (Step 8, eval: Output Accuracy)
| # | Check | Expected |
|---|-------|----------|
| A1 | busiest route = a HYD route (most departures scheduled) | HYD–BLR or HYD–BOM on top |
| A2 | every flight load_pct between 35 and 80 | matches generator LOAD_MIN/MAX |
| A4 | fee revenue > 0 | overweight tail exists |

## T3 — Constraints (Steps 6–7, eval: Output Accuracy)
| # | Check | Expected |
|---|-------|----------|
| C-a | insert duplicate (instance_id, seat_number) | ERROR 1062, row rejected |
| C-b | insert flight with departure = arrival airport | CHECK violation, rejected |
| C-c | insert bag with weight 0 or negative | CHECK violation, rejected |
| C-d | delete an airport that still has flights | RESTRICT refuses (flights preserved) |
| C-e | delete a booking that has bags + payment | CASCADE wipes bags/payment, no orphans |

## T4 — Trigger + procedure (Steps 8–9, eval: SQL Implementation)
| # | Check | Expected |
|---|-------|----------|
| T-a | `CALL MakeBooking(...)` on a free seat | booking + Pending payment created, @id returned |
| T-b | `CALL MakeBooking(...)` on a taken seat | procedure fails, NOTHING inserted (atomicity) |
| T-c | fill an instance to capacity, book once more | ERROR 45000 'fully booked' from trigger |

## T5 — Transactions (Step 9, eval: Output Accuracy)
| # | Check | Expected |
|---|-------|----------|
| D-A | Demo A commits | booking + payment both visible |
| D-B | Demo B rolls back | seat still free afterwards |
| D-C | two-session read during open txn | session 2 sees old value until COMMIT (isolation) |

## T6 — Indexes (Step 10, eval: Output Accuracy)
| # | Check | Expected |
|---|-------|----------|
| I-a | EXPLAIN on each of the 4 queries, before vs after | `rows` examined drops and/or `type` improves; capture both |
| I-b | `SHOW INDEX` listings | 4 new indexes present, FK indexes untouched |

## T7 — Access control (Step 7 DCL, eval: Problem Understanding)
| # | Check | Expected |
|---|-------|----------|
| R-a | `SHOW GRANTS` for the 3 users | admin = ALL, staff = SELECT/INSERT/UPDATE, viewer = SELECT |
| R-b | login as sky_viewer, try an INSERT | access denied |
| R-c | grants name `skyroute_db`, spelled exactly | no dead grant on a misspelled DB |

## T8 — Scale (Step 10, eval: Output Accuracy)
| # | Check | Expected |
|---|-------|----------|
| S-a | row-count table from 03-admin | 140 instances, ~14k bookings, ~17k bags |
| S-b | A7 daily snapshot covers all 14 days | no gaps in the date range |
