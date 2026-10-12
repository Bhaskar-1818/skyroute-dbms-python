"""Single source of truth for the report: parses dbms/docs/REPORT_TEXT.md
into blocks. Both build_report.py (docx) and build_pdf.py (pdf) use this,
so the three formats can never drift apart.

Block kinds: ("title", text) ("sub", text) ("meta", text) ("h1", text)
("h2", text) ("p", text) ("bullets", [items])
"""
import re

SCHEMA_TABLE = (
    ["Table", "Primary key", "Rule that matters"],
    [["Airports", "airport_id", "UNIQUE iata, name"],
     ["Airlines", "airline_id", "UNIQUE name, iata"],
     ["Aircraft", "aircraft_id", "UNIQUE tail; CHECK cap 1-850"],
     ["Flights", "flight_id", "UNIQUE number; dep <> arr airports"],
     ["Departures", "departure_id", "UNIQUE(flight, dep datetime)"],
     ["Terminals / Gates", "own ids", "UNIQUE per parent (anti-clash)"],
     ["Passengers", "passenger_id", "UNIQUE passport, email"],
     ["Bookings", "booking_id", "UNIQUE(departure, seat)"],
     ["Baggage", "(booking, seq)", "weak entity; 0 < kg <= 100"],
     ["Payments / Check-Ins", "own ids", "UNIQUE booking (one-to-one)"],
     ["Employees + role tables", "employee_id", "role PK = employee PK"]],
)


def load(path="dbms/docs/REPORT_TEXT.md"):
    blocks, pending = [], []
    with open(path, encoding="utf-8") as f:
        lines = [ln.rstrip() for ln in f]

    def flush():
        if pending:
            blocks.append(("bullets", pending.copy()))
            pending.clear()

    for ln in lines:
        s = ln.strip()
        if not s:
            flush()
            continue
        if s.startswith("# ") and not s.startswith("###"):
            flush()
            blocks.append(("title", s[2:].strip()))
        elif s.startswith("### "):
            flush()
            blocks.append(("sub", s[4:].strip()))
        elif s.startswith("## "):
            flush()
            blocks.append(("h1", s[3:].strip()))
        elif re.match(r"^\d+\.\s+[A-Z]", s) and len(s) < 60 and pending == [] and \
                blocks and blocks[-1][0] == "h1":
            # section lead-ins stay prose; numbered problem items are bullets
            blocks.append(("p", s))
        elif s.startswith("- ") or re.match(r"^\d+\.\s", s):
            pending.append(re.sub(r"^(-|\d+\.)\s+", "", s))
        elif s.startswith("Database:"):
            flush()
            blocks.append(("meta", s))
        else:
            flush()
            blocks.append(("p", s))
    flush()
    return blocks
