"""Builds dbms/docs/SkyRoute_Slides.pptx (11 slides, themed).
Run from repo root:  python dbms/docs/build_slides.py"""
from pptx import Presentation
from pptx.dml.color import RGBColor
from pptx.util import Pt

NAVY, AMBER, INK, MUT, PAPER = (
    RGBColor(0x0F, 0x25, 0x40), RGBColor(0xF5, 0xA6, 0x23),
    RGBColor(0x22, 0x22, 0x22), RGBColor(0x5B, 0x6B, 0x7F),
    RGBColor(0xF6, 0xF8, 0xFB))

prs = Presentation()
prs.slide_width, prs.slide_height = Pt(960), Pt(540)
blank = prs.slide_layouts[6]


def band(s, title, kicker="SKYROUTE"):
    bar = s.shapes.add_shape(1, Pt(0), Pt(0), Pt(960), Pt(130))
    bar.fill.solid()
    bar.fill.fore_color.rgb = NAVY
    bar.line.fill.background()
    tx = s.shapes.add_textbox(Pt(48), Pt(22), Pt(864), Pt(30)).text_frame
    tx.word_wrap = True
    r = tx.paragraphs[0].add_run()
    r.text = kicker
    r.font.size, r.font.color.rgb, r.font.bold = Pt(13), AMBER, True
    tx2 = s.shapes.add_textbox(Pt(48), Pt(48), Pt(864), Pt(70)).text_frame
    tx2.word_wrap = True
    r = tx2.paragraphs[0].add_run()
    r.text = title
    r.font.size, r.font.color.rgb, r.font.bold = Pt(30), RGBColor(255, 255, 255), True
    foot = s.shapes.add_textbox(Pt(48), Pt(500), Pt(864), Pt(24)).text_frame
    foot.word_wrap = True
    r = foot.paragraphs[0].add_run()
    r.text = "SkyRoute  ·  DBMS mini project  ·  skyroute_db (MySQL 8.0)"
    r.font.size, r.font.color.rgb = Pt(11), MUT


def body(s, points, top=150, size=19, gap=10):
    tf = s.shapes.add_textbox(Pt(48), Pt(top), Pt(864), Pt(330)).text_frame
    tf.word_wrap = True
    for i, (lead, rest) in enumerate(points):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.space_after = Pt(gap)
        r = p.add_run()
        r.text = "▸ " + lead + ("  " if rest else "")
        r.font.size, r.font.bold = Pt(size), True
        r.font.color.rgb = NAVY
        if rest:
            r2 = p.add_run()
            r2.text = rest
            r2.font.size = Pt(size)
            r2.font.color.rgb = INK
    return tf


def cover():
    s = prs.slides.add_slide(blank)
    bg = s.shapes.add_shape(1, Pt(0), Pt(0), Pt(960), Pt(540))
    bg.fill.solid()
    bg.fill.fore_color.rgb = NAVY
    bg.line.fill.background()
    tx = s.shapes.add_textbox(Pt(60), Pt(120), Pt(840), Pt(300)).text_frame
    tx.word_wrap = True
    for txt, sz, col, bold in [
            ("SKYROUTE  ✈", 20, AMBER, True),
            ("Airline Ticket & Baggage System", 44, RGBColor(255, 255, 255), True),
            ("Multi-airport database · 16 tables · 336 departures · ~34,000 bookings",
             20, RGBColor(207, 227, 247), False),
            ("Views · trigger · procedure · transactions · indexes · Flask booking site",
             20, RGBColor(207, 227, 247), False)]:
        p = tx.add_paragraph() if tx.paragraphs[0].text else tx.paragraphs[0]
        r = p.add_run()
        r.text = txt
        r.font.size, r.font.color.rgb, r.font.bold = Pt(sz), col, bold
        p.space_after = Pt(10)


def table_slide(title, headers, rows):
    s = prs.slides.add_slide(blank)
    band(s, title)
    tbl = s.shapes.add_table(len(rows) + 1, len(headers),
                             Pt(48), Pt(150), Pt(864), Pt(320)).table
    widths = [Pt(200), Pt(180), Pt(484)]
    for j, w in enumerate(widths):
        tbl.columns[j].width = w
    for j, hd in enumerate(headers):
        c = tbl.cell(0, j)
        c.text = hd
        for p in c.text_frame.paragraphs:
            for r in p.runs:
                r.font.size, r.font.bold = Pt(15), True
                r.font.color.rgb = RGBColor(255, 255, 255)
        c.fill.solid()
        c.fill.fore_color.rgb = NAVY
    for i, row in enumerate(rows):
        for j, val in enumerate(row):
            c = tbl.cell(i + 1, j)
            c.text = val
            for p in c.text_frame.paragraphs:
                for r in p.runs:
                    r.font.size = Pt(14)
                    r.font.color.rgb = INK
            if i % 2 == 1:
                c.fill.solid()
                c.fill.fore_color.rgb = PAPER


cover()

s = prs.slides.add_slide(blank)
band(s, "The problem: five failures, five mechanisms")
body(s, [("Double seat booking", "UNIQUE(departure, seat) refuses it in storage."),
         ("Gate clash", "UNIQUE(terminal, gate) — one gate, one row."),
         ("Wrong baggage fee", "one fee rule in booking_receipt_view: 20 kg free, Rs 500/kg."),
         ("No shared database", "one skyroute_db for all five airports."),
         ("Overselling", "trigger refuses sales past aircraft capacity.")])

s = prs.slides.add_slide(blank)
band(s, "ER model: timetable vs dated reality")
body(s, [("Masters", "Airport, Airline, Aircraft, Terminal, Gate."),
         ("Flight → Departures", "timetable template owns unlimited dated departures."),
         ("Booking bridge", "passengers meet departures; bags hang off bookings (weak)."),
         ("Staff", "Employee supertype + Pilot / Crew / Ground subtypes.")])

table_slide("Schema: 16 tables, every key earns its place",
            ["Table", "Primary key", "Rule that matters"],
            [["Flights", "flight_id", "UNIQUE number · dep ≠ arr airports"],
             ["Departures", "departure_id", "UNIQUE(flight, date-time)"],
             ["Bookings", "booking_id", "UNIQUE(departure, seat)"],
             ["Baggage", "(booking, seq)", "weak entity · 0 < kg ≤ 100"],
             ["Gates", "gate_id", "UNIQUE(terminal, gate)"],
             ["Payments / Check-Ins", "own ids", "UNIQUE booking (one-to-one)"]])

s = prs.slides.add_slide(blank)
band(s, "Scale: designed unlimited, demonstrated at volume")
body(s, [("Design", "integer keys + indexed FKs — nothing changes at 10× volume."),
         ("Generator", "deterministic (seed 42): 14 days, 35–80% load factors."),
         ("Verified", "zero duplicate seats · all foreign keys in range."),
         ("Payoff", "load factor, revenue, gate use — one query each.")])

s = prs.slides.add_slide(blank)
band(s, "Advanced SQL: rules live in the database")
body(s, [("flight_board_view", "the whole departure board in one query."),
         ("booking_receipt_view", "price + computed baggage fee per booking."),
         ("trg_booking_capacity", "BEFORE INSERT trigger: full flight? refused (SQLSTATE 45000)."),
         ("MakeBooking", "seat + payment in one transaction — both or neither.")])

s = prs.slides.add_slide(blank)
band(s, "Transactions: ACID you can watch")
body(s, [("Demo A — commit", "booking + payment appear together."),
         ("Demo B — rollback", "failed payment → seat provably still free."),
         ("Demo C — isolation", "two sessions: old value visible until COMMIT.")])

s = prs.slides.add_slide(blank)
band(s, "Indexing: measure, don't guess")
body(s, [("No cargo cult", "InnoDB already indexes FK columns — untouched."),
         ("4 workload indexes", "status · departure date · surname · bag weight."),
         ("Proof", "before/after EXPLAIN pairs: fewer rows examined.")])

s = prs.slides.add_slide(blank)
band(s, "Access control + testing")
body(s, [("3 roles", "admin = all · staff = read-write · viewer = read-only, SHOW GRANTS proof."),
         ("30 checks", "joins · analytics · rejections (ERROR 1062 live) · atomicity · grants · scale."),
         ("Every check", "states its expected result before the run.")])

s = prs.slides.add_slide(blank)
band(s, "Flask booking site: the database, clickable")
body(s, [("3 steps", "Search → seat map → My bookings (http://127.0.0.1:5000)."),
         ("Seat map", "grey seats are the UNIQUE key made visible."),
         ("CRUD + fee", "edit · cancel · delete · 25 kg bag = Rs 2,500 fee."),
         ("13 tests", "all passing, no server needed: test_app.py.")])

s = prs.slides.add_slide(blank)
band(s, "Result: every problem closed, everything tested")
body(s, [("Coverage", "all 5 problem items → named mechanisms → tests."),
         ("Volume", "~14k bookings answered in single queries."),
         ("Next", "live demo: board → book 12A → re-book 12A (refused) → fee receipt.")])

prs.save("dbms/docs/SkyRoute_Slides.pptx")
print("slides written")
