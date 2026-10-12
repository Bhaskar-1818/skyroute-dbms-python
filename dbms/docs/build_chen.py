"""Chen ER v2 — vertical journey-flow layout (deliberately unlike the friend's
landscape scatter): 4 top-to-bottom lanes (places / flights / travelers /
staff band), attributes stacked above+below each box, diamonds inline on the
wires, cross-lane links on side channels. Plain B/W Chen, schema-case entity
names matching CREATE TABLE, lowercase verb diamonds, italic cardinality
cells. No ISA: role tables are plain entities with 1-1 diamonds.
Emits dbms/docs/SkyRoute_ER.drawio + dbms/docs/ER_Diagram.png.
Run from repo root:  python dbms/docs/build_chen.py"""
import xml.etree.ElementTree as ET
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent
F_TITLE = ImageFont.load_default(size=26)
F_ENT = ImageFont.load_default(size=18)
F_ATTR = ImageFont.load_default(size=14)
F_DIAM = ImageFont.load_default(size=12)
F_CARD = ImageFont.load_default(size=14)

EW, EH = 220, 60      # entity box
OW, OH = 290, 46      # attribute oval
DW, DH = 160, 88      # relationship diamond
AY0, PITCH = 150, 62  # vertical stacks: first offset, row pitch

# Lanes (entity centre x): places=800, flights=2500, travelers=4200.
# Staff band y=6500: Pilots=700, Employees=2100, Ground_Staff=3500, Crew=4900.
ENTS = {
 "Airports":     (800, 900,  [("airport_id", "PK"), ("iata_code", ""), ("airport_name", ""), ("city", ""), ("country", "")]),
 "Airlines":     (2500, 900, [("airline_id", "PK"), ("airline_name", ""), ("iata_code", ""), ("country", "")]),
 "Passengers":   (4200, 900, [("passenger_id", "PK"), ("first_name", ""), ("last_name", ""), ("passport_number", ""), ("nationality", ""), ("phone", ""), ("email", "")]),
 "Terminals":    (800, 2300, [("terminal_id", "PK"), ("airport_id", "FK"), ("terminal_code", ""), ("terminal_name", ""), ("terminal_status", "")]),
 "Aircraft":     (2500, 2300, [("aircraft_id", "PK"), ("tail_number", ""), ("model", ""), ("capacity", ""), ("airline_id", "FK")]),
 "Bookings":     (4200, 2300, [("booking_id", "PK"), ("passenger_id", "FK"), ("departure_id", "FK"), ("seat_number", ""), ("travel_class", ""), ("price", ""), ("booking_status", ""), ("booked_at", "")]),
 "Gates":        (800, 3700, [("gate_id", "PK"), ("terminal_id", "FK"), ("gate_number", ""), ("gate_status", "")]),
 "Flights":      (2500, 3700, [("flight_id", "PK"), ("flight_number", ""), ("airline_id", "FK"), ("departure_airport_id", "FK"), ("arrival_airport_id", "FK"), ("sched_departure", ""), ("sched_arrival", ""), ("flight_status", "")]),
 "Payments":     (3600, 3700, [("payment_id", "PK"), ("booking_id", "FK"), ("amount", ""), ("pay_method", ""), ("pay_status", ""), ("txn_reference", ""), ("paid_at", "")]),
 "Check_Ins":    (4800, 3700, [("checkin_id", "PK"), ("booking_id", "FK"), ("checkin_time", ""), ("boarding_status", "")]),
 "Baggage":      (4200, 4900, [("booking_id", "PK"), ("baggage_seq", "PK"), ("weight_kg", "")]),
 "Departures":   (2500, 5100, [("departure_id", "PK"), ("flight_id", "FK"), ("scheduled_departure", ""), ("scheduled_arrival", ""), ("actual_departure", ""), ("actual_arrival", ""), ("departure_status", ""), ("aircraft_id", "FK"), ("gate_id", "FK")]),
 "Pilots":       (700, 6500, [("employee_id", "PK"), ("license_number", ""), ("license_type", "")]),
 "Employees":    (2100, 6500, [("employee_id", "PK"), ("full_name", ""), ("email", ""), ("phone", ""), ("base_airport", "FK"), ("hire_date", "")]),
 "Ground_Staff": (3500, 6500, [("employee_id", "PK"), ("ground_role", ""), ("airport_id", "FK")]),
 "Crew_Members": (4900, 6500, [("employee_id", "PK"), ("crew_role", "")]),
}
WEAK = {"Baggage"}

W, H = 5400, 7500


def zigzag(cx, cy, attrs):
    # vertical stacks: even index above the box, odd index below
    pts = []
    for i, a in enumerate(attrs):
        k = i // 2
        y = cy - AY0 - k * PITCH if i % 2 == 0 else cy + AY0 + k * PITCH
        pts.append((cx, y, a))
    return pts


ATTR_POS = {name: zigzag(cx, cy, attrs) for name, (cx, cy, attrs) in ENTS.items()}

# d=(name, x, y, identifying); legs=[(entity, [(x,y),...])]; cards=[(text,x,y)]
WIRE = [
 dict(d=("has_terminal", 1020, 1600, False),
      legs=[("Airports", [(900, 930), (1020, 930), (1020, 1556)]),
            ("Terminals", [(900, 2270), (1020, 2270), (1020, 1644)])],
      cards=[("1", 1065, 1250), ("N", 1065, 1950)]),
 dict(d=("contains_gate", 1020, 3000, False),
      legs=[("Terminals", [(900, 2330), (1020, 2330), (1020, 2956)]),
            ("Gates", [(900, 3670), (1020, 3670), (1020, 3044)])],
      cards=[("1", 1065, 2650), ("N", 1065, 3350)]),
 dict(d=("has_fleet", 2720, 1600, False),
      legs=[("Airlines", [(2610, 930), (2720, 930), (2720, 1556)]),
            ("Aircraft", [(2610, 2270), (2720, 2270), (2720, 1644)])],
      cards=[("1", 2765, 1250), ("N", 2765, 1950)]),
 dict(d=("scheduled_as", 2720, 4400, False),
      legs=[("Flights", [(2610, 3730), (2720, 3730), (2720, 4356)]),
            ("Departures", [(2610, 5070), (2720, 5070), (2720, 4444)])],
      cards=[("1", 2765, 4050), ("N", 2765, 4750)]),
 dict(d=("makes_booking", 4420, 1600, False),
      legs=[("Passengers", [(4310, 930), (4420, 930), (4420, 1556)]),
            ("Bookings", [(4310, 2270), (4420, 2270), (4420, 1644)])],
      cards=[("1", 4465, 1250), ("N", 4465, 1950)]),
 dict(d=("has_baggage", 4420, 3600, True),
      legs=[("Bookings", [(4310, 2330), (4420, 2330), (4420, 3556)]),
            ("Baggage", [(4310, 4870), (4420, 4870), (4420, 3644)])],
      cards=[("1", 4465, 2950), ("N", 4465, 4250)]),
 dict(d=("operates", 2900, 1800, False),
      legs=[("Airlines", [(2610, 900), (2900, 900), (2900, 1756)]),
            ("Flights", [(2610, 3700), (2900, 3700), (2900, 1844)])],
      cards=[("1", 2945, 1300), ("N", 2945, 3000)]),
 dict(d=("aircraft_assigned", 3100, 3700, False),
      legs=[("Aircraft", [(2610, 2300), (3100, 2300), (3100, 3656)]),
            ("Departures", [(2610, 5100), (3100, 5100), (3100, 3744)])],
      cards=[("1", 3145, 2900), ("0..N", 3145, 4450)]),
 dict(d=("holds", 5050, 3700, False),
      legs=[("Bookings", [(4310, 2300), (5050, 2300), (5050, 3656)]),
            ("Departures", [(2610, 5100), (5050, 5100), (5050, 3744)])],
      cards=[("1", 5195, 2900), ("N", 5195, 4500)]),
 dict(d=("departs_from", 400, 2000, False),
      legs=[("Airports", [(690, 900), (400, 900), (400, 1956)]),
            ("Flights", [(2390, 3700), (400, 3700), (400, 2044)])],
      cards=[("1", 445, 1350), ("N", 445, 2950)]),
 dict(d=("arrives_at", 550, 2600, False),
      legs=[("Airports", [(690, 920), (550, 920), (550, 2556)]),
            ("Flights", [(2390, 3720), (550, 3720), (550, 2644)])],
      cards=[("1", 595, 1500), ("N", 595, 3250)]),
 dict(d=("gate_assigned", 1650, 5600, False),
      legs=[("Gates", [(900, 3730), (1000, 3730), (1000, 5600), (1570, 5600)]),
            ("Departures", [(2610, 5100), (2700, 5100), (2700, 5600), (1730, 5600)])],
      cards=[("1", 1200, 5562), ("0..N", 2300, 5562)]),
 dict(d=("based_at", 150, 3700, False),
      legs=[("Airports", [(690, 880), (150, 880), (150, 3656)]),
            ("Employees", [(1990, 6500), (1900, 6500), (1900, 6560), (150, 6560), (150, 3744)])],
      cards=[("1", 195, 1500), ("0..N", 195, 5500)]),
 dict(d=("posted_at", 1100, 4500, False),
      legs=[("Airports", [(910, 920), (1100, 920), (1100, 4456)]),
            ("Ground_Staff", [(3390, 6500), (3300, 6500), (3300, 6560), (1100, 6560), (1100, 4544)])],
      cards=[("1", 1145, 1500), ("0..N", 1145, 5950)]),
 dict(d=("has_payment", 3400, 3000, False),
      legs=[("Bookings", [(4090, 2300), (3400, 2300), (3400, 2956)]),
            ("Payments", [(3490, 3670), (3400, 3670), (3400, 3044)])],
      cards=[("1", 3445, 2650), ("1", 3445, 3350)]),
 dict(d=("has_checkin", 4800, 3000, False),
      legs=[("Bookings", [(4310, 2300), (4800, 2300), (4800, 2956)]),
            ("Check_Ins", [(4690, 3670), (4600, 3670), (4600, 3000), (4720, 3000)])],
      cards=[("1", 4845, 2650), ("0..1", 4645, 3350)]),
 dict(d=("has_pilot", 1400, 6500, False),
      legs=[("Pilots", [(810, 6500), (1320, 6500)]),
            ("Employees", [(1990, 6500), (1480, 6500)])],
      cards=[("1", 1050, 6462), ("1", 1750, 6462)]),
 dict(d=("has_ground", 2800, 6500, False),
      legs=[("Employees", [(2210, 6500), (2720, 6500)]),
            ("Ground_Staff", [(3390, 6500), (2880, 6500)])],
      cards=[("1", 2450, 6462), ("1", 3150, 6462)]),
 dict(d=("has_crew", 4200, 6500, False),
      legs=[("Ground_Staff", [(3610, 6500), (4120, 6500)]),
            ("Crew_Members", [(4790, 6500), (4280, 6500)])],
      cards=[("1", 3850, 6462), ("1", 4600, 6462)]),
]

TITLE = "Fig. 1 \u2014 SkyRoute ER Diagram (Chen notation)"
SUBTITLE = "16 entity sets \u00b7 19 relationships \u00b7 Baggage weak \u00b7 keys underlined"

# ---------------- draw.io ----------------
cells, nid = [], 2
ids = {}


def _mk(tag, attrs, kids=()):
    global nid
    c = ET.Element(tag, {"id": str(nid), **attrs})
    for g in kids:
        c.append(g)
    cells.append(c)
    nid += 1
    return str(nid - 1)


def vertex(x, y, w, h, label, style):
    return _mk("mxCell", {"value": label, "vertex": "1", "parent": "1", "style": style},
               [ET.Element("mxGeometry", {"x": str(x), "y": str(y),
                                          "width": str(w), "height": str(h), "as": "geometry"})])


def oedge(src, tgt, pts, w=1.4):
    g = ET.Element("mxGeometry", {"relative": "1", "as": "geometry"})
    if pts:
        arr = ET.SubElement(g, "Array", {"as": "points"})
        for x, y in pts:
            ET.SubElement(arr, "mxPoint", {"x": str(x), "y": str(y)})
    return _mk("mxCell",
               {"value": "", "edge": "1", "parent": "1", "source": src, "target": tgt,
                "style": ("edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;"
                          "html=1;endArrow=none;startArrow=none;strokeColor=#000000;"
                          f"strokeWidth={w};")}, [g])


def sedge(src, tgt):
    return _mk("mxCell",
               {"value": "", "edge": "1", "parent": "1", "source": src, "target": tgt,
                "style": ("edgeStyle=none;html=1;endArrow=none;startArrow=none;"
                          "strokeColor=#000000;strokeWidth=1;")},
               [ET.Element("mxGeometry", {"relative": "1", "as": "geometry"})])


ENT_ST = ("rounded=0;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#000000;"
          "strokeWidth=2;fontColor=#000000;fontSize=14;align=center;verticalAlign=middle;")
ATTR_ST = ("ellipse;whiteSpace=wrap;html=1;fillColor=none;strokeColor=#000000;"
           "strokeWidth=1.2;fontColor=#000000;fontSize=11;align=center;verticalAlign=middle;")
DIAM_ST = ("shape=rhombus;perimeter=rhombusPerimeter;whiteSpace=wrap;html=1;fillColor=none;"
           "strokeColor=#000000;strokeWidth=1.5;fontColor=#000000;fontSize=10;"
           "align=center;verticalAlign=middle;")
CARD_ST = ("text;html=1;align=center;verticalAlign=middle;fontStyle=1;fontSize=12;fontColor=#000000;")
vertex(W / 2 - 2500, 60, 5000, 80, "&lt;b&gt;" + TITLE + "&lt;/b&gt;",
       "text;html=1;align=center;verticalAlign=middle;fontSize=26;whiteSpace=wrap;fontColor=#000000;")
vertex(W / 2 - 2500, 140, 5000, 40, SUBTITLE,
       "text;html=1;align=center;verticalAlign=middle;fontSize=15;whiteSpace=wrap;fontColor=#000000;")
for name, (cx, cy, attrs) in ENTS.items():
    ids[name] = vertex(cx - EW / 2, cy - EH / 2, EW, EH, f"&lt;b&gt;{name}&lt;/b&gt;", ENT_ST)
    if name in WEAK:
        vertex(cx - EW / 2 - 9, cy - EH / 2 - 9, EW + 18, EH + 18, "", ENT_ST)
for name, (cx, cy, attrs) in ENTS.items():
    for ax, ay, (col, tag) in ATTR_POS[name]:
        lab = f"&lt;u&gt;{col}&lt;/u&gt;" if tag == "PK" else (col + " (FK)" if tag == "FK" else col)
        aid = vertex(ax - OW / 2, ay - OH / 2, OW, OH, lab, ATTR_ST)
        sedge(ids[name], aid)
dids = {}
for wdef in WIRE:
    dname, dx, dy, ident = wdef["d"]
    did = vertex(dx - DW / 2, dy - DH / 2, DW, DH, f"&lt;b&gt;{dname}&lt;/b&gt;", DIAM_ST)
    dids[dname] = did
    if ident:
        vertex(dx - DW / 2 - 10, dy - DH / 2 - 10, DW + 20, DH + 20, "", DIAM_ST)
for wdef in WIRE:
    dname = wdef["d"][0]
    for ent, pts in wdef["legs"]:
        oedge(ids[ent], dids[dname], pts)
    for text, cx, cy in wdef["cards"]:
        vertex(cx - 20, cy - 15, 40, 30, text, CARD_ST)

LEG_ST = ("text;html=1;align=left;verticalAlign=middle;fontSize=12;fontColor=#000000;")
vertex(100, 6900, 600, 400, "", ENT_ST)
vertex(120, 6912, 560, 30, "&lt;b&gt;Notation&lt;/b&gt;", LEG_ST)
LEG_ROWS = [
 ("rect", 6975, "entity set (16)"),
 ("oval", 7020, "attribute — underline = key"),
 ("diamond", 7065, "relationship"),
 ("double_rect", 7110, "weak entity (Baggage)"),
 ("cards", 7155, "cardinality: 1 / N / 0..N"),
 ("double_diamond", 7200, "identifying relationship"),
]
for kind, y, label in LEG_ROWS:
    if kind == "rect":
        vertex(180, y - 17, 100, 34, "", ENT_ST)
    elif kind == "oval":
        vertex(180, y - 17, 100, 34, "", ATTR_ST)
    elif kind == "diamond":
        vertex(180, y - 22, 100, 44, "", DIAM_ST)
    elif kind == "double_rect":
        vertex(180, y - 17, 100, 34, "", ENT_ST)
        vertex(188, y - 11, 84, 22, "", ENT_ST)
    elif kind == "cards":
        vertex(180, y - 15, 100, 30, "&lt;b&gt;1 / N&lt;/b&gt;", CARD_ST)
    elif kind == "double_diamond":
        vertex(180, y - 22, 100, 44, "", DIAM_ST)
        vertex(192, y - 14, 76, 28, "", DIAM_ST)
    vertex(300, y - 15, 430, 30, label, LEG_ST)

mxfile = ET.Element("mxfile", {"host": "app.diagrams.net", "agent": "opencode"})
diagram = ET.SubElement(mxfile, "diagram", {"id": "skyroute-chen", "name": "SkyRoute Chen ER"})
model = ET.SubElement(diagram, "mxGraphModel",
                      {"grid": "1", "page": "1", "gridSize": "10", "guides": "1",
                       "tooltips": "1", "connect": "1", "arrows": "1", "fold": "1",
                       "pageScale": "1", "pageWidth": str(W), "pageHeight": str(H),
                       "math": "0", "shadow": "0"})
root = ET.SubElement(model, "root")
ET.SubElement(root, "mxCell", {"id": "0"})
ET.SubElement(root, "mxCell", {"id": "1", "parent": "0"})
for c in cells:
    root.append(c)
ET.indent(mxfile)
with open(OUT / "SkyRoute_ER.drawio", "w", encoding="utf-8") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(mxfile, encoding="unicode"))
print("drawio written")

# ---------------- PNG mirror ----------------
img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)
BLK = (0, 0, 0)


def ctext(x, y, s, font=F_ATTR):
    bb = d.textbbox((x, y), s, font=font, anchor="mm")
    d.rectangle([bb[0] - 6, bb[1] - 3, bb[2] + 6, bb[3] + 3], fill="white")
    d.text((x, y), s, font=font, fill="black", anchor="mm")


d.text((W / 2, 110), TITLE, font=F_TITLE, fill="black", anchor="mm")
d.text((W / 2, 150), SUBTITLE, font=F_ATTR, fill="black", anchor="mm")
for name, (cx, cy, attrs) in ENTS.items():
    d.rectangle([cx - EW / 2, cy - EH / 2, cx + EW / 2, cy + EH / 2], outline=BLK, width=3)
    if name in WEAK:
        d.rectangle([cx - EW / 2 - 9, cy - EH / 2 - 9, cx + EW / 2 + 9, cy + EH / 2 + 9],
                    outline=BLK, width=2)
    d.text((cx, cy), name, font=F_ENT, fill="black", anchor="mm")
    for ax, ay, (col, tag) in ATTR_POS[name]:
        d.ellipse([ax - OW / 2, ay - OH / 2, ax + OW / 2, ay + OH / 2], outline=BLK, width=2)
        d.text((ax, ay), col + (" (FK)" if tag == "FK" else ""), font=F_ATTR, fill="black", anchor="mm")
        if tag == "PK":
            w = d.textlength(col, font=F_ATTR)
            d.line([ax - w / 2, ay + 11, ax + w / 2, ay + 11], fill=BLK, width=2)
        d.line([cx, cy, ax, ay], fill=BLK, width=1)
for wdef in WIRE:
    dname, dx, dy, ident = wdef["d"]
    d.polygon([(dx - DW / 2, dy), (dx, dy - DH / 2), (dx + DW / 2, dy), (dx, dy + DH / 2)],
              outline=BLK, width=2)
    if ident:
        m = 12
        d.polygon([(dx - DW / 2 + m, dy), (dx, dy - DH / 2 + m),
                   (dx + DW / 2 - m, dy), (dx, dy + DH / 2 - m)], outline=BLK, width=2)
    ctext(dx, dy, dname, font=F_DIAM)
    for ent, pts in wdef["legs"]:
        ex, ey = ENTS[ent][0], ENTS[ent][1]
        d.line([(ex, ey)] + pts, fill=BLK, width=2)
    for text, cx, cy in wdef["cards"]:
        ctext(cx, cy, text, font=F_CARD)

LX, LEG_W = 100, 600
d.rectangle([LX, 6900, LX + LEG_W, 7340], outline=BLK, width=2)
d.text((LX + 20, 6927), "Notation", font=F_ATTR, fill="black", anchor="lm")
for kind, y, label in LEG_ROWS:
    if kind in ("rect", "double_rect"):
        d.rectangle([180, y - 17, 280, y + 17], outline=BLK, width=2)
        if kind == "double_rect":
            d.rectangle([188, y - 11, 272, y + 11], outline=BLK, width=1)
    elif kind == "oval":
        d.ellipse([180, y - 17, 280, y + 17], outline=BLK, width=2)
    elif kind in ("diamond", "double_diamond"):
        d.polygon([(180, y), (230, y - 22), (280, y), (230, y + 22)], outline=BLK, width=2)
        if kind == "double_diamond":
            d.polygon([(192, y), (230, y - 14), (268, y), (230, y + 14)], outline=BLK, width=1)
    elif kind == "cards":
        d.text((230, y), "1 / N", font=F_ATTR, fill="black", anchor="mm")
    d.text((300, y), label, font=F_ATTR, fill="black", anchor="lm")

img.save(OUT / "ER_Diagram.png")
print("png written")

DESC = {
 "Airports": "master list of airports served.",
 "Airlines": "master list of carriers.",
 "Flights": "timetable templates, one row per flight number.",
 "Passengers": "travelers who can hold bookings.",
 "Terminals": "terminals inside airports.",
 "Aircraft": "fleet with seating capacity.",
 "Departures": "dated departures of timetable flights.",
 "Bookings": "seat reservations linking traveler and departure.",
 "Gates": "boarding gates inside terminals.",
 "Payments": "one payment record per booking.",
 "Check_Ins": "boarding record per booking.",
 "Baggage": "weak entity: bags belonging to a booking.",
 "Pilots": "licensed pilots (role table).",
 "Employees": "staff base records.",
 "Ground_Staff": "airport ground roles (role table).",
 "Crew_Members": "cabin-crew roles (role table).",
}
with open(OUT / "ER_Dictionary.md", "w", encoding="utf-8") as f:
    f.write("# SkyRoute ER dictionary (companion to Fig. 1)\n\n")
    f.write("Entity names match CREATE TABLE statements exactly.\n\n")
    for name, (cx, cy, attrs) in ENTS.items():
        keys = [c for c, t in attrs if t == "PK"]
        f.write(f"## {name} — {DESC[name]}\n")
        f.write(f"Key: {', '.join(keys)}. Columns: "
                + ", ".join(c + (" [PK]" if t == "PK" else (" [FK]" if t == "FK" else "")) for c, t in attrs) + "\n")
        rels = [w["d"][0] for w in WIRE for ent, _ in w["legs"] if ent == name]
        f.write("Relationships: " + (", ".join(rels) if rels else "—") + "\n\n")
    f.write("## Relationships\n\n")
    f.write("| Relationship | Ends (cardinality) |\n|---|---| \n")
    for wdef in WIRE:
        dname = wdef["d"][0]
        legs = " — ".join(f"{ent} ({wdef['cards'][i][0]})" for i, (ent, _) in enumerate(wdef["legs"]))
        f.write(f"| {dname} | {legs} |\n")
print("dictionary written")
