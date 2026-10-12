"""Builds python/flask_app/skyroute.db from schema_sqlite.sql (v2).
Stdlib sqlite3 only, deterministic (seed 7). Run from repo root:
    python python/flask_app/seed_sqlite.py

Realism rules (the demo must survive scrutiny): each traveler takes 1-4
trips, at most one departure per day, so nobody boards two flights at once
and nobody lives on planes. Seats never double-sell per departure.
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
            ("DEL", "Indira Gandhi International Airport", "New Delhi"),
            ("MAA", "Chennai International Airport", "Chennai")]
con.executemany(
    "INSERT INTO Airports (iata_code, airport_name, city) VALUES (?, ?, ?)", AIRPORTS)
con.executemany(
    "INSERT INTO Airlines (airline_name, iata_code) VALUES (?, ?)",
    [("IndiGo", "6E"), ("Air India", "AI"), ("SpiceJet", "SG")])
FLEET = [("VT-SK101", "Airbus A320neo", 180, 1), ("VT-SK102", "Airbus A321neo", 222, 1),
         ("VT-SK201", "Airbus A321", 182, 2), ("VT-SK301", "Boeing 737-8", 189, 3),
         ("VT-SK103", "ATR 72-600", 78, 1)]
con.executemany(
    "INSERT INTO Aircraft (tail_number, model, capacity, airline_id) VALUES (?, ?, ?, ?)", FLEET)

SCHED = [  # (flight_no, airline, dep, arr, dep_t, arr_t, aircraft)
    ("6E-501", 1, 1, 2, "08:00:00", "09:20:00", 1),
    ("6E-502", 1, 2, 1, "10:10:00", "11:30:00", 1),
    ("AI-654", 2, 4, 3, "07:15:00", "09:25:00", 3),
    ("SG-893", 3, 2, 4, "06:30:00", "09:10:00", 4),
    ("6E-511", 1, 1, 3, "18:05:00", "19:35:00", 2),
    ("6E-561", 1, 5, 1, "07:30:00", "08:45:00", 5),
    ("6E-562", 1, 1, 5, "19:20:00", "20:35:00", 5)]
con.executemany(
    "INSERT INTO Flights (flight_number, airline_id, departure_airport_id, "
    "arrival_airport_id, sched_departure, sched_arrival) VALUES (?, ?, ?, ?, ?, ?)",
    [row[:6] for row in SCHED])

for aid in (1, 2, 3, 4, 5):
    t = con.execute("INSERT INTO Terminals (airport_id, terminal_code, terminal_name) "
                    "VALUES (?, 'T1', ?)", (aid, f"T{aid} Main")).lastrowid
    for g in range(1, 4):
        con.execute("INSERT INTO Gates (terminal_id, gate_number) VALUES (?, ?)", (t, f"G{g}"))

N_PAX = 600

def fetch_names(pool=800):
    """Real diverse traveler names from the web (randomuser.me, Indian
    sample — fits our domestic network). Cached to passengers_source.json
    so reseeds are stable and offline-safe. None = use built-in pool."""
    import json as _json
    import urllib.request
    cache = ROOT / "passengers_source.json"
    if cache.exists():
        try:
            return _json.loads(cache.read_text(encoding="utf-8"))
        except ValueError:
            pass
    try:
        req = urllib.request.Request(
            f"https://randomuser.me/api/?results={pool}&nat=in&inc=name,email,phone&noinfo",
            headers={"User-Agent": "skyroute-dbms-demo"})
        data = _json.load(urllib.request.urlopen(req, timeout=40))["results"]
        names = [(d["name"]["first"].title(), d["name"]["last"].title(),
                  d["email"].lower(),
                  ("".join(c for c in d["phone"] if c.isdigit())[-10:]
                   or "9000000000"))
                 for d in data]
        cache.write_text(_json.dumps(names), encoding="utf-8")
        return names
    except Exception as exc:
        print("web names unavailable, using built-in pool:", exc)
        return None

NAMES = fetch_names()
# Trip budgets: most travelers fly once, some twice, nobody more. This keeps
# every traveler's story believable: no 14-trip frequent flyers in a demo.
added, i = 0, 0
while added < N_PAX:
    if NAMES:
        fn, ln, email, phone = NAMES[i % len(NAMES)]
        i += 1
        if i > len(NAMES) + N_PAX + 500:
            raise SystemExit("ran out of unique web names")
        try:
            con.execute("INSERT INTO Passengers (first_name, last_name, passport_number, phone, email) "
                        "VALUES (?, ?, ?, ?, ?)",
                        (fn, ln, f"D{200000 + added + 1}", phone, email))
        except sqlite3.IntegrityError:
            continue  # duplicate email in source data: skip them
        added += 1
    else:
        FIRST = ["Aarav", "Ananya", "Arjun", "Diya", "Kavya", "Meera",
                 "Rahul", "Riya", "Rohan", "Sneha"]
        LAST = ["Sharma", "Rao", "Singh", "Reddy", "Nair", "Gupta",
                "Iyer", "Kumar"]
        for j in range(1, N_PAX + 1):
            fn, ln = random.choice(FIRST), random.choice(LAST)
            con.execute("INSERT INTO Passengers (first_name, last_name, passport_number, phone, email) "
                        "VALUES (?, ?, ?, ?, ?)",
                        (fn, ln, f"D{200000 + j}", f"98{10000000 + j}",
                         f"{fn.lower()}.{ln.lower()}{j}@example.com"))
        added = N_PAX

deps = []  # (did, day, cap)
did = 0
# Randomized sparse timetable: every date flies a different random mix of
# flights, and some routes are dark on some days — like a real schedule.
# Pinned combos keep the demo stable: 6E-501 + 6E-561 always fly Nov 3,
# nothing MAA-HYD on Nov 2, departure #1 is 6E-501 on Nov 1.
# Deterministic (seed 7 above), so reseeds reproduce the same week.
DAY_OPS = {}
while True:
    seen, ok = set(), True
    for day in range(7):
        ops = set(random.sample(range(1, 8), random.randint(3, 5)))
        if day == 0:
            ops.add(1)
        if day == 2:
            ops |= {1, 6}
        if day == 1:
            ops.discard(6)
        key = tuple(sorted(ops))
        if key in seen:
            ok = False
            break
        seen.add(key)
        DAY_OPS[day] = sorted(ops)
    if ok and all(sum(f in DAY_OPS[d] for d in range(7)) >= 2 for f in range(1, 8)):
        break
for day in range(7):
    d = date(2026, 11, 1) + timedelta(days=day)
    for f in DAY_OPS[day]:
        did += 1
        dep_t, arr_t = SCHED[f - 1][4], SCHED[f - 1][5]
        gate = con.execute(
            "SELECT gate_id FROM Gates WHERE terminal_id = ? ORDER BY gate_id",
            (SCHED[f - 1][2],)).fetchall()[(f + day) % 3][0]
        con.execute("INSERT INTO Departures (flight_id, scheduled_departure, scheduled_arrival, "
                    "departure_status, aircraft_id, gate_id) VALUES (?, ?, ?, 'Scheduled', ?, ?)",
                    (f, f"{d} {dep_t}", f"{d} {arr_t}", SCHED[f - 1][6], gate))
        deps.append((did, day, FLEET[SCHED[f - 1][6] - 1][2]))

trips = [0] * (N_PAX + 1)
daybooked = [set() for _ in range(N_PAX + 1)]
budget = [0] + [1 if random.random() < 0.7 else 2 for _ in range(N_PAX)]
for did, day, cap in sorted(deps, key=lambda _: random.random()):
    want = max(1, int(cap * random.uniform(0.10, 0.22)))
    elig = [p for p in range(1, N_PAX + 1)
            if trips[p] < budget[p] and day not in daybooked[p]]
    chosen = random.sample(elig, min(want, len(elig)))
    seats = [f"{r}{l}" for r in range(1, cap // 6 + 2) for l in "ABCDEF"][:cap]
    for pax, seat in zip(chosen, random.sample(seats, len(chosen))):
        price = 4500 + random.randint(-300, 900)
        bid = con.execute("INSERT INTO Bookings (passenger_id, departure_id, seat_number, price) "
                          "VALUES (?, ?, ?, ?)", (pax, did, seat, price)).lastrowid
        con.execute("INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference) "
                    "VALUES (?, ?, 'UPI', 'Paid', ?)", (bid, price, f"TXNAPP{100000 + bid}"))
        con.execute("INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (?, 1, ?)",
                    (bid, round(random.uniform(5, 20) if random.random() < 0.8
                                 else random.uniform(20.5, 32), 2)))
        trips[pax] += 1
        daybooked[pax].add(day)

con.commit()
n = lambda t: con.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
top = con.execute("SELECT passenger_id, COUNT(*) c FROM Bookings GROUP BY 1 ORDER BY c DESC LIMIT 1").fetchone()
names = con.execute("SELECT COUNT(DISTINCT first_name), COUNT(DISTINCT last_name) FROM Passengers").fetchone()
print(f"departures={n('Departures')} bookings={n('Bookings')} bags={n('Baggage')} "
      f"max trips by one traveler={top[1]} distinct first/last={names[0]}/{names[1]}")
con.close()
