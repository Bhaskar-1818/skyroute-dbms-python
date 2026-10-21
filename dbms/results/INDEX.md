# Recorded results - 21 October 2026

Captured output of every check in `dbms/docs/evidence/TESTING.md`, run against
the live database.

- Server: MySQL 8.0.46, InnoDB
- Database: `skyroute_db`, 16 tables + 2 views
- Volume: 34,708 bookings, 4,000 passengers, 336 departures, 43,314 bags, 16 flights
- Every file below is the raw client output, errors included.

| Group | File | What it proves |
|---|---|---|
| T1 joins | `T1-joins.txt` | Ten multi-table result sets, all non-empty |
| T2 analytics | `T2-analytics.txt` | Top route MAA -> BOM (2,688); load factor 53.7-62.6%; 8,704 overweight bags worth Rs 2,69,74,740 |
| T3 constraints | `T3-constraints.txt` | ERROR 1062 duplicate seat, ERROR 1644 same-airport route, CHECK violation on zero-weight bag, ERROR 1451 RESTRICT on airport delete |
| T3e cascade | `T3e-cascade.txt` | Deleting a booking removes its bag and payment: 1 and 1 before, 0 and 0 after |
| T4 procedure | `T4-procedure-trigger.txt` | MakeBooking returns id 34711, seat 99Z, Payment Pending/UPI; second call refused ERROR 1062 with 1 row intact; capacity trigger ERROR 45000; cleanup restores 34,708 bookings |
| T5 rollback | `T5-rollback.txt` | Row visible inside the transaction (1), refused duplicate (ERROR 1062), `rows_left_behind = 0` after ROLLBACK |
| T6 indexes | `T6-indexes.txt` | Four before/after pairs. Example: booking_status goes `ref` 5,449 rows -> `ALL` 33,904 rows after the drop -> `ref` 5,449 again after re-create |
| T7 access | `T7-access.txt` | Three roles; staff revoked to SELECT only then restored |
| T7b viewer | `T7b-viewer-denied.txt` | ERROR 1142: INSERT denied to `sky_viewer` |
| T8 scale | `T8-scale.txt` | 34,708 / 4,000 / 336 / 43,314 / 16 |
| T8 admin | `T8-admin.txt` | SHOW TABLES (16 tables + 2 views) and the per-table row-count union |

## Reproducing

From the repo root, with MySQL credentials in the environment:

```sql
SOURCE dbms/queries/01-joins.sql;
SOURCE dbms/queries/02-analytics.sql;
SOURCE dbms/queries/03-admin.sql;
SOURCE dbms/advanced/03-advanced.sql;
SOURCE dbms/advanced/04-transactions.sql;
SOURCE dbms/advanced/05-indexes.sql;
```

The individual check scripts are in `results/sql/` and are safe to re-run:
they either fail by design or clean up after themselves.

## Relationship to the screenshots

These captures are the machine-readable evidence. The screenshots in
`dbms/docs/evidence/screenshots/` are the visual duplicate for the report.
You do not need both in the PDF; the text output is enough if page count is
tight.
