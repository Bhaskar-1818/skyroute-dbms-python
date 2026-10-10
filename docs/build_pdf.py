"""Builds docs/SkyRoute_Report.pdf with fpdf2 (no Word/LibreOffice needed).
Run from project root:  python docs/build_pdf.py"""
from fpdf import FPDF

class Report(FPDF):
    def mc(self, w, h, t, **k):
        k.setdefault('new_x', 'LMARGIN')
        k.setdefault('new_y', 'NEXT')
        for a, b in [("—", "--"), ("–", "-"), ("•", "-"), ("’", "'"),
                     ("“", '"'), ("”", '"'), ("…", "...")]:
            t = t.replace(a, b)
        return self.multi_cell(w, h, t, **k)

    def header(self):
        if self.page_no() > 1:
            self.set_font("Helvetica", "I", 9)
            self.cell(0, 8, "SkyRoute: Airline Ticket and Baggage Management System", align="C")
            self.ln(10)

    def h1(self, t):
        self.set_font("Helvetica", "B", 15)
        self.set_text_color(20, 60, 120)
        self.mc(0, 9, t)
        self.set_text_color(0, 0, 0)
        self.ln(1)

    def h2(self, t):
        self.set_font("Helvetica", "B", 12)
        self.mc(0, 8, t)
        self.ln(1)

    def para(self, t):
        self.set_font("Helvetica", "", 10.5)
        self.mc(0, 6, t)
        self.ln(1)

    def bullets(self, items):
        self.set_font("Helvetica", "", 10.5)
        for it in items:
            self.mc(0, 6, "-  " + it)
        self.ln(1)

    def table(self, headers, rows):
        self.set_font("Helvetica", "B", 9.5)
        w = 190 / len(headers)
        for hd in headers:
            self.cell(w, 7, hd, border=1)
        self.ln()
        self.set_font("Helvetica", "", 9)
        for row in rows:
            for val in row:
                self.cell(w, 6.5, str(val)[:42], border=1)
            self.ln()
        self.ln(2)

pdf = Report()
pdf.set_auto_page_break(True, margin=20)
pdf.add_page()
pdf.set_font("Helvetica", "B", 22)
pdf.mc(0, 12, "SkyRoute: Airline Ticket and\nBaggage Management System")
pdf.ln(2)
pdf.set_font("Helvetica", "", 12)
pdf.mc(0, 8, "DBMS Mini Project - Database Management System (CS/AI/AIM/DS202)\n"
                     "Database: skyroute_db  |  Tables: 18  |  MySQL 8.0\n"
                     "Seed volume: 140 flight instances, ~14,000 bookings, "
                     "~17,000 baggage records (deterministic generator, seed 42).")

pdf.h1("Abstract")
pdf.para("Managing flight bookings, seat allocation, gate assignment and baggage "
         "handling across several airports by hand causes duplicate seat bookings, "
         "gate clashes, wrong baggage-fee computation and inconsistent data between "
         "stations. SkyRoute is a centralized relational database for five Indian "
         "airports and three airlines that automates scheduling, reservations, "
         "baggage tracking, payments and check-in. The schema separates timetable "
         "templates (Flights) from dated departures (Flight_Instances); models "
         "Terminal/Gate/Runway infrastructure per airport; and organises staff with "
         "a supertype/subtype hierarchy. Integrity rules live inside the database: "
         "a unique seat-per-instance key, a capacity trigger, composite gate keys, "
         "and check constraints. A stored procedure books atomically, two views "
         "serve the departure board and the receipt (with overweight-baggage fee), "
         "transaction demos prove atomicity and isolation, and indexes with "
         "before/after EXPLAIN checks prove performance at volume.")

pdf.h1("1. Title Selection")
pdf.para("SkyRoute: Airline Ticket and Baggage Management System - the real-world "
         "problem solved (ticketing and baggage across multiple airports), not a "
         "single-route shuttle.")

pdf.h1("2. Problem Statement")
pdf.para("Manual single-station workflows suffer five failures, each closed by one "
         "named database mechanism:")
pdf.bullets(["Duplicate seat booking -> UNIQUE(instance_id, seat_number).",
             "Gate clash -> UNIQUE(terminal_id, gate_number) plus gate rotation.",
             "Wrong baggage fee -> fee rule encoded once in booking_receipt_view.",
             "No single database -> one skyroute_db for all five airports.",
             "Overselling -> trg_booking_capacity trigger against aircraft capacity."])

pdf.h1("3. Objectives")
pdf.bullets(["Automate scheduling and gate allocation across five airports.",
             "Make double booking and overselling impossible at engine level.",
             "Compute baggage fees deterministically from weighed kilograms.",
             "Answer boards, manifests, revenue and utilisation in single queries.",
             "Guarantee integrity with least-privilege access control.",
             "Prove performance at volume with indexing and cost analysis."])

pdf.h1("4. Requirements Gathering")
pdf.h2("Functional")
pdf.bullets(["Add/edit/view airports, airlines, aircraft, flights, dated instances.",
             "Assign aircraft, gate, runway and crew per departure.",
             "Reserve seats, log baggage, record payments and check-ins.",
             "Manage staff and roles."])
pdf.h2("Non-functional")
pdf.bullets(["Fast response at tens of thousands of rows.",
             "Integrity under concurrent sellers.", "Secure access."])

pdf.h1("5. Entity-Relationship Modeling")
pdf.para("Entities: Airport, Airline, Aircraft, Flight, Flight_Instance, Terminal, "
         "Gate, Runway, Passenger, Booking, Baggage (weak), Payment, Check_In, "
         "Employee (supertype) with Pilot, Crew_Member, Ground_Staff subtypes, and "
         "Crew_Assignment linking staff to dated flights. Flight 1-N Instances; "
         "Airport 1-N Terminals 1-N Gates; Passenger 1-N Bookings N-1 Instances; "
         "Booking 1-N Baggage (identifying), 1-1 Payment/Check_In. See ER_Diagram.png.")

pdf.h1("6. Schema Design (Relational Model)")
pdf.para("18 InnoDB tables. Surrogate integer PKs keep FKs narrow; business keys "
         "(IATA codes, tail numbers, licences, emails, txn refs) are UNIQUE. "
         "1NF: masters remove repeating groups. 2NF: attributes depend on whole "
         "keys. 3NF: no transitive dependencies (city lives once in Airports). "
         "BCNF-clean: every determinant is a key.")
pdf.table(["Table", "PK", "Key rules"],
          [["Airports", "airport_id", "UNIQUE iata, name"],
           ["Airlines", "airline_id", "UNIQUE name, iata"],
           ["Aircraft", "aircraft_id", "UNIQUE tail; CHECK cap 1..850"],
           ["Flights", "flight_id", "UNIQUE number; 2 airport FKs; dep<>arr"],
           ["Flight_Instances", "instance_id", "UNIQUE(flight, dep_time)"],
           ["Terminals/Gates/Runways", "own ids", "UNIQUE per parent (anti-clash)"],
           ["Passengers", "passenger_id", "UNIQUE passport, email"],
           ["Bookings", "booking_id", "UNIQUE(instance, seat)"],
           ["Baggage", "(booking, seq)", "weak entity; 0 < kg <= 100"],
           ["Payments/Check_Ins", "own ids", "UNIQUE booking_id (1-to-1)"],
           ["Employees+subtypes", "employee_id", "subtype PK = supertype PK"],
           ["Crew_Assignments", "assignment_id", "UNIQUE(employee, instance)"]])

pdf.h1("7. SQL Implementation")
pdf.h2("DDL")
pdf.para("01-travel-core.sql: 13 travel tables with keys, CASCADE where children "
         "cannot outlive parents, RESTRICT on airports (deleting an airport must "
         "never wipe flights). 02-staff-roles.sql: staff hierarchy plus DCL - "
         "sky_admin (all), sky_staff (read-write), sky_viewer (read-only), verified "
         "with SHOW GRANTS on the exact database name.")
pdf.h2("DML")
pdf.para("generate.py (seed 42) writes seed_data.sql: 5 airports, 3 airlines, 10 "
         "aircraft, 10 flights, 140 instances over 14 days, 500 passengers, ~14k "
         "bookings at 35-80% load, ~14k payments, ~17k bags (20% overweight tail), "
         "~5k check-ins, 8 staff with assignments. Verified: zero duplicate seats, "
         "all FKs in range.")
pdf.h2("DCL")
pdf.para("Least-privilege roles as above; viewer INSERT is denied (test R-b).")

pdf.h1("8. Advanced SQL Features")
pdf.para("Views: flight_board_view (whole departure board, one query); "
         "booking_receipt_view (price + fee: 20 kg free, Rs 500/excess kg). "
         "Procedure MakeBooking inserts booking + Pending payment in one "
         "transaction with an exit handler (rollback + re-signal). Trigger "
         "trg_booking_capacity refuses inserts past aircraft capacity with "
         "SQLSTATE 45000. Join pack (10 queries) + analytics pack (GROUP BY, "
         "HAVING, CASE, subquery) cover every module.")

pdf.h1("9. Transaction Management")
pdf.para("Demo A commits booking+payment together. Demo B rolls back on payment "
         "failure and the seat stays free (atomicity). Demo C uses two sessions "
         "to show REPEATABLE READ isolation. Script: 04-transactions.sql.")

pdf.h1("10. Indexing and Optimization")
pdf.para("FK columns are already auto-indexed by InnoDB and were not re-indexed. "
         "Four workload indexes: booking_status, scheduled_departure, "
         "(last_name, first_name), weight_kg - each with a before/after EXPLAIN "
         "pair in the test log showing fewer rows examined.")

pdf.h1("11. Testing and Validation")
pdf.para("TESTING.md: 30 checks in 8 groups - joins, analytics, constraint "
         "rejections (duplicate seat ERROR 1062, impossible route, bad weight, "
         "RESTRICT, CASCADE), procedure atomicity, transaction demos, EXPLAIN "
         "pairs, grants, scale counts. Each states its expected result.")

pdf.h1("12. Documentation")
pdf.para("This report (docx + pdf), README.md (run order, users, rules, screenshot "
         "workflow), TESTING.md, decision journal C1-C13 in the SQL comments, "
         "ER diagram, slide deck, Flask brief report.")

pdf.h1("13. Presentation and Reporting")
pdf.para("This report, 11-slide deck, all sources, README, test log, 2-3 minute "
         "demo video (departure board, live booking, duplicate-seat refusal, fee "
         "receipt).")

pdf.h1("Conclusion")
pdf.para("Every problem item is closed by a named mechanism, every mechanism has "
         "a test, and the system holds production-shaped volume while answering "
         "analytics in single queries. The Flask project reuses this design on "
         "SQLite with raw SQL and full CRUD.")

pdf.h1("References")
pdf.bullets(["Ramakrishna R., Gehrke J. Database Management Systems, 3rd Ed.",
             "Silberschatz, Korth, Sudarshan. Database System Concepts, 7th Ed.",
             "MySQL 8.0 Reference Manual: constraints, triggers, EXPLAIN."])

pdf.output("docs/SkyRoute_Report.pdf")
print("pdf written")
