"""Bhaskar DBMS Project - deterministic seed-data generator (MySQL dialect).

Produces data/seed_data.sql for skyroute_db. Reproducible: same seed -> same file.
Realism rules mirror operations: morning/evening departure banks, load factors
below aircraft capacity, baggage mostly under the 20 kg free allowance with an
overweight tail (for the fee demo), payments mostly Paid, check-ins only for
departed instances.

Usage:  python generate.py        (run from the project root)
Output: data/seed_data.sql   (run with  SOURCE seed_data.sql;  in mysql)
Scale knobs: NUM_DAYS, ROUTES, LOAD_MIN/LOAD_MAX below.
"""
import random
from datetime import date, timedelta

random.seed(42)

# ------------------------------- scale knobs --------------------------------
NUM_DAYS = 14
START_DAY = date(2026, 11, 1)
AIRPORTS = [  # iata, name, city
    ("HYD", "Rajiv Gandhi International Airport", "Hyderabad"),
    ("BLR", "Kempegowda International Airport", "Bengaluru"),
    ("BOM", "Chhatrapati Shivaji Maharaj International Airport", "Mumbai"),
    ("DEL", "Indira Gandhi International Airport", "New Delhi"),
    ("MAA", "Chennai International Airport", "Chennai"),
]
AIRLINES = [  # name, iata
    ("IndiGo", "6E"),
    ("Air India", "AI"),
    ("SpiceJet", "SG"),
]
# (airline_idx, dep_iata, arr_iata, flight_no, dep_time, arr_time, model, capacity)
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
]
LOAD_MIN, LOAD_MAX = 0.35, 0.80   # fraction of seats sold per instance
FIRST = ["Aarav", "Ananya", "Arjun", "Diya", "Ishaan", "Kavya", "Krishna",
         "Meera", "Nikhil", "Pooja", "Priya", "Rahul", "Riya", "Rohan",
         "Sanya", "Sneha", "Vikram", "Aisha", "Aditya", "Neha"]
LAST = ["Sharma", "Rao", "Singh", "Reddy", "Nair", "Gupta", "Mehta",
        "Iyer", "Patel", "Kumar", "Das", "Menon", "Verma", "Joshi"]
STAFF = ["Karan Patel", "Suresh Kumar", "Rajesh Gupta", "Nitin Joshi",
         "Amit Verma", "Pooja Iyer", "Meera Das", "Arjun Mehta"]
SEAT_LETTERS = ["A", "B", "C", "D", "E", "F"]

# ---------------------------------- build -----------------------------------
airport_id = {iata: n + 1 for n, (iata, _, _) in enumerate(AIRPORTS)}
lines = ["USE skyroute_db;", "SET FOREIGN_KEY_CHECKS = 0;"]

vals = ", ".join(
    f"({n + 1}, '{iata}', '{name}', '{city}', 'India')"
    for n, (iata, name, city) in enumerate(AIRPORTS))
lines.append("INSERT INTO Airports (airport_id, iata_code, airport_name, city, country) VALUES " + vals + ";")

vals = ", ".join(
    f"({n + 1}, '{name}', '{iata}', 'India')"
    for n, (name, iata) in enumerate(AIRLINES))
lines.append("INSERT INTO Airlines (airline_id, airline_name, iata_code, country) VALUES " + vals + ";")

aircraft_of_route = {}
ac_rows = []
for r, route in enumerate(ROUTES):
    airline_idx, _, _, _, _, _, model, cap = route
    ac_rows.append(f"({r + 1}, 'VT-SR{r + 1:03d}', '{model}', {cap}, {airline_idx + 1})")
    aircraft_of_route[r] = (r + 1, cap)
lines.append("INSERT INTO Aircraft (aircraft_id, tail_number, model, capacity, airline_id) VALUES "
             + ", ".join(ac_rows) + ";")

# one terminal + 4 gates + 1 runway per airport (gate clash demo needs >1 gate)
term_rows, gate_rows, run_rows, gate_of_airport = [], [], [], {}
gid = 1
for n, (iata, _, _) in enumerate(AIRPORTS):
    aid = n + 1
    term_rows.append(f"({aid}, {aid}, 'T1', '{iata} Terminal 1', 'Operational')")
    gate_of_airport[aid] = []
    for g in range(1, 5):
        gate_rows.append(f"({gid}, {aid}, 'G{g}', 'Open')")
        gate_of_airport[aid].append(gid)
        gid += 1
    run_rows.append(f"({aid}, {aid}, '09L/27R', 3700.00, 'Active')")
lines.append("INSERT INTO Terminals (terminal_id, airport_id, terminal_code, terminal_name, terminal_status) VALUES "
             + ", ".join(term_rows) + ";")
lines.append("INSERT INTO Gates (gate_id, terminal_id, gate_number, gate_status) VALUES "
             + ", ".join(gate_rows) + ";")
lines.append("INSERT INTO Runways (runway_id, airport_id, runway_code, length_metre, runway_status) VALUES "
             + ", ".join(run_rows) + ";")

fl_rows = []
for r, route in enumerate(ROUTES):
    al, dep, arr, fno, dt, at, _, _ = route
    fl_rows.append(f"({r + 1}, '{fno}', {al + 1}, {airport_id[dep]}, {airport_id[arr]}, "
                   f"'{dt}:00', '{at}:00', 'Active')")
lines.append("INSERT INTO Flights (flight_id, flight_number, airline_id, departure_airport_id, "
             "arrival_airport_id, sched_departure, sched_arrival, flight_status) VALUES "
             + ", ".join(fl_rows) + ";")

# instances: every route, every day
inst_rows, instances = [], []
iid = 1
for day in range(NUM_DAYS):
    d = START_DAY + timedelta(days=day)
    for r, route in enumerate(ROUTES):
        al, dep, arr, _, dt, at, _, _ = route
        sdep = f"{d} {dt}:00"
        arr_d = d + timedelta(days=1) if at < dt else d
        sarr = f"{arr_d} {at}:00"
        ac, _ = aircraft_of_route[r]
        g = gate_of_airport[airport_id[dep]][(r + day) % 4]  # rotate gates
        past = d < date(2026, 11, 8)
        status = "'Arrived'" if past else "'Scheduled'"
        ad = f"'{sdep}'" if past else "NULL"
        aa = f"'{sarr}'" if past else "NULL"
        inst_rows.append(f"({iid}, {r + 1}, '{sdep}', '{sarr}', {ad}, {aa}, {status}, {ac}, {g}, {airport_id[dep]})")
        instances.append((iid, r, ac, past, sdep))
        iid += 1
lines.append("INSERT INTO Flight_Instances (instance_id, flight_id, scheduled_departure, scheduled_arrival, "
             "actual_departure, actual_arrival, instance_status, aircraft_id, gate_id, runway_id) VALUES "
             + ", ".join(inst_rows) + ";")

# passengers
N_PAX = 500
pax_rows = []
for p in range(1, N_PAX + 1):
    fn, ln = random.choice(FIRST), random.choice(LAST)
    pax_rows.append(f"({p}, '{fn}', '{ln}', 'P{100000 + p}', 'India', '98{10000000 + p}', "
                    f"'{fn.lower()}.{ln.lower()}{p}@example.com')")
lines.append("INSERT INTO Passengers (passenger_id, first_name, last_name, passport_number, nationality, phone, email) VALUES "
             + ", ".join(pax_rows) + ";")

# staff (8) + subtypes + crew assignments on early instances
emp_rows = [f"({n + 1}, '{name}', '{name.lower().replace(' ', '.')}@skyroute.aero', '97{10000000 + n}', 1, '2024-06-01')"
            for n, name in enumerate(STAFF)]
lines.append("INSERT INTO Employees (employee_id, full_name, email, phone, base_airport, hire_date) VALUES "
             + ", ".join(emp_rows) + ";")
lines.append("INSERT INTO Pilots (employee_id, license_number, license_type) VALUES "
             "(1, 'IND-PIL-2001', 'ATPL'), (2, 'IND-PIL-2002', 'ATPL');")
lines.append("INSERT INTO Crew_Members (employee_id, crew_role) VALUES "
             "(3, 'Purser'), (4, 'Flight Attendant'), (5, 'Flight Attendant');")
lines.append("INSERT INTO Ground_Staff (employee_id, ground_role, airport_id) VALUES "
             "(6, 'Ramp Agent', 1), (7, 'Baggage Handler', 1), (8, 'Check-in Staff', 2);")
ca_rows = []
for iid, r, ac, past, sdep in instances[:40]:
    ca_rows.append(f"(NULL, 1, {iid}, 'Captain')")
    ca_rows.append(f"(NULL, 3, {iid}, 'Purser')")
lines.append("INSERT INTO Crew_Assignments (assignment_id, employee_id, instance_id, role_on_flight) VALUES "
             + ", ".join(ca_rows) + ";")

# bookings: load factor of capacity, seats sampled without replacement
CLASSES = ["Economy"] * 7 + ["Premium Economy", "Business"]
PRICE = {"Economy": 4500, "Premium Economy": 7500, "Business": 14000}
b_rows, pay_rows, bag_rows, chk_rows = [], [], [], []
bid, payid, chkid = 1, 1, 1
for iid, r, ac, past, sdep in instances:
    _, cap = aircraft_of_route[r]
    n_sold = max(1, int(cap * random.uniform(LOAD_MIN, LOAD_MAX)))
    rows_n = (cap // 6) + 1
    seats = [f"{row}{ltr}" for row in range(1, rows_n + 1) for ltr in SEAT_LETTERS][:cap]
    for seat in random.sample(seats, n_sold):
        cls = random.choice(CLASSES)
        price = PRICE[cls] + random.randint(-300, 900)
        pax = random.randint(1, N_PAX)
        st = "'Confirmed'" if not past else random.choice(["'Confirmed'", "'Confirmed'", "'Refunded'"])
        b_rows.append(f"({bid}, {pax}, {iid}, '{seat}', '{cls}', {price}, {st}, '{sdep}')")
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
lines.append("INSERT INTO Bookings (booking_id, passenger_id, instance_id, seat_number, travel_class, price, booking_status, booked_at) VALUES "
             + ", ".join(b_rows) + ";")
lines.append("INSERT INTO Payments (payment_id, booking_id, amount, pay_method, pay_status, txn_reference, paid_at) VALUES "
             + ", ".join(pay_rows) + ";")
lines.append("INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES "
             + ", ".join(bag_rows) + ";")
if chk_rows:
    lines.append("INSERT INTO Check_Ins (checkin_id, booking_id, checkin_time, boarding_status) VALUES "
                 + ", ".join(chk_rows) + ";")
lines.append("SET FOREIGN_KEY_CHECKS = 1;")

with open("data/seed_data.sql", "w", encoding="utf-8") as f:
    f.write("\n".join(lines) + "\n")
print(f"instances={len(instances)} bookings={bid - 1} payments={payid - 1} bags={len(bag_rows)} checkins={chkid - 1}")
