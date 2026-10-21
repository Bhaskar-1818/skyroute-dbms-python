"""Single source of truth for the report: parses
dbms/docs/report/REPORT_FINAL.md into blocks. build_report.py (docx) and
build_pdf.py (pdf) both use this, so the formats cannot drift apart.

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


def load(path="dbms/docs/report/REPORT_FINAL.md"):
    """Parse the report source into blocks.

    Cover block (before the first '# ') and the '--- INSERT ... ---' /
    '--- END ... ---' marker blocks are Word hand-off instructions, so they
    are stripped. Consecutive plain lines join into one paragraph, the way
    Markdown reads them, and fenced blocks become ("code", text).
    """
    blocks, pending, para, code = [], [], [], []
    in_code = False
    with open(path, encoding="utf-8") as f:
        lines = [ln.rstrip() for ln in f]

    def flush():
        if para:
            blocks.append(("p", " ".join(para)))
            para.clear()
        if pending:
            blocks.append(("bullets", pending.copy()))
            pending.clear()

    started = skipping = False
    for ln in lines:
        s = ln.strip()
        if not started:
            if s.startswith("# ") and not s.startswith("###"):
                started = True
            else:
                continue
        if s.startswith("```"):
            if in_code:
                blocks.append(("code", "\n".join(code)))
                code.clear()
                in_code = False
            else:
                flush()
                in_code = True
            continue
        if in_code:
            code.append(s)
            continue
        if s.startswith("--- INSERT") or s.startswith("--- END"):
            skipping = not skipping
            continue
        if skipping or s.startswith("--- PAGE BREAK"):
            continue
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
        elif s.startswith("- ") or re.match(r"^\d+\.\s", s):
            if para:
                flush()
            pending.append(re.sub(r"^(-|\d+\.)\s+", "", s))
        elif s.startswith("![[") and s.endswith("]]"):
            flush()
            blocks.append(("fig", s[3:-2].strip()))
        elif s.startswith("Database:") or s.startswith("Seed volume"):
            flush()
            blocks.append(("meta", s))
        else:
            para.append(s)
    if in_code and code:
        blocks.append(("code", "\n".join(code)))
    flush()
    return blocks
