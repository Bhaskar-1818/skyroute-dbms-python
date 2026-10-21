# Test log — mapped to syllabus Steps 8–12 and the evaluation criteria

Recorded run: 21 October 2026, MySQL 8.0.46. The captured output of every
check below is in dbms/results/; the Evidence column names the exact file.

## T1 — Joins (Step 8, eval: SQL Implementation)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| J1–J10 | `SOURCE queries/01-joins.sql` runs with zero errors | 10 result sets, counts > 0 | dbms/results/T1-joins.txt |
| J4 | bookings with no bags still appear | LEFT JOIN keeps bag-less rows, bags = 0 | dbms/results/T1-joins.txt |
| J10 | overweight list non-empty | generator plants a ~20% overweight tail | dbms/results/T1-joins.txt |

## T2 — Analytics (Step 8, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| A1 | busiest route by bookings | MAA -> BOM (2,688); HYD -> BOM second at 2,664 | dbms/results/T2-analytics.txt |
| A2 | every flight load_pct between 35 and 80 | matches generator LOAD_MIN/MAX | dbms/results/T2-analytics.txt |
| A4 | fee revenue > 0 | overweight tail exists | dbms/results/T2-analytics.txt |

## T3 — Constraints (Steps 6–7, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| C-a | insert duplicate (departure_id, seat_number) | ERROR 1062, row rejected | dbms/results/T3-constraints.txt |
| C-b | insert flight with departure = arrival airport | trigger SIGNAL (ERROR 1644), rejected | dbms/results/T3-constraints.txt |
| C-c | insert bag with weight 0 or negative | CHECK violation, rejected | dbms/results/T3-constraints.txt |
| C-d | delete an airport that still has flights | RESTRICT refuses (flights preserved) | dbms/results/T3-constraints.txt |
| C-e | delete a booking that has bags + payment | CASCADE wipes bags/payment, no orphans | dbms/results/T3-constraints.txt |

## T4 — Trigger + procedure (Steps 8–9, eval: SQL Implementation)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| T-a | `CALL MakeBooking(...)` on a free seat | booking + Pending payment created, @id returned | dbms/results/T4-procedure-trigger.txt |
| T-b | `CALL MakeBooking(...)` on a taken seat | procedure fails, NOTHING inserted (atomicity) | dbms/results/T4-procedure-trigger.txt |
| T-c | fill a departure to capacity, book once more | ERROR 45000 'fully booked' from trigger | dbms/results/T4-procedure-trigger.txt |

## T5 — Transactions (Step 9, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| D-A | Demo A commits | booking + payment both visible | dbms/results/T5-rollback.txt |
| D-B | Demo B rolls back | seat still free afterwards | dbms/results/T5-rollback.txt |
| D-C | two-session read during open txn | session 2 sees old value until COMMIT (isolation) | dbms/results/T5-rollback.txt |

## T6 — Indexes (Step 10, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| I-a | EXPLAIN on each of the 4 queries, before vs after | `rows` examined drops and/or `type` improves; capture both | dbms/results/T6-indexes.txt |
| I-b | `SHOW INDEX` listings | 4 new indexes present, FK indexes untouched | dbms/results/T6-indexes.txt |

## T7 — Access control (Step 7 DCL, eval: Problem Understanding)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| R-a | `SHOW GRANTS` for the 3 users | admin = ALL, staff = SELECT/INSERT/UPDATE, viewer = SELECT | dbms/results/T7-access.txt |
| R-b | login as sky_viewer, try an INSERT | access denied | dbms/results/T7-access.txt |
| R-c | grants name `skyroute_db`, spelled exactly | no dead grant on a misspelled DB | dbms/results/T7-access.txt |

## T8 — Scale (Step 10, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| S-a | row-count table from 03-admin | 336 departures, ~34k bookings, ~42k bags | dbms/results/T8-scale.txt |
| S-b | A7 daily snapshot covers all 21 days | no gaps in the date range | dbms/results/T8-scale.txt |