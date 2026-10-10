"""One-off v2 patch for REPORT_TEXT.md: unicode normalize + renames + removals."""
import re

p = "dbms/docs/REPORT_TEXT.md"
s = open(p, encoding="utf-8").read()
for a, b in [("—", "-"), ("–", "-"), ("≤", "<=")]:
    s = s.replace(a, b)
subs = [
    ("Flight_Instances", "Departures"),
    ("Flight_Instance", "Departure"),
    ("flight_instances", "departures"),
    ("flight_instance", "departure"),
    ("instance_id", "departure_id"),
    ("instance_status", "departure_status"),
    ("(instance, seat)", "(departure, seat)"),
    ("instance, seat_number", "departure_id, seat_number"),
    ("140 flight instances", "140 departures"),
    ("140 dated instances", "140 dated departures"),
    ("Tables: 18", "Tables: 16"),
    ("Terminal/Gate/Runway infrastructure", "Terminal/Gate infrastructure"),
    ("assign aircraft, gate, runway and crew", "assign aircraft, gate and crew"),
    ("18 InnoDB tables", "16 InnoDB tables"),
    ("Gates, Runways (UNIQUE per parent", "Gates (UNIQUE per parent"),
    ("Crew_Assignments (UNIQUE(employee, instance)).", ""),
    ("01-travel-core.sql creates the 13 travel tables",
     "01-travel-core.sql creates the 12 travel tables"),
    ("a unique seat-per-instance key", "a unique seat-per-departure key"),
    ("check-ins on departed instances, 8", "check-ins on past departures, 8"),
    ("Gate,\nRunway, Passenger", "Gate, Passenger"),
]
missing = [a for a, _ in subs if a not in s]
print("missing:", missing if missing else "(none)")
for a, b in subs:
    s = s.replace(a, b)
s = re.sub(r"Ground_Staff subtypes, and Crew_Assignment\nas the associative entity between staff and dated flights\.",
           "Ground_Staff subtypes.", s)
s = re.sub(r"[ \t]+", " ", s)
open(p, "w", encoding="utf-8").write(s)
left = [ln for ln in s.splitlines()
        if re.search(r"nstance|unway|Crew_Assign|Tables: 1|13 travel|UNIQUE\(employee", ln)]
print("leftovers:", left if left else "(none)")
