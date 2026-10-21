"""SUPERSEDED by build_chen.py â€” kept as history. Do not run: its output path
collides with the canonical SkyRoute_ER.drawio. If ever revived, retarget
the save below to SkyRoute_ER_layered.drawio first.
Legacy builder: layered-boxes ER diagram (draw.io)."""
import xml.etree.ElementTree as ET

cells, nid = [], 2


def vertex(x, y, w, h, label):
    global nid
    c = ET.Element("mxCell", {"id": str(nid), "value": label, "vertex": "1", "parent": "1",
                              "style": "rounded=0;whiteSpace=wrap;html=1;fillColor=#ffffff;"
                                       "strokeColor=#0f2540;strokeWidth=2;fontSize=13"})
    ET.SubElement(c, "mxGeometry", {"x": str(x), "y": str(y), "width": str(w),
                                    "height": str(h), "as": "geometry"})
    cells.append(c)
    nid += 1
    return str(nid - 1)


def edge(src, tgt, label, ex, ey, nx, ny):
    global nid
    c = ET.Element("mxCell", {"id": str(nid), "value": label, "edge": "1",
                              "parent": "1", "source": src, "target": tgt,
                              "style": "endArrow=classic;html=1;strokeWidth=2;fontSize=12;"
                                       f"exitX={ex};exitY={ey};entryX={nx};entryY={ny};"})
    ET.SubElement(c, "mxGeometry", {"relative": "1", "as": "geometry"})
    cells.append(c)
    nid += 1


def entity(title, attrs, weak=False):
    head = (f'<div style="background:#0f2540;color:#ffffff;padding:4px">'
            f'<b>{title}{" [WEAK]" if weak else ""}</b></div>')
    rows = "<br>".join(f'<div style="text-align:left">{a}</div>' for a in attrs)
    return head + rows, 44 + 20 * len(attrs)


ENTS = {
    "Airports": (40, 60, ["* airport_id PK", "# iata_code UQ", "# airport_name UQ", "- city", "- country"]),
    "Airlines": (340, 60, ["* airline_id PK", "# airline_name UQ", "# iata_code UQ"]),
    "Aircraft": (640, 60, ["* aircraft_id PK", "# tail_number UQ", "- model", "- capacity", "# airline_id FK"]),
    "Flights": (940, 60, ["* flight_id PK", "# flight_number UQ", "# airline_id FK",
                          "# departure_airport_id FK", "# arrival_airport_id FK"]),
    "Passengers": (1240, 60, ["* passenger_id PK", "- first / last name", "# passport UQ", "# email UQ"]),
    "Terminals": (40, 430, ["* terminal_id PK", "# airport_id FK", "# terminal_code UQ"]),
    "Gates": (340, 430, ["* gate_id PK", "# terminal_id FK", "# gate_number UQ"]),
    "Departures": (640, 430, ["* departure_id PK", "# flight_id FK", "- scheduled dep / arr",
                             "- actual dep / arr", "- status", "# aircraft_id / gate_id FK"]),
    "Bookings": (1000, 430, ["* booking_id PK", "# passenger_id FK", "# departure_id FK",
                             "- seat_number", "- class / price", "# UQ(departure, seat)"]),
    "Baggage": (120, 800, ["# booking_id PK,FK", "* baggage_seq PK", "- weight_kg"]),
    "Payments": (450, 800, ["* payment_id PK", "# booking_id UQ,FK", "- amount / status", "# txn_ref UQ"]),
    "Check_Ins": (770, 800, ["* checkin_id PK", "# booking_id UQ,FK", "- boarding_status"]),
    "Employees": (1090, 800, ["* employee_id PK", "- full_name", "# email UQ", "# base_airport FK"]),
    "Pilots": (450, 1060, ["# employee_id PK,FK", "# licence UQ"]),
    "Crew_Members": (770, 1060, ["# employee_id PK,FK", "- crew_role"]),
    "Ground_Staff": (1090, 1060, ["# employee_id PK,FK", "- ground_role"]),
}
W = 280
ids = {}
for name, (x, y, attrs) in ENTS.items():
    label, h = entity(name, attrs, weak=(name == "Baggage"))
    ids[name] = vertex(x, y, W, h, label)

E = [("Airlines", "Aircraft", "fleet 1-N", 1, .5, 0, .5),
     ("Airports", "Terminals", "has 1-N", .5, 1, .5, 0),
     ("Terminals", "Gates", "has 1-N", 1, .5, 0, .5),
     ("Aircraft", "Departures", "assigned", .5, 1, .35, 0),
     ("Flights", "Departures", "dated 1-N", .35, 1, .6, 0),
     ("Gates", "Departures", "assigned", 1, .5, .75, 0),
     ("Passengers", "Bookings", "books 1-N", .3, 1, .8, 0),
     ("Departures", "Bookings", "holds 1-N", .8, 1, .3, 0),
     ("Bookings", "Baggage", "bags 1-N identifying", .2, 1, .8, 0),
     ("Bookings", "Payments", "pays 1-1", .45, 1, .5, 0),
     ("Bookings", "Check_Ins", "boards 1-1", .7, 1, .5, 0),
     ("Employees", "Pilots", "is-a", .35, 1, .5, 0),
     ("Employees", "Crew_Members", "is-a", .55, 1, .5, 0),
     ("Employees", "Ground_Staff", "is-a", .8, 1, .5, 0),
     ("Airlines", "Flights", "operates 1-N", .5, 1, .5, 0),
     ("Airports", "Flights", "dep / arr", .85, 0, .5, 0)]
for s, t, lab, ex, ey, nx, ny in E:
    edge(ids[s], ids[t], lab, ex, ey, nx, ny)

mxfile = ET.Element("mxfile", {"host": "SkyRoute"})
diagram = ET.SubElement(mxfile, "diagram", {"name": "ER"})
model = ET.SubElement(diagram, "mxGraphModel",
                      {"dx": "1200", "dy": "800", "grid": "1", "page": "1",
                       "pageWidth": "1600", "pageHeight": "1240"})
root = ET.SubElement(model, "root")
ET.SubElement(root, "mxCell", {"id": "0"})
ET.SubElement(root, "mxCell", {"id": "1", "parent": "0"})
for c in cells:
    root.append(c)

ET.indent(mxfile)
with open("dbms/docs/design/SkyRoute_ER_layered.drawio", "w", encoding="utf-8") as f:
    f.write('<?xml version="1.0" encoding="UTF-8"?>\n' + ET.tostring(mxfile, encoding="unicode"))
print("drawio written")

