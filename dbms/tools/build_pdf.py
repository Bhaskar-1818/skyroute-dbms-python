"""Builds dbms/docs/report/SkyRoute_Report.pdf from REPORT_FINAL.md.

Styled like a standard institutional project report (Word default look):
US Letter, Calibri 11, Word-blue headings, centred cover with the IcfaiTech
logo, page numbers in the footer, no decorative colour blocks.

Run from the repo root:
    uv run --with fpdf2 python dbms/tools/build_pdf.py
"""
import re
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fpdf import FPDF  # noqa: E402
from fpdf.fonts import FontFace  # noqa: E402

from report_content import SCHEMA_TABLE, load  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]      # tools -> dbms -> repo root
DOCS = ROOT / "dbms" / "docs"
DESIGN = DOCS / "design"
SHOTS = DOCS / "evidence" / "screenshots"
REPORT_SRC = DOCS / "report" / "REPORT_FINAL.md"
OUT_PDF = DOCS / "report" / "SkyRoute_Report.pdf"
LOGO = DESIGN / "icfaitech-logo.png"

# Word's default Heading 1 colour, used by the reference report.
HEAD_BLUE = (46, 116, 181)
INK = (0, 0, 0)
GREY = (110, 110, 110)
RULE = (200, 200, 200)

STUDENT = {
    "name": "D.Sivasai Bhaskar Sarma",
    "roll": "25STUCHH010868",
    "section": "D",
    "course": "CS/AI/AIM/DS202",
    "guide": "Dr. Meena Kumari Parigi",
    "date": "",
}

FONT_DIR = Path(r"C:\Windows\Fonts")
FONT = "Calibri" if (FONT_DIR / "calibri.ttf").exists() else "Helvetica"

ROW_COUNTS = (    ("airports", "5", "IATA code, city, country"),
    ("airlines", "3", "two-letter code and name"),
    ("aircraft", "16", "tail number, model, capacity"),
    ("flights", "16", "route, times, base fare"),
    ("departures", "336", "dated flight, aircraft, gate"),
    ("terminals", "5", "one per airport"),
    ("gates", "20", "terminal and gate number"),
    ("passengers", "4,000", "passport, name, contact"),
    ("bookings", "34,708", "seat, class, price, status"),
    ("baggage", "43,314", "tag, weight, booking"),
    ("payments", "34,708", "method, amount, status"),
    ("check_ins", "11,544", "boarding time and seat"),
    ("employees", "8", "shared staff record"),
    ("pilots", "2", "licence and flight hours"),
    ("crew_members", "3", "cabin role"),
    ("ground_staff", "3", "airport and shift"),
)

APPENDIX_TESTS = (
    ("J1-J10", "Ten join queries run clean and return 10 result sets", "T1-joins.txt"),
    ("J4", "LEFT JOIN keeps bookings that have no bags", "T1-joins.txt"),
    ("J10", "Crew directory joins all three role tables", "T1-joins.txt"),
    ("A1", "Busiest route is MAA-BOM with 2,688 bookings", "T2-analytics.txt"),
    ("A2", "Every load factor falls between 35 and 80 per cent", "T2-analytics.txt"),
    ("A4", "Fee revenue is positive", "T2-analytics.txt"),
    ("C-a", "Duplicate (departure, seat) gives ERROR 1062", "T3-constraints.txt"),
    ("C-b", "Same departure and arrival airport gives ERROR 1644", "T3-constraints.txt"),
    ("C-c", "Bag of zero or negative weight is refused", "T3-constraints.txt"),
    ("C-d", "Deleting a used airport gives ERROR 1451", "T3-constraints.txt"),
    ("C-e", "Deleting a booking removes its bags, payment and check-in", "T3e-cascade.txt"),
    ("T-a", "MakeBooking returns an id and a Pending payment", "T4-procedure-trigger.txt"),
    ("T-b", "A second call on the same seat inserts nothing", "T4-procedure-trigger.txt"),
    ("T-c", "A booking past capacity gives ERROR 45000", "T4-procedure-trigger.txt"),
    ("D-A", "Commit keeps the booking and the payment", "T5-rollback.txt"),
    ("D-B", "Rollback leaves the seat free", "T5-rollback.txt"),
    ("D-C", "A second session reads the old value until commit", "T5-rollback.txt"),
    ("I-a", "EXPLAIN pairs captured before and after each index", "T6-indexes.txt"),
    ("I-b", "SHOW INDEX lists the four new indexes", "T6-indexes.txt"),
    ("R-a", "Grants match the three roles", "T7-access.txt"),
    ("R-b", "The viewer is refused an INSERT", "T7b-viewer-denied.txt"),
    ("R-c", "Grant names spell skyroute_db exactly", "T7-access.txt"),
    ("S-a", "336 departures, 34,708 bookings, 43,314 bags", "T8-scale.txt"),
    ("S-b", "The daily snapshot covers all 21 days", "T8-scale.txt"),
)
MONO = "Mono" if (FONT_DIR / "consola.ttf").exists() else "Courier"


def _ascii(t):
    """Map typographic characters to plain ASCII for the core fonts."""
    for a, b in [("\u2014", "-"), ("\u2013", "-"), ("\u2192", "->"),
                 ("\u2019", "'"), ("\u2018", "'"), ("\u201c", '"'),
                 ("\u201d", '"'), ("\u2026", "..."), ("\u2264", "<="),
                 ("\u2265", ">="), ("`", ""), ("\ufffd", "-")]:
        t = str(t).replace(a, b)
    return t


# Captions keyed by the start of the file name, so "A3-duplicate-seat.png",
# "a3.png" and "A3_screenshot.png" all pick up the same text.
CAPTIONS = {
    "a1": "Join queries J1-J10: five-table joins, LEFT JOIN and the crew directory",
    "a2": "Analytics: busiest routes, load factor and overweight baggage revenue",
    "a3": "Duplicate seat rejected by the UNIQUE constraint (ERROR 1062)",
    "a4": "MakeBooking writes the booking and its pending payment in one call",
    "a5": "Capacity trigger refuses an oversold seat (ERROR 4500)",
    "a6": "ROLLBACK discards the uncommitted passenger row",
    "a7": "Row lock blocks a competing UPDATE until the transaction ends",
    "a8": "Grants for the three roles: admin, staff and read-only viewer",
    "a9": "Row counts across the six largest tables",
    "b1": "Remaining constraints: same-airport route, zero-weight bag, RESTRICT delete",
    "b2": "ON DELETE CASCADE removes the child bag and payment rows",
    "b3": "A second MakeBooking call for the same seat is refused",
    "b4": "EXPLAIN before the index is dropped",
    "b5": "EXPLAIN after the index is re-created",
    "b6": "Viewer account denied INSERT (ERROR 1142)",
    "b7": "REVOKE removes write access and GRANT restores it",
    "b8": "COMMIT keeps the new booking and payment",
    "t1": "Join queries across the schema",
    "t2": "Aggregate analytics with HAVING filters",
    "t3": "Constraint violations",
    "t4": "Stored procedure and capacity trigger",
    "t5": "Transaction rollback",
    "t6": "Index before and after",
    "t7": "Role-based access control",
    "t8": "Table row counts",
}


def _natural(name):
    """Sort key that puts 2 before 10, and numbers ahead of words."""
    return [(0, int(p)) if p.isdigit() else (1, p.lower())
            for p in re.split(r"(\d+)", name)]


def _caption_for(stem):
    key = re.sub(r"[^a-z0-9]", "", stem.lower())
    best = None
    for k in CAPTIONS:
        if key.startswith(k) and (best is None or len(k) > len(best)):
            best = k
    if best:
        return CAPTIONS[best]
    return re.sub(r"[_-]+", " ", stem).strip().capitalize()


def load_captions():
    """Optional captions.txt beside the images: one 'file.png | caption' per line."""
    f = SHOTS / "captions.txt"
    out = {}
    if f.exists():
        for line in f.read_text(encoding="utf-8").splitlines():
            if "|" in line and not line.lstrip().startswith("#"):
                name, cap = line.split("|", 1)
                out[name.strip()] = cap.strip()
    return out


def collect_shots():
    """(path, caption) for every image, in chronological order.

    Files sort naturally by name (2 before 10), so numbering them 01_, 02_ ...
    or A1, A2 ... controls the order they appear in the report. A caption from
    captions.txt wins; otherwise the file name is matched against CAPTIONS.
    """
    if not SHOTS.is_dir():
        return []
    files = [p for p in SHOTS.iterdir()
             if p.suffix.lower() in (".png", ".jpg", ".jpeg")]
    files.sort(key=lambda p: _natural(p.name))
    written = load_captions()
    out = []
    for p in files:
        cap = written.get(p.name) or written.get(p.stem) or _caption_for(p.stem)
        out.append((p, cap))
    return out


def section_for(caption):
    """Which step a screenshot belongs to, decided from its caption."""
    c = caption.lower()
    if "duplicate seat" in c or "grant" in c or "revoke" in c or "viewer" in c:
        return "Step 7:"
    if "rollback" in c or "lock" in c or "transaction" in c:
        return "Step 9:"
    if "explain" in c or "index" in c:
        return "Step 10:"
    if "cleanup" in c or "restores" in c or "row count" in c:
        return "Step 11:"
    return "Step 8:"


class Report(FPDF):
    def __init__(self):
        super().__init__(orientation="P", unit="mm", format="A4")
        self.set_margins(25.4, 22, 25.4)
        self.set_auto_page_break(True, margin=22)
        if FONT == "Calibri":
            for style, fname in (("", "calibri.ttf"), ("B", "calibrib.ttf"),
                                 ("I", "calibrii.ttf"), ("BI", "calibriz.ttf")):
                f = FONT_DIR / fname
                if f.exists():
                    self.add_font("Calibri", style, str(f))
        if MONO == "Mono":
            self.add_font("Mono", "", str(FONT_DIR / "consola.ttf"))
        self.alias_nb_pages()

    # -- text helpers -------------------------------------------------------
    def mc(self, w, h, t, **k):
        k.setdefault("new_x", "LMARGIN")
        k.setdefault("new_y", "NEXT")
        return self.multi_cell(w, h, _ascii(t), **k)

    def footer(self):
        if self.page_no() == 1:
            return
        self.set_y(-16)
        self.set_font(FONT, "", 8.5)
        self.set_text_color(*GREY)
        self.cell(0, 6, "Page %d of {nb}" % self.page_no(), align="C")

    # -- cover --------------------------------------------------------------
    def cover(self, title, sub, meta):
        if LOGO.exists():
            from PIL import Image as _PIL
            _iw, _ih = _PIL.open(LOGO).size
            w = 46
            h = w * _ih / _iw
            self.image(str(LOGO), x=(self.w - w) / 2, y=26, w=w)
            self.set_y(26 + h + 14)
        else:
            self.set_y(35)

        self.set_text_color(*INK)
        self.set_font(FONT, "B", 17)
        self.mc(0, 8, title.upper(), align="C")
        self.set_font(FONT, "B", 12)
        self.ln(10)

        self.set_font(FONT, "", 11)
        self.mc(0, 6, "A Mini Project Report Submitted for the Course", align="C")
        self.set_font(FONT, "B", 11)
        self.mc(0, 6, "Database Management Systems (" + STUDENT["course"] + ")", align="C")
        self.ln(9)

        self.set_font(FONT, "", 11)
        self.mc(0, 6, "Submitted by", align="C")
        self.set_font(FONT, "B", 13)
        self.mc(0, 7, STUDENT["name"], align="C")
        self.set_font(FONT, "", 10.5)
        self.mc(0, 6, "Roll Number: " + STUDENT["roll"] + "     Section: "
                + STUDENT["section"], align="C")
        self.ln(9)

        self.set_font(FONT, "", 11)
        self.mc(0, 6, "Instructor-in-Charge: " + STUDENT["guide"], align="C")
        self.mc(0, 6, "Faculty of Science & Technology (FST)", align="C")
        self.mc(0, 6, "IcfaiTech, IFHE Hyderabad", align="C")
        if STUDENT["date"]:
            self.ln(10)
            self.mc(0, 6, STUDENT["date"], align="C")

        if meta:
            self.set_y(self.h - 34)
            self.set_font(FONT, "I", 8.5)
            self.set_text_color(*GREY)
            self.mc(0, 5, meta, align="C")
        self.set_text_color(*INK)

    # -- headings and body --------------------------------------------------
    def h1(self, t):
        if self.get_y() > self.h - 45:
            self.add_page()
        self.ln(4)
        self.set_font(FONT, "B", 16)
        self.set_text_color(*HEAD_BLUE)
        self.mc(0, 8, t)
        self.set_text_color(*INK)
        self.ln(1)

    def h2(self, t):
        self.ln(2)
        self.set_font(FONT, "B", 13)
        self.set_text_color(*HEAD_BLUE)
        self.mc(0, 7, t)
        self.set_text_color(*INK)
        self.ln(1)

    def para(self, t):
        self.set_font(FONT, "", 11)
        self.set_text_color(*INK)
        self.mc(0, 5.4, t)
        self.ln(1.6)

    def bullets(self, items):
        self.set_font(FONT, "", 11)
        for it in items:
            self.set_x(self.l_margin + 4)
            self.mc(self.w - self.l_margin - self.r_margin - 4, 5.4, "\u2022  " + it)
        self.ln(1.6)

    def data_table(self, headers, rows, widths=(34, 16, 109), line_height=5):
        self.set_font(FONT, "", 9.5)
        self.set_draw_color(*RULE)
        self.set_line_width(0.2)
        self.set_fill_color(255, 255, 255)
        with self.table(col_widths=widths, line_height=line_height,
                        text_align=("LEFT", "LEFT", "LEFT"),
                        headings_style=FontFace(emphasis="BOLD",
                                                fill_color=(240, 242, 245))) as tb:
            hr = tb.row()
            for h in headers:
                hr.cell(h)
            for r in rows:
                row = tb.row()
                for c in r:
                    row.cell(str(c))
        self.ln(3)

    # -- code block ---------------------------------------------------------
    def code(self, text):
        lines = text.splitlines() or [""]
        h, pad = 3.6, 2.2
        total = len(lines) * h + pad * 2
        if self.get_y() + total > self.page_break_trigger:
            self.add_page()
        x, w, y = self.l_margin, self.epw, self.get_y()
        self.set_fill_color(28, 28, 30)
        self.set_draw_color(70, 70, 74)
        self.rect(x, y, w, total, style="DF")
        self.set_font(MONO, "", 7.4)
        self.set_text_color(232, 232, 232)
        self.set_xy(x + 2.5, y + pad)
        for ln in lines:
            self.cell(w - 5, h, _ascii(ln))
            self.ln(h)
        self.set_text_color(*INK)
        self.set_fill_color(255, 255, 255)
        self.set_draw_color(*RULE)
        self.set_y(y + total + 3)

    # -- screenshot grid ----------------------------------------------------
    def screenshot_grid(self, items, start_no, pair_wide=False):
        """Wide shots fill the page; when space is tight, two share a row."""
        from PIL import Image as _PIL

        full = self.w - self.l_margin - self.r_margin
        gap = 6.0
        half = (full - gap) / 2
        max_h = 94.0

        def shape(p, box):
            iw, ih = _PIL.open(p).size
            ar = iw / ih
            h = min(box * ih / iw, max_h)
            return ar, h * ar, h

        def cap_height(text, width):
            per_line = max(12, int(width / 1.55))
            lines = max(1, -(-len(text) // per_line))
            return min(lines, 3) * 4.2 + 1.5

        n = start_no
        i = 0
        while i < len(items):
            first, cap1 = items[i]
            ar1 = _PIL.open(first).size[0] / _PIL.open(first).size[1]
            row = [(first, cap1, full)]
            i += 1
            if i < len(items):
                second, cap2 = items[i]
                ar2 = _PIL.open(second).size[0] / _PIL.open(second).size[1]
                if ((ar1 < 1.45 or (pair_wide and ar1 <= 3.2))
                        and (ar2 < 1.45 or (pair_wide and ar2 <= 3.2))):
                    row = [(first, cap1, half), (second, cap2, half)]
                    i += 1

            shaped = [shape(p, box) for p, _, box in row]
            row_h = max(s[2] for s in shaped)
            caps = [f"Figure {n + k}: {c}" for k, (_, c, _) in enumerate(row)]
            cap_h = max(cap_height(c, shaped[k][1]) for k, c in enumerate(caps))

            avail = self.page_break_trigger - self.get_y()
            if row_h + cap_h > avail:
                if avail >= 50:
                    budget = max(34.0, avail - cap_h - 2)
                    shaped = [(ar, *(lambda hh: (hh * ar, hh))(min(h, budget)))
                              for ar, _w, h in shaped]
                    row_h = max(s[2] for s in shaped)
                else:
                    self.add_page()

            y0 = self.get_y()
            for k, ((p, _cap, box), (ar, w, h)) in enumerate(zip(row, shaped)):
                if len(row) == 1:
                    x = self.l_margin + (full - w) / 2
                else:
                    slot = self.l_margin + k * (half + gap)
                    x = slot + (half - w) / 2
                self.image(str(p), x=x, y=y0, w=w, h=h)
                self.set_xy(x, y0 + row_h + 1.0)
                self.set_font(FONT, "I", 8)
                self.set_text_color(*GREY)
                self.multi_cell(w, 4.2, _ascii(caps[k]), align="C")
                self.set_text_color(*INK)
                n += 1
            self.set_y(y0 + row_h + cap_h)
        return n

    # -- figures ------------------------------------------------------------
    def figure(self, path, caption=None, max_w=158, max_h=240):
        from PIL import Image as _PIL
        iw, ih = _PIL.open(path).size
        scale = min(max_w / iw, max_h / ih)
        w, h = iw * scale, ih * scale
        if self.get_y() + h > self.page_break_trigger:
            self.add_page()
        self.image(str(path), x=(self.w - w) / 2, w=w, h=h)
        if caption:
            self.ln(1.5)
            self.set_font(FONT, "I", 9)
            self.set_text_color(*GREY)
            self.mc(0, 4.5, caption, align="C")
            self.set_text_color(*INK)
        self.ln(2)

    def figure_tall(self, path, caption=None):
        from PIL import Image as _PIL
        img = _PIL.open(path)
        iw, ih = img.size
        half = ih // 2
        tmp = Path(tempfile.gettempdir()) / "skyroute_fig"
        tmp.mkdir(parents=True, exist_ok=True)
        boxes = [(0, 0, iw, half), (0, half, iw, ih)]
        for i, box in enumerate(boxes):
            out = tmp / f"{Path(path).stem}_part{i + 1}.png"
            img.crop(box).save(out)
            self.add_page()
            self.figure(out, caption=f"{caption}  ({i + 1} of {len(boxes)})",
                        max_w=158, max_h=245)


def build(pair_wide=False):
    pdf = Report()
    blocks = load(str(REPORT_SRC))
    title = sub = meta = ""
    rest = []
    for kind, payload in blocks:
        if kind == "title":
            title = payload
        elif kind == "sub":
            sub = payload
        elif kind == "meta":
            meta = (meta + "  |  " + payload) if meta else payload
        else:
            rest.append((kind, payload))

    pdf.add_page()
    pdf.cover(title, sub, meta)
    pdf.add_page()

    fig_no = 2
    shots = collect_shots()
    assigned = {}
    for s in shots:
        assigned.setdefault(section_for(s[1]), []).append(s)
    for sec, items in assigned.items():
        print(f"{sec}  <- {len(items)} figure(s)")
        for _p, cap in items:
            print(f"    {cap[:70]}")
    explicit = any(k == "fig" for k, _ in rest)
    if explicit:
        assigned = {}
    caps = load_captions()

    pending = None
    pending_schema = False
    pending_counts = False

    for kind, payload in rest:
        if kind == "h1":
            if pending_counts:
                need = 17 * 5.2 + 10
                if pdf.page_break_trigger - pdf.get_y() < need:
                    pdf.add_page()
                pdf.set_font(FONT, "B", 9.5)
                pdf.set_text_color(*INK)
                pdf.mc(0, 5.2, "Table 2: What the seed produced, counted with COUNT(*)")
                pdf.data_table(("Table", "Rows", "What it holds"), ROW_COUNTS)
                pending_counts = False
            if pending and assigned.get(pending):
                fig_no = pdf.screenshot_grid(assigned[pending], fig_no, pair_wide)
            pending = next((k for k in assigned if k in payload), None)
            if pending_schema and "Step 6:" not in payload:
                headers, rows = SCHEMA_TABLE
                need = len(rows) * 5.6 + 18
                if pdf.page_break_trigger - pdf.get_y() < need:
                    pdf.add_page()
                pdf.set_font(FONT, "B", 9.5)
                pdf.set_text_color(*INK)
                pdf.mc(0, 5.2, "Table 1: The sixteen tables, their primary keys "
                              "and the rule each one enforces")
                pdf.data_table(headers, rows)
                sch = DESIGN / "Schema_Diagram.png"
                if sch.exists():
                    pdf.figure(sch, caption=f"Figure {fig_no}: Relational schema "
                                            "of skyroute_db (16 tables, 19 foreign keys)",
                               max_w=150, max_h=104)
                    fig_no += 1
                pending_schema = False

            if payload.startswith("Appendix A"):
                pdf.add_page()
                pdf.h1(payload)
                pdf.para("Every check was run against the seeded database on 21 October 2026. "
                         "The table lists all twenty-four, with the file that holds the "
                         "captured output.")
                pdf.set_font(FONT, "B", 9.5)
                pdf.set_text_color(*INK)
                pdf.mc(0, 5.2, "Table 3: The twenty-four checks and where each "
                              "capture lives")
                pdf.data_table(("Check", "What it proves", "Captured in"),
                               APPENDIX_TESTS, widths=(22, 92, 45), line_height=6.9)
                continue

            if "Step 6:" in payload:
                er = DESIGN / "ER_Diagram.png"
                if er.exists():
                    room = pdf.page_break_trigger - pdf.get_y() - 12
                    pdf.figure(er, caption="Figure 1: SkyRoute ER diagram "
                                           "(Chen notation, keys, cardinality)",
                               max_w=158, max_h=max(150.0, min(212.0, room)))
                pdf.add_page()
                pdf.h1(payload)
                pending_schema = True
            else:
                pdf.h1(payload)
                if "Step 7:" in payload:
                    pending_counts = True
        elif kind == "h2":
            pdf.h2(payload)
        elif kind == "p":
            pdf.para(payload)
        elif kind == "bullets":
            pdf.bullets(payload)
        elif kind == "code":
            pdf.code(payload)
        elif kind == "fig":
            path = SHOTS / payload
            if path.exists():
                caption = caps.get(payload) or _caption_for(path.stem)
                pdf.figure(path, caption=f"Figure {fig_no}: {caption}",
                           max_w=136, max_h=100)
                fig_no += 1
            else:
                print("missing figure:", payload)

    if pending and assigned.get(pending):
        fig_no = pdf.screenshot_grid(assigned[pending], fig_no, pair_wide)
    return pdf


pdf = build()
if pdf.page_no() > 15:
    print(f"{pdf.page_no()} pages is over the 15-page limit; shrinking figures and rebuilding")
    pdf = build(pair_wide=True)

pdf.output(str(OUT_PDF))
print("pdf written:", OUT_PDF, "| pages:", pdf.page_no())
