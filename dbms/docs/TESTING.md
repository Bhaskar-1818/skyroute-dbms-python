# Test log — mapped to syllabus Steps 8–12 and the evaluation criteria

Date the run, paste the output or screenshot number next to each row.

## T1 — Joins (Step 8, eval: SQL Implementation)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| J1–J10 | `SOURCE queries/01-joins.sql` runs with zero errors | 10 result sets, counts > 0 | Shot T1 |
| J4 | bookings with no bags still appear | LEFT JOIN keeps bag-less rows, bags = 0 | Shot T1 |
| J10 | overweight list non-empty | generator plants a ~20% overweight tail | Shot T1 |

## T2 — Analytics (Step 8, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| A1 | busiest route = a HYD route (most departures scheduled) | HYD–BLR or HYD–BOM on top | Shot T2 |
| A2 | every flight load_pct between 35 and 80 | matches generator LOAD_MIN/MAX | Shot T2 |
| A4 | fee revenue > 0 | overweight tail exists | Shot T2 |

## T3 — Constraints (Steps 6–7, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| C-a | insert duplicate (departure_id, seat_number) | ERROR 1062, row rejected | Shot T3 |
| C-b | insert flight with departure = arrival airport | CHECK violation, rejected | Shot T3 |
| C-c | insert bag with weight 0 or negative | CHECK violation, rejected | Shot T3 |
| C-d | delete an airport that still has flights | RESTRICT refuses (flights preserved) | Shot T3 |
| C-e | delete a booking that has bags + payment | CASCADE wipes bags/payment, no orphans | Shot T3 |

## T4 — Trigger + procedure (Steps 8–9, eval: SQL Implementation)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| T-a | `CALL MakeBooking(...)` on a free seat | booking + Pending payment created, @id returned | Shot T4 |
| T-b | `CALL MakeBooking(...)` on a taken seat | procedure fails, NOTHING inserted (atomicity) | Shot T4 |
| T-c | fill a departure to capacity, book once more | ERROR 45000 'fully booked' from trigger | Shot T4 |

## T5 — Transactions (Step 9, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| D-A | Demo A commits | booking + payment both visible | Shot T5 |
| D-B | Demo B rolls back | seat still free afterwards | Shot T5 |
| D-C | two-session read during open txn | session 2 sees old value until COMMIT (isolation) | Shot T5 |

## T6 — Indexes (Step 10, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| I-a | EXPLAIN on each of the 4 queries, before vs after | `rows` examined drops and/or `type` improves; capture both | Shot T6 |
| I-b | `SHOW INDEX` listings | 4 new indexes present, FK indexes untouched | Shot T6 |

## T7 — Access control (Step 7 DCL, eval: Problem Understanding)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| R-a | `SHOW GRANTS` for the 3 users | admin = ALL, staff = SELECT/INSERT/UPDATE, viewer = SELECT | Shot T7 |
| R-b | login as sky_viewer, try an INSERT | access denied | Shot T7 |
| R-c | grants name `skyroute_db`, spelled exactly | no dead grant on a misspelled DB | Shot T7 |

## T8 — Scale (Step 10, eval: Output Accuracy)
| # | Check | Expected | Evidence |
|---|-------|----------|----------|
| S-a | row-count table from 03-admin | 336 departures, ~34k bookings, ~42k bags | Shot T8 |
| S-b | A7 daily snapshot covers all 21 days | no gaps in the date range | Shot T8 |