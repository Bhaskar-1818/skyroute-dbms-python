"""Builds docs/SkyRoute_DBMS_Report.docx (python-docx). Run from project root:
python docs/build_report.py"""
from docx import Document
from docx.shared import Pt

doc = Document()
style = doc.styles["Normal"]
style.font.name = "Calibri"
style.font.size = Pt(11)

def h(text, level=1):
    doc.add_heading(text, level=level)

def p(text):
    doc.add_paragraph(text)

def bullets(items):
    for it in items:
        doc.add_paragraph(it, style="List Bullet")

def table(headers, rows):
    t = doc.add_table(rows=1 + len(rows), cols=len(headers))
    t.style = "Table Grid"
    for j, hd in enumerate(headers):
        t.rows[0].cells[j].text = hd
    for i, row in enumerate(rows):
        for j, val in enumerate(row):
            t.rows[i + 1].cells[j].text = str(val)
    doc.add_paragraph("")

# ------------------------------- cover --------------------------------------
doc.add_heading("SkyRoute: Airline Ticket and Baggage Management System", level=0)
p("DBMS Mini Project — Database Management System (CS/AI/AIM/DS202)")
p("Multi-airport relational database with SQL implementation, advanced features, "
  "transaction management, indexing and testing on MySQL 8.0.")
p("Database: skyroute_db | Tables: 18 | Seed volume: 140 flight instances, "
  "~14,000 bookings, ~17,000 baggage records (deterministic generator, seed 42).")

h("Abstract")
p("Managing flight bookings, seat allocation, gate assignment and baggage handling "
  "across several airports by hand causes duplicate seat bookings, gate clashes, "
  "wrong baggage-fee computation and inconsistent data between stations. SkyRoute is "
  "a centralized relational database for five Indian airports and three airlines that "
  "automates scheduling, reservations, baggage tracking, payments and check-in. The "
  "schema separates timetable templates (Flights) from dated departures "
  "(Flight_Instances) so the system can hold an unlimited number of dated flights; "
  "models Terminal/Gate/Runway infrastructure per airport; and organises staff with a "
  "supertype/subtype hierarchy. Integrity rules live inside the database: a unique "
  "seat-per-instance key blocks double booking, a trigger blocks overselling past "
  "aircraft capacity, composite gate keys block gate clashes, and check constraints "
  "block impossible routes and weights. A stored procedure books a seat and opens its "
  "payment atomically, two reporting views serve the departure board and the booking "
  "receipt (including the overweight-baggage fee), transaction demos prove atomicity "
  "and isolation, and targeted indexes with before/after EXPLAIN checks prove the "
  "system stays fast at volume.")

h("1. Title Selection")
p("SkyRoute: Airline Ticket and Baggage Management System. The title reflects the "
  "real-world problem solved — ticketing and baggage handling for scheduled airline "
  "operations across multiple airports — rather than a single-route shuttle.")

h("2. Problem Statement")
p("Manual and single-station booking workflows observed at HYD and BLR suffer five "
  "concrete failures: (1) duplicate seat booking on the same flight when two agents "
  "sell concurrently; (2) gate assignment clashes written down wrongly between "
  "flights; (3) baggage fees miscalculated when weight exceeds the 20 kg free "
  "allowance; (4) no single database shared by flights, passengers and bookings "
  "across stations; (5) no automated guard when a flight sells more seats than the "
  "aircraft holds. Each failure maps to exactly one database mechanism built in "
  "Sections 7–9, so every problem statement item is provably closed.")
bullets([
    "Duplicate seat booking -> UNIQUE(instance_id, seat_number).",
    "Gate clash -> UNIQUE(terminal_id, gate_number) plus gate rotation in scheduling.",
    "Wrong baggage fee -> fee rule encoded once in booking_receipt_view.",
    "No single database -> one skyroute_db serving all five airports.",
    "Overselling -> trg_booking_capacity trigger against aircraft capacity.",
])

h("3. Objectives")
bullets([
    "Automate flight scheduling and gate allocation across five airports.",
    "Make double seat booking and overselling impossible at the storage engine level.",
    "Compute baggage fees deterministically from weighed kilograms.",
    "Retrieve flight boards, manifests, revenue and utilisation with single queries.",
    "Guarantee integrity with least-privilege access control (admin / staff / viewer).",
    "Prove performance at volume with indexing and query-cost analysis.",
])

h("4. Requirements Gathering")
h("Functional requirements", level=2)
bullets([
    "Add, edit and view airports, airlines, aircraft, flights and dated instances.",
    "Assign aircraft, gate, runway and crew to each dated departure.",
    "Reserve seats and create bookings; log baggage weight per booking.",
    "Record payments and check-ins; manage staff and roles.",
])
h("Non-functional requirements", level=2)
bullets([
    "Fast query response at tens of thousands of rows (indexes + EXPLAIN proof).",
    "Data integrity under concurrent sellers (constraints + transactions).",
    "Secure access (three least-privilege database roles).",
])

h("5. Entity-Relationship Modeling")
p("Entities: Airport, Airline, Aircraft, Flight, Flight_Instance, Terminal, Gate, "
  "Runway, Passenger, Booking, Baggage (weak, double-bordered), Payment, Check_In, "
  "Employee (supertype) with Pilot, Crew_Member, Ground_Staff subtypes, and "
  "Crew_Assignment as the associative entity between staff and dated flights. "
  "Key relationships: Airline 1—N Aircraft; Flight N—1 Airports (departure and "
  "arrival roles); Flight 1—N Flight_Instances; Airport 1—N Terminals 1—N Gates; "
  "Passenger 1—N Bookings N—1 Flight_Instances; Booking 1—N Baggage (identifying) "
  "and 1—1 Payment / Check_In. Cardinalities and keys were drawn in draw.io from "
  "this model before any CREATE TABLE was written.")

h("6. Schema Design (Relational Model)")
p("The ER model converts to 18 InnoDB tables. Surrogate integer primary keys keep "
  "foreign keys narrow at scale; natural business keys (IATA codes, tail numbers, "
  "licences, emails, transaction references) carry UNIQUE constraints instead. "
  "Normalisation: repeating groups are removed into masters (airline/aircraft data "
  "live once, not inside every flight row) for 1NF; every non-key attribute depends "
  "on the whole key (2NF — e.g. gate status depends on gate_id, never on a booking); "
  "no transitive dependencies remain (3NF — city depends on airport, and flights "
  "reference the airport rather than copying its city). The design is BCNF-clean: "
  "every determinant in every table is a key.")
table(["Table", "PK", "Key rules"],
      [["Airports", "airport_id", "UNIQUE iata_code, airport_name"],
       ["Airlines", "airline_id", "UNIQUE name, iata_code"],
       ["Aircraft", "aircraft_id", "UNIQUE tail_number; CHECK capacity 1..850"],
       ["Flights", "flight_id", "UNIQUE flight_number; two airport FKs; CHECK dep <> arr"],
       ["Flight_Instances", "instance_id", "UNIQUE(flight_id, scheduled_departure); CHECK arr > dep"],
       ["Terminals", "terminal_id", "UNIQUE(airport_id, terminal_code)"],
       ["Gates", "gate_id", "UNIQUE(terminal_id, gate_number)"],
       ["Runways", "runway_id", "UNIQUE(airport_id, runway_code)"],
       ["Passengers", "passenger_id", "UNIQUE passport, email"],
       ["Bookings", "booking_id", "UNIQUE(instance_id, seat_number)"],
       ["Baggage", "(booking_id, baggage_seq)", "weak entity; CHECK 0 < kg <= 100"],
       ["Payments", "payment_id", "UNIQUE booking_id, txn_reference"],
       ["Check_Ins", "checkin_id", "UNIQUE booking_id"],
       ["Employees + 3 subtypes", "employee_id", "subtype PK = supertype PK; UNIQUE email/licence"],
       ["Crew_Assignments", "assignment_id", "UNIQUE(employee, instance)"]])

h("7. SQL Implementation")
h("DDL", level=2)
p("schema/01-travel-core.sql creates the 13 travel tables with primary keys, "
  "foreign keys (CASCADE where children cannot outlive parents, RESTRICT where "
  "deleting a master must be refused — airports), unique keys, checks and enums. "
  "schema/02-staff-roles.sql adds the staff hierarchy and the DCL: three users "
  "(sky_admin full, sky_staff read-write, sky_viewer read-only) with SHOW GRANTS "
  "proof. The grant names the database exactly; a grant on a misspelled name "
  "succeeds silently and protects nothing, so exactness is verified, not assumed.")
h("DML", level=2)
p("data/generate.py (seed 42) writes data/seed_data.sql deterministically: 5 "
  "airports, 3 airlines, 10 aircraft, 10 scheduled flights, 140 dated instances "
  "over 14 days, 500 passengers, ~14,000 bookings at 35–80% load factors with "
  "seats sampled without replacement, ~14,000 payments, ~17,000 bags (80% under "
  "20 kg, 20% overweight tail for the fee demo), ~5,000 check-ins on departed "
  "instances, 8 staff with subtype rows and crew assignments. The generated file "
  "was machine-verified: zero duplicate (instance, seat) pairs, all foreign keys "
  "in range.")
h("DCL", level=2)
p("Least-privilege roles as above; viewer INSERT is denied (test R-b).")

h("8. Advanced SQL Features")
h("Views", level=2)
p("flight_board_view joins timetable, airports, airline, aircraft, gate and "
  "terminal into the single departure-board query the application uses. "
  "booking_receipt_view returns price plus the computed baggage fee "
  "(20 kg free, Rs 500 per excess kg) via a scalar subquery, keeping the view "
  "valid under ONLY_FULL_GROUP_BY.")
h("Stored procedure", level=2)
p("MakeBooking(passenger, instance, seat, class, price, OUT id) inserts the "
  "booking and opens its Pending payment inside one transaction with an EXIT "
  "HANDLER that rolls back and re-signals on any error: a taken seat fails the "
  "whole call atomically, never half-written.")
h("Trigger", level=2)
p("trg_booking_capacity (BEFORE INSERT ON Bookings) compares seats sold against "
  "the assigned aircraft's capacity and SIGNALs SQLSTATE 45000 when full. It "
  "fires for every insert path — manual SQL, the procedure, and the future web "
  "app — because the rule lives in the database, not in any single client.")
h("Joins and subqueries", level=2)
p("queries/01-joins.sql covers all ten join patterns across every module "
  "(inner, multi-table, LEFT for optional bags/check-ins, supertype/subtype, "
  "self-role double airport join); queries/02-analytics.sql adds GROUP BY, "
  "HAVING, CASE aggregates and a subquery (above-average spenders).")

h("9. Transaction Management")
p("InnoDB provides ACID. Demo A commits a booking plus its payment together; "
  "Demo B rolls back a booking whose payment fails, and the seat is provably "
  "still free afterwards (atomicity). Demo C uses two simultaneous mysql "
  "sessions to show REPEATABLE READ isolation: the second session keeps seeing "
  "the old booking status until the first commits. Script: "
  "advanced/04-transactions.sql.")

h("10. Indexing and Optimization")
p("InnoDB auto-indexes single-column foreign keys, so those were deliberately "
  "not re-indexed. Four workload-driven indexes were added: booking_status "
  "(operations filters), scheduled_departure (every board search), "
  "(last_name, first_name) (desk lookups), weight_kg (fee-report range scans). "
  "Each has a before/after EXPLAIN pair captured in the test log, showing fewer "
  "rows examined after indexing (advanced/05-indexes.sql, tests I-a/I-b).")

h("11. Testing and Validation")
p("docs/TESTING.md records 30 checks in 8 groups (T1–T8): joins, analytics, "
  "constraint rejection (duplicate seat ERROR 1062, impossible route, bad "
  "weight, RESTRICT on airports, CASCADE orphan check), procedure atomicity, "
  "transaction demos, EXPLAIN pairs, role grants, and scale counts. Every check "
  "states its expected result, so the log doubles as the validation protocol.")

h("12. Documentation")
p("This report; README.md (run order, users, rules, layout, screenshot "
  "workflow); TESTING.md (validation protocol); the decision journal C1–C13 "
  "embedded as comments in the SQL sources, tracing each design choice to the "
  "requirement that caused it.")

h("13. Presentation and Reporting")
p("Deliverables: this report, an 11-slide deck (docs/SkyRoute_Slides.pptx), "
  "all source SQL and the generator, README, test log, and a 2–3 minute demo "
  "video walking the departure board, a live booking, the duplicate-seat "
  "rejection, and the fee receipt.")

h("Conclusion")
p("Every problem-statement item is closed by a named database mechanism, every "
  "mechanism has a test, and the system holds production-shaped volume "
  "(~14k bookings) while answering analytical questions in single queries. The "
  "Flask web project (Phase 5) reuses this design on SQLite with raw SQL, "
  "keeping the same integrity rules visible in application code.")

h("References")
bullets([
    "Ramkrishna R., Gehrke J. Database Management Systems, 3rd Ed, McGraw-Hill, 2002.",
    "Silberschatz, Korth, Sudarshan. Database System Concepts, 7th Ed, McGraw-Hill.",
    "MySQL 8.0 Reference Manual: constraints, triggers, stored programs, EXPLAIN.",
])

doc.save("docs/SkyRoute_DBMS_Report.docx")
print("report written")
