"""Builds dbms/docs/SkyRoute_Report.pdf from REPORT_TEXT.md (themed).
Run from repo root:  python dbms/docs/build_pdf.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fpdf import FPDF  # noqa: E402

from report_content import SCHEMA_TABLE, load  # noqa: E402

NAVY, AMBER, INK, MUT, PAPER = ((15, 37, 64), (245, 166, 35),
                                (34, 34, 34), (91, 107, 127), (246, 248, 251))


class Report(FPDF):
    def mc(self, w, h, t, **k):
        k.setdefault("new_x", "LMARGIN")
        k.setdefault("new_y", "NEXT")
        for a, b in [("—", "--"), ("–", "-"), ("•", "-"), ("’", "'"),
                     ("“", '"'), ("”", '"'), ("…", "..."), ("≤", "<=")]:
            t = t.replace(a, b)
        return self.multi_cell(w, h, t, **k)

    def header(self):
        if self.page_no() > 1:
            self.set_font("Helvetica", "I", 9)
            self.set_text_color(*MUT)
            self.mc(0, 8, "SkyRoute: Airline Booking, Baggage & Staff Operations System")

    def cover(self, title, sub, meta):
        self.set_fill_color(*NAVY)
        self.rect(0, 0, 210, 110, "F")
        self.set_y(18)
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(*AMBER)
        self.mc(0, 8, "SKYROUTE  DBMS MINI PROJECT", align="C")
        self.set_font("Helvetica", "B", 24)
        self.set_text_color(255, 255, 255)
        self.mc(0, 11, title, align="C")
        self.set_font("Helvetica", "", 11)
        self.set_text_color(207, 227, 247)
        self.mc(0, 7, sub, align="C")
        self.mc(0, 7, meta, align="C")
        self.set_y(120)
        self.set_text_color(*INK)

    def h1(self, t):
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(*NAVY)
        self.mc(0, 9, t)
        self.set_draw_color(*AMBER)
        self.set_line_width(1.2)
        self.line(self.l_margin, self.get_y(), self.l_margin + 40, self.get_y())
        self.ln(3)
        self.set_text_color(*INK)

    def h2(self, t):
        self.set_font("Helvetica", "B", 12)
        self.set_text_color(*NAVY)
        self.mc(0, 8, t)
        self.set_text_color(*INK)

    def para(self, t):
        self.set_font("Helvetica", "", 10.5)
        self.mc(0, 6, t)
        self.ln(1)

    def bullets(self, items):
        self.set_font("Helvetica", "", 10.5)
        for it in items:
            self.mc(0, 6, "-  " + it)
        self.ln(1)

    def table(self, headers, rows):
        self.set_font("Helvetica", "B", 9.5)
        w = 190 / len(headers)
        self.set_fill_color(*NAVY)
        self.set_text_color(255, 255, 255)
        for hd in headers:
            self.cell(w, 7, hd, border=1, fill=True)
        self.ln()
        self.set_font("Helvetica", "", 9)
        self.set_text_color(*INK)
        for i, row in enumerate(rows):
            if i % 2 == 1:
                self.set_fill_color(*PAPER)
            for val in row:
                self.cell(w, 6.5, str(val)[:44], border=1, fill=(i % 2 == 1))
            self.ln()
        self.ln(2)


pdf = Report()
pdf.set_auto_page_break(True, margin=20)
pdf.add_page()
blocks = load()
title = sub = meta = ""
rest = []
for kind, payload in blocks:
    if kind == "title":
        title = payload
    elif kind == "sub":
        sub = (sub + " | " + payload) if sub else payload
    elif kind == "meta":
        meta = payload
    else:
        rest.append((kind, payload))
pdf.cover(title, sub, meta)
for kind, payload in rest:
    if kind == "h1":
        pdf.h1(payload)
        if "Step 6:" in payload:
            headers, rows = SCHEMA_TABLE
            pdf.table(headers, rows)
    elif kind == "h2":
        pdf.h2(payload)
    elif kind == "p":
        pdf.para(payload)
    elif kind == "bullets":
        pdf.bullets(payload)

pdf.output("dbms/docs/SkyRoute_Report.pdf")
print("pdf written")
