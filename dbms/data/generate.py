"""SkyRoute seed-data generator v2 (MySQL dialect, deterministic, seed 42).

v2: Departures (renamed), no Runways, no Crew_Assignments.
Usage (from dbms/):  python data/generate.py  ->  data/seed_data.sql
Knobs: NUM_DAYS, ROUTES, LOAD_MIN/LOAD_MAX.
"""
import random
from datetime import date, timedelta

random.seed(42)

NUM_DAYS = 21
START_DAY = date(2026, 11, 1)
AIRPORTS = [
    ("HYD", "Rajiv Gandhi International Airport", "Hyderabad"),
    ("BLR", "Kempegowda International Airport", "Bengaluru"),
    ("BOM", "Chhatrapati Shivaji Maharaj International Airport", "Mumbai"),
    ("DEL", "Indira Gandhi International Airport", "New Delhi"),
    ("MAA", "Chennai International Airport", "Chennai"),
]
AIRLINES = [("IndiGo", "6E"), ("Air India", "AI"), ("SpiceJet", "SG")]
# (airline_idx, dep, arr, flight_no, dep_t, arr_t, model, capacity)
ROUTES = [
    (0, "HYD", "BLR", "6E-501", "08:00", "09:20", "Airbus A320neo", 180),
    (0, "BLR", "HYD", "6E-502", "10:10", "11:30", "Airbus A320neo", 180),
    (0, "HYD", "BOM", "6E-511", "18:05", "19:35", "Airbus A321neo", 222),
    (1, "DEL", "BOM", "AI-654", "07:15", "09:25", "Airbus A321", 182),
    (1, "BOM", "MAA", "AI-671", "13:40", "15:35", "Airbus A320", 168),
    (1, "MAA", "HYD", "AI-682", "17:20", "18:35", "Airbus A320", 168),
    (2, "BLR", "DEL", "SG-893", "06:30", "09:10", "Boeing 737-8", 189),
    (2, "DEL", "HYD", "SG-894", "20:00", "22:15", "Boeing 737-8", 189),
    (0, "HYD", "MAA", "6E-531", "11:45", "13:00", "ATR 72-600", 78),
    (2, "BOM", "DEL", "SG-901", "09:30", "11:40", "Boeing 737-8", 189),
    (1, "HYD", "DEL", "AI-701", "09:05", "11:15", "Airbus A320neo", 180),
    (1, "DEL", "BLR", "AI-702", "12:20", "15:00", "Airbus A320neo", 180),
    (0, "BOM", "HYD", "6E-541", "07:40", "09:05", "Airbus A320neo", 180),
    (2, "BLR", "MAA", "SG-902", "15:25", "16:30", "Boeing 737-700", 148),
    (0, "MAA", "BOM", "6E-551", "19:10", "21:05", "Airbus A321neo", 222),
    (2, "DEL", "MAA", "SG-903", "10:50", "13:45", "Boeing 737-8", 189),
]
LOAD_MIN, LOAD_MAX = 0.35, 0.80
FIRST = ["Aarav", "Ananya", "Arjun", "Diya", "Ishaan", "Kavya", "Krishna",
         "Meera", "Nikhil", "Pooja", "Priya", "Rahul", "Riya", "Rohan",
         "Sanya", "Sneha", "Vikram", "Aisha", "Aditya", "Neha"]
LAST = ["Sharma", "Rao", "Singh", "Reddy", "Nair", "Gupta", "Mehta",
        "Iyer", "Patel", "Kumar", "Das", "Menon", "Verma", "Joshi"]
STAFF = ["Karan Patel", "Suresh Kumar", "Rajesh Gupta", "Nitin Joshi",
         "Amit Verma", "Pooja Iyer", "Meera Das", "Arjun Mehta"]
SEAT_LETTERS = ["A", "B", "C", "D", "E", "F"]

airport_id = {iata: n + 1 for n, (iata, _, _) in enumerate(AIRPORTS)}
lines = ["USE skyroute_db;", "SET FOREIGN_KEY_CHECKS = 0;"]

lines.append("INSERT INTO Airports (airport_id, iata_code, airport_name, city, country) VALUES " +
             ", ".join(f"({n + 1}, '{i}', '{nm}', '{c}', 'India')"
                       for n, (i, nm, c) in enumerate(AIRPORTS)) + ";")

lines.append("INSERT INTO Airlines (airline_id, airline_name, iata_code, country) VALUES " +
             ", ".join(f"({n + 1}, '{nm}', '{i}', 'India')"
                       for n, (nm, i) in enumerate(AIRLINES)) + ";")

cap_of_route, ac_rows = {}, []
for r, route in enumerate(ROUTES):
    al, _, _, _, _, _, model, cap = route
    ac_rows.append(f"({r + 1}, 'VT-SR{r + 1:03d}', '{model}', {cap}, {al + 1})")
    cap_of_route[r] = cap
lines.append("INSERT INTO Aircraft (aircraft_id, tail_number, model, capacity, airline_id) VALUES " +
             ", ".join(ac_rows) + ";")

term_rows, gate_rows, gate_of = [], [], {}
gid = 1
for n, (iata, _, _) in enumerate(AIRPORTS):
    aid = n + 1
    term_rows.append(f"({aid}, {aid}, 'T1', '{iata} Terminal 1', 'Operational')")
    gate_of[aid] = []
    for g in range(1, 5):
        gate_rows.append(f"({gid}, {aid}, 'G{g}', 'Open')")
        gate_of[aid].append(gid)
        gid += 1
lines.append("INSERT INTO Terminals (terminal_id, airport_id, terminal_code, terminal_name, terminal_status) VALUES " +
             ", ".join(term_rows) + ";")
lines.append("INSERT INTO Gates (gate_id, terminal_id, gate_number, gate_status) VALUES " +
             ", ".join(gate_rows) + ";")

lines.append("INSERT INTO Flights (flight_id, flight_number, airline_id, departure_airport_id, "
             "arrival_airport_id, sched_departure, sched_arrival, flight_status) VALUES " +
             ", ".join(f"({r + 1}, '{fno}', {al + 1}, {airport_id[dep]}, {airport_id[arr]}, "
                       f"'{dt}:00', '{at}:00', 'Active')"
                       for r, (al, dep, arr, fno, dt, at, _, _) in enumerate(ROUTES)) + ";")

dep_rows, departures = [], []
did = 1
for day in range(NUM_DAYS):
    d = START_DAY + timedelta(days=day)
    for r, route in enumerate(ROUTES):
        _, dep, _, _, dt, at, _, _ = route
        sdep = f"{d} {dt}:00"
        sarr = f"{d + timedelta(days=1) if at < dt else d} {at}:00"
        g = gate_of[airport_id[dep]][(r + day) % 4]
        past = d < date(2026, 11, 11)
        st = "'Arrived'" if past else "'Scheduled'"
        ad = f"'{sdep}'" if past else "NULL"
        aa = f"'{sarr}'" if past else "NULL"
        dep_rows.append(f"({did}, {r + 1}, '{sdep}', '{sarr}', {ad}, {aa}, {st}, {r + 1}, {g})")
        departures.append((did, r, past, sdep))
        did += 1
lines.append("INSERT INTO Departures (departure_id, flight_id, scheduled_departure, scheduled_arrival, "
             "actual_departure, actual_arrival, departure_status, aircraft_id, gate_id) VALUES " +
             ", ".join(dep_rows) + ";")

N_PAX = 500
pax_rows = []
for p in range(1, N_PAX + 1):
    fn, ln = random.choice(FIRST), random.choice(LAST)
    pax_rows.append(
        f"({p}, '{fn}', '{ln}', 'P{100000 + p}', 'India', '98{10000000 + p}', "
        f"'{fn.lower()}.{ln.lower()}{p}@example.com')")
lines.append("INSERT INTO Passengers (passenger_id, first_name, last_name, passport_number, nationality, phone, email) VALUES " +
             ", ".join(pax_rows) + ";")

lines.append("INSERT INTO Employees (employee_id, full_name, email, phone, base_airport, hire_date) VALUES " +
             ", ".join(f"({n + 1}, '{nm}', '{nm.lower().replace(' ', '.')}@skyroute.aero', "
                       f"'97{10000000 + n}', 1, '2024-06-01')"
                       for n, nm in enumerate(STAFF)) + ";")
lines.append("INSERT INTO Pilots (employee_id, license_number, license_type) VALUES "
             "(1, 'IND-PIL-2001', 'ATPL'), (2, 'IND-PIL-2002', 'ATPL');")
lines.append("INSERT INTO Crew_Members (employee_id, crew_role) VALUES "
             "(3, 'Purser'), (4, 'Flight Attendant'), (5, 'Flight Attendant');")
lines.append("INSERT INTO Ground_Staff (employee_id, ground_role, airport_id) VALUES "
             "(6, 'Ramp Agent', 1), (7, 'Baggage Handler', 1), (8, 'Check-in Staff', 2);")

CLASSES = ["Economy"] * 7 + ["Premium Economy", "Business"]
PRICE = {"Economy": 4500, "Premium Economy": 7500, "Business": 14000}
b_rows, pay_rows, bag_rows, chk_rows = [], [], [], []
bid, payid, chkid = 1, 1, 1
for did, r, past, sdep in departures:
    cap = cap_of_route[r]
    n_sold = max(1, int(cap * random.uniform(LOAD_MIN, LOAD_MAX)))
    seats = [f"{row}{l}" for row in range(1, cap // 6 + 2) for l in SEAT_LETTERS][:cap]
    for seat in random.sample(seats, n_sold):
        cls = random.choice(CLASSES)
        price = PRICE[cls] + random.randint(-300, 900)
        pax = random.randint(1, N_PAX)
        st = "'Confirmed'" if not past else random.choice(["'Confirmed'", "'Confirmed'", "'Refunded'"])
        b_rows.append(f"({bid}, {pax}, {did}, '{seat}', '{cls}', {price}, {st}, '{sdep}')")
        pstat = "'Paid'" if random.random() < 0.92 else "'Pending'"
        pay_rows.append(f"({payid}, {bid}, {price}, 'UPI', {pstat}, 'TXNSR{100000 + payid}', '{sdep}')")
        payid += 1
        for seq in range(1, random.choice([1, 1, 1, 2]) + 1):
            w = round(random.uniform(5, 20), 2) if random.random() < 0.8 else round(random.uniform(20.5, 32), 2)
            bag_rows.append(f"({bid}, {seq}, {w})")
        if past and random.random() < 0.7:
            chk_rows.append(f"({chkid}, {bid}, '{sdep}', 'Boarded')")
            chkid += 1
        bid += 1
lines.append("INSERT INTO Bookings (booking_id, passenger_id, departure_id, seat_number, travel_class, price, booking_status, booked_at) VALUES " +
             ", ".join(b_rows) + ";")
lines.append("INSERT INTO Payments (payment_id, booking_id, amount, pay_method, pay_status, txn_reference, paid_at) VALUES " +
             ", ".join(pay_rows) + ";")
lines.append("INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES " +
             ", ".join(bag_rows) + ";")
if chk_rows:
    lines.append("INSERT INTO Check_Ins (checkin_id, booking_id, checkin_time, boarding_status) VALUES " +
                 ", ".join(chk_rows) + ";")
lines.append("SET FOREIGN_KEY_CHECKS = 1;")

with open("data/seed_data.sql", "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
print(f"departures={len(departures)} bookings={bid - 1} payments={payid - 1} bags={len(bag_rows)} checkins={chkid - 1}")
