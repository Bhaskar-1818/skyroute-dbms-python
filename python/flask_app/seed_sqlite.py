"""Builds python/flask_app/skyroute.db from schema_sqlite.sql (v2).
Stdlib sqlite3 only, deterministic (seed 7). Run from repo root:
    python python/flask_app/seed_sqlite.py
"""
import random
import sqlite3
from datetime import date, timedelta
from pathlib import Path

random.seed(7)
ROOT = Path(__file__).resolve().parent
DB = ROOT / "skyroute.db"
if DB.exists():
    DB.unlink()

con = sqlite3.connect(DB)
con.execute("PRAGMA foreign_keys = ON")
con.executescript((ROOT / "schema_sqlite.sql").read_text(encoding="utf-8"))

AIRPORTS = [("HYD", "Rajiv Gandhi International Airport", "Hyderabad"),
            ("BLR", "Kempegowda International Airport", "Bengaluru"),
            ("BOM", "Chhatrapati Shivaji Maharaj International Airport", "Mumbai"),
            ("DEL", "Indira Gandhi International Airport", "New Delhi")]
con.executemany(
    "INSERT INTO Airports (iata_code, airport_name, city) VALUES (?, ?, ?)", AIRPORTS)
con.executemany(
    "INSERT INTO Airlines (airline_name, iata_code) VALUES (?, ?)",
    [("IndiGo", "6E"), ("Air India", "AI"), ("SpiceJet", "SG")])
FLEET = [("VT-SK101", "Airbus A320neo", 180, 1), ("VT-SK102", "Airbus A321neo", 222, 1),
         ("VT-SK201", "Airbus A321", 182, 2), ("VT-SK301", "Boeing 737-8", 189, 3)]
con.executemany(
    "INSERT INTO Aircraft (tail_number, model, capacity, airline_id) VALUES (?, ?, ?, ?)", FLEET)

SCHED = [  # (flight_no, airline, dep, arr, dep_t, arr_t, aircraft)
    ("6E-501", 1, 1, 2, "08:00:00", "09:20:00", 1),
    ("6E-502", 1, 2, 1, "10:10:00", "11:30:00", 1),
    ("AI-654", 2, 4, 3, "07:15:00", "09:25:00", 3),
    ("SG-893", 3, 2, 4, "06:30:00", "09:10:00", 4),
    ("6E-511", 1, 1, 3, "18:05:00", "19:35:00", 2)]
con.executemany(
    "INSERT INTO Flights (flight_number, airline_id, departure_airport_id, "
    "arrival_airport_id, sched_departure, sched_arrival) VALUES (?, ?, ?, ?, ?, ?)",
    [row[:6] for row in SCHED])

for aid in (1, 2, 3, 4):
    t = con.execute("INSERT INTO Terminals (airport_id, terminal_code, terminal_name) "
                    "VALUES (?, 'T1', ?)", (aid, f"T{aid} Main")).lastrowid
    for g in range(1, 4):
        con.execute("INSERT INTO Gates (terminal_id, gate_number) VALUES (?, ?)", (t, f"G{g}"))

FIRST = ["Aarav", "Ananya", "Arjun", "Diya", "Kavya", "Meera", "Rahul", "Riya", "Rohan", "Sneha"]
LAST = ["Sharma", "Rao", "Singh", "Reddy", "Nair", "Gupta", "Iyer", "Kumar"]
for i in range(1, 121):
    fn, ln = random.choice(FIRST), random.choice(LAST)
    con.execute("INSERT INTO Passengers (first_name, last_name, passport_number, phone, email) "
                "VALUES (?, ?, ?, ?, ?)",
                (fn, ln, f"D{200000 + i}", f"98{10000000 + i}", f"{fn.lower()}.{ln.lower()}{i}@example.com"))

did = 0
for day in range(7):
    d = date(2026, 11, 1) + timedelta(days=day)
    for f in range(1, 6):
        did += 1
        dep_t, arr_t = SCHED[f - 1][4], SCHED[f - 1][5]
        gate = con.execute(
            "SELECT gate_id FROM Gates WHERE terminal_id = ? ORDER BY gate_id",
            (SCHED[f - 1][2],)).fetchall()[(f + day) % 3][0]
        con.execute("INSERT INTO Departures (flight_id, scheduled_departure, scheduled_arrival, "
                    "departure_status, aircraft_id, gate_id) VALUES (?, ?, ?, 'Scheduled', ?, ?)",
                    (f, f"{d} {dep_t}", f"{d} {arr_t}", SCHED[f - 1][6], gate))
        cap = FLEET[SCHED[f - 1][6] - 1][2]
        seats = [f"{r}{l}" for r in range(1, cap // 6 + 2) for l in "ABCDEF"][:cap]
        for seat in random.sample(seats, max(1, int(cap * random.uniform(0.3, 0.7)))):
            pax = random.randint(1, 120)
            price = 4500 + random.randint(-300, 900)
            bid = con.execute("INSERT INTO Bookings (passenger_id, departure_id, seat_number, price) "
                              "VALUES (?, ?, ?, ?)", (pax, did, seat, price)).lastrowid
            con.execute("INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference) "
                        "VALUES (?, ?, 'UPI', 'Paid', ?)", (bid, price, f"TXNAPP{100000 + bid}"))
            con.execute("INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (?, 1, ?)",
                        (bid, round(random.uniform(5, 20) if random.random() < 0.8
                                     else random.uniform(20.5, 32), 2)))
con.commit()
n = lambda t: con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
print(f"departures={n('Departures')} bookings={n('Bookings')} bags={n('Baggage')} payments={n('Payments')}")
con.close()
