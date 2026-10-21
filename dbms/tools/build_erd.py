"""SUPERSEDED by build_chen.py (v2 true-Chen ER). Kept for history; running this
would redraw the old v1 boxes (Runways/Flight_Instances/Crew_Assignments).
Use:  python dbms/tools/build_chen.py  ->  SkyRoute_ER.drawio + ER_Diagram.png"""
from PIL import Image, ImageDraw

W, H = 2200, 1500
img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)

def box(x, y, w, h, title, attrs, weak=False):
    d.rectangle([x, y, x + w, y + h], outline="black", width=3)
    if weak:  # double border = weak entity
        d.rectangle([x + 6, y + 6, x + w - 6, y + h - 6], outline="black", width=2)
    d.rectangle([x, y, x + w, y + 34], fill=(20, 60, 120))
    d.text((x + 10, y + 9), title, fill="white")
    for i, a in enumerate(attrs):
        mark = "*" if a.endswith("PK") else ("#" if "FK" in a else "-")
        d.text((x + 12, y + 42 + i * 20), f"{mark} {a}", fill="black")

def link(x1, y1, x2, y2, label):
    d.line([x1, y1, x2, y2], fill="black", width=2)
    mx, my = (x1 + x2) // 2, (y1 + y2) // 2 - 18
    d.rectangle([mx - 4, my - 4, mx + len(label) * 7 + 4, my + 16], fill="white")
    d.text((mx, my), label, fill="black")

d.text((30, 15), "SkyRoute ER Diagram  ( * = PK,  # = FK )   double border = weak entity",
       fill="black")

# row 1: masters
box(60, 70, 300, 220, "Airports", ["airport_id PK", "iata_code UQ", "airport_name UQ", "city", "country"])
box(480, 70, 300, 220, "Airlines", ["airline_id PK", "airline_name UQ", "iata_code UQ"])
box(900, 70, 300, 220, "Aircraft", ["aircraft_id PK", "tail_number UQ", "model", "capacity", "airline_id FK"])
box(1320, 70, 300, 220, "Flights", ["flight_id PK", "flight_number UQ", "airline_id FK",
                                    "departure_airport_id FK", "arrival_airport_id FK", "sched times"])
box(1740, 70, 300, 200, "Passengers", ["passenger_id PK", "first/last name", "passport UQ", "email UQ"])
# row 2: operations core
box(60, 420, 330, 260, "Flight_Instances", ["instance_id PK", "flight_id FK", "sched dep/arr",
                                            "actual dep/arr", "status", "aircraft/gate/runway FK"])
box(500, 420, 300, 240, "Terminals", ["terminal_id PK", "airport_id FK", "terminal_code UQ"])
box(910, 420, 300, 240, "Gates", ["gate_id PK", "terminal_id FK", "gate_number UQ"])
box(1320, 420, 300, 220, "Runways", ["runway_id PK", "airport_id FK", "runway_code UQ"])
box(1730, 420, 320, 280, "Bookings", ["booking_id PK", "passenger_id FK", "instance_id FK",
                                      "seat_number", "class", "price", "UQ(instance, seat)"])
# row 3: dependents + staff
box(60, 800, 330, 200, "Baggage [WEAK]", ["booking_id PK,FK", "baggage_seq PK", "weight_kg"], weak=True)
box(500, 800, 300, 200, "Payments", ["payment_id PK", "booking_id UQ,FK", "amount", "status", "txn_ref UQ"])
box(910, 800, 300, 180, "Check_Ins", ["checkin_id PK", "booking_id UQ,FK", "boarding_status"])
box(1320, 800, 300, 220, "Employees", ["employee_id PK", "full_name", "email UQ", "base_airport FK"])
box(1730, 800, 320, 200, "Pilots / Crew / Ground", ["employee_id PK,FK (each)", "licence UQ / role"])
box(910, 1100, 380, 160, "Crew_Assignments", ["assignment_id PK", "employee_id FK", "instance_id FK",
                                             "role_on_flight", "UQ(employee, instance)"])

link(360, 180, 480, 180, "based in")
link(780, 180, 900, 180, "1-N")
link(1200, 180, 1320, 180, "operates")
link(1470, 290, 225, 420, "1-N dated departures")
link(210, 290, 210, 420, "1-N")
link(650, 290, 650, 420, "1-N")
link(1060, 290, 1060, 420, "1-N")
link(1470, 290, 1470, 420, "1-N")
link(1900, 270, 1900, 420, "1-N books")
link(390, 550, 500, 550, "assigned")
link(1890, 700, 225, 800, "1-N bags (identifying)")
link(1890, 700, 650, 800, "1-1")
link(1890, 700, 1060, 800, "1-1")
link(1470, 910, 1730, 900, "is-a")
link(1730, 910, 1100, 1100, "duties")
link(225, 680, 1000, 1100, "crews")

img.save("dbms/docs/design/ER_Diagram.png")
print("erd written")

