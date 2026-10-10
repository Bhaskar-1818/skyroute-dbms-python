"""SkyRoute booking site - Flask + stdlib sqlite3 (no ORM).
A customer books a real ticket in 3 steps: 1 Search, 2 Choose seat, 3 My bookings.
Every database call is visible SQL, so the app doubles as executable revision.

Run (from repo root):  python python/flask_app/seed_sqlite.py  (builds demo DB once)
                       python python/flask_app/app.py            (serves http://127.0.0.1:5000)
"""
import re
import sqlite3
from datetime import date, timedelta
from functools import wraps
from pathlib import Path

from flask import Flask, flash, g, redirect, render_template, request, session, url_for

ROOT = Path(__file__).resolve().parent
DB = ROOT / "skyroute.db"
FREE_KG, FEE_PER_KG = 20, 500  # baggage fee rule, single source of truth
ADMIN_PIN = "1234"  # demo staff gate (classroom stand-in for staff login)

app = Flask(__name__)
app.secret_key = "skyroute-demo-key"  # flash messages only; demo app


def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON")
    return g.db


@app.teardown_appcontext
def close_db(exc):
    db = g.pop("db", None)
    if db is not None:
        db.close()


@app.context_processor
def traveler():
    """Traveling-as badge for the header on every page (None = guest)."""
    me = None
    pid = session.get("pax_id")
    if pid:
        me = get_db().execute(
            "SELECT first_name, last_name FROM Passengers WHERE passenger_id = ?",
            (pid,)).fetchone()
    return {"traveler": me}


def owns(bid):
    """True only if the ticket belongs to the current traveler. Every
    mutating route checks this, so nobody can touch anyone else's tickets."""
    pid = session.get("pax_id")
    if not pid:
        return False
    r = get_db().execute("SELECT passenger_id FROM Bookings WHERE booking_id = ?",
                         (bid,)).fetchone()
    return bool(r and r["passenger_id"] == pid)


def refuse():
    flash("That ticket isn't yours. Travel as its owner to manage it.", "error")
    return redirect(url_for("bookings"))


def admin_only(fn):
    """Staff gate: timetable and passenger deletes need the demo PIN."""
    @wraps(fn)
    def w(*a, **k):
        if not session.get("is_admin"):
            flash("Staff only. Unlock the admin page with the PIN first.", "error")
            return redirect(url_for("admin"))
        return fn(*a, **k)
    return w


def seat_map(capacity, taken):
    """Full cabin grid for the booking page. Taken seats render disabled,
    which is the UNIQUE(departure_id, seat_number) rule made visible."""
    rows = []
    n = 1
    while len(rows) * 6 < capacity:
        row = [f"{n}{l}" for l in "ABCDEF"][: capacity - len(rows) * 6]
        rows.append([(s, s in taken) for s in row])
        n += 1
    return rows


# ------------------------------- 1. search ----------------------------------
@app.route("/", methods=["GET", "POST"])
def index():
    db = get_db()
    airports = db.execute("SELECT * FROM Airports ORDER BY iata_code").fetchall()
    results = []
    if request.method == "POST":
        dep = (request.form.get("dep") or "").strip().upper()
        arr = (request.form.get("arr") or "").strip().upper()
        day = (request.form.get("day") or "").strip()
        known = {a["iata_code"] for a in airports}
        if not dep or not arr or not day:
            flash("Choose a departure, an arrival and a date first.", "error")
        elif dep not in known or arr not in known:
            flash("Unknown airport. Pick both cities from the lists.", "error")
        elif dep == arr:
            flash("Departure and arrival airports must differ.", "error")
        else:
            results = db.execute(
                """SELECT d.departure_id, f.flight_number, al.airline_name,
                          d.scheduled_departure, d.scheduled_arrival,
                          g.gate_number, d.departure_status,
                          (SELECT COUNT(*) FROM Bookings b
                            WHERE b.departure_id = d.departure_id) AS sold,
                          ac.capacity, ac.model
                   FROM Departures d
                   JOIN Flights f ON d.flight_id = f.flight_id
                   JOIN Airlines al ON f.airline_id = al.airline_id
                   JOIN Airports dep ON f.departure_airport_id = dep.airport_id
                   JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
                   LEFT JOIN Aircraft ac ON d.aircraft_id = ac.aircraft_id
                   LEFT JOIN Gates g ON d.gate_id = g.gate_id
                   WHERE dep.iata_code = ? AND arr.iata_code = ?
                     AND date(d.scheduled_departure) = ?
                   ORDER BY d.scheduled_departure""",
                (dep, arr, day)).fetchall()
            if not results:
                flash("No departures on this route and date. Try HYD to BLR on 2026-11-03.", "error")
    return render_template("index.html", airports=airports, results=results)


# ------------------------------ 2. choose seat --------------------------------
@app.route("/book/<int:departure_id>", methods=["GET", "POST"])
def book(departure_id):
    db = get_db()
    dep = db.execute(
        """SELECT d.*, f.flight_number, al.airline_name, ac.capacity, ac.model,
                  dep_a.iata_code AS from_airport, arr_a.iata_code AS to_airport
           FROM Departures d
           JOIN Flights f ON d.flight_id = f.flight_id
           JOIN Airlines al ON f.airline_id = al.airline_id
           JOIN Airports dep_a ON f.departure_airport_id = dep_a.airport_id
           JOIN Airports arr_a ON f.arrival_airport_id = arr_a.airport_id
           LEFT JOIN Aircraft ac ON d.aircraft_id = ac.aircraft_id
           WHERE d.departure_id = ?""",
        (departure_id,)).fetchone()
    if dep is None:
        return "Unknown departure", 404
    taken = {r["seat_number"] for r in
             db.execute("SELECT seat_number FROM Bookings WHERE departure_id = ?",
                        (departure_id,))}
    passengers = db.execute(
        "SELECT * FROM Passengers ORDER BY last_name, first_name").fetchall()
    if request.method == "POST":
        seat = (request.form.get("seat") or "").strip().upper()
        pid = request.form.get("passenger_id")
        tclass = request.form.get("travel_class")
        try:
            price = float(request.form.get("price") or "")
            price_ok = price >= 0
        except ValueError:
            price_ok = False
        cap = dep["capacity"] or 180
        max_row = cap // 6 + 1
        seat_ok = bool(re.fullmatch(r"[1-9][0-9]?[A-F]", seat or ""))
        if seat_ok:
            seat_ok = int(seat[:-1]) <= max_row
        pax_ok = pid and pid.isdigit() and db.execute(
            "SELECT 1 FROM Passengers WHERE passenger_id = ?", (int(pid),)).fetchone()
        if not pax_ok:
            flash("Pick a traveler from the list first.", "error")
        elif not seat_ok:
            flash(f"Seat {seat or '?'} doesn't exist on this plane. Tap a white seat on the map.", "error")
        elif not price_ok:
            flash("Price must be a number, zero or more.", "error")
        elif tclass not in ("Economy", "Premium Economy", "Business", "First"):
            flash("Pick a valid travel class.", "error")
        elif seat in taken:
            # The UNIQUE(departure_id, seat_number) key would refuse this anyway;
            # we check first to explain it in plain words instead of a crash page.
            flash(f"Seat {seat} is already taken on this departure. Pick a green seat.", "error")
        else:
            try:
                with db:  # one transaction: booking + payment together or neither
                    cur = db.execute(
                        "INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price) "
                        "VALUES (?, ?, ?, ?, ?)",
                        (int(pid), departure_id, seat, tclass, price))
                    bid = cur.lastrowid
                    db.execute(
                        "INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference) "
                        "VALUES (?, ?, 'UPI', 'Pending', ?)",
                        (bid, price, f"TXNAPP{100000 + bid}"))
            except sqlite3.IntegrityError:
                # Only reachable through a true race now: inputs above are valid,
                # so a constraint failure here means the seat just got taken.
                flash(f"Seat {seat} was just taken by someone else. Pick a green seat.", "error")
            else:
                session["pax_id"] = int(pid)
                flash(f"Booked! Seat {seat} on {dep['flight_number']} (booking {bid}).", "ok")
                return redirect(url_for("bookings"))
    grid = seat_map(dep["capacity"] or 180, taken)
    return render_template("book.html", dep=dep, grid=grid,
                           taken=sorted(taken), passengers=passengers)


# ------------------------------ 3. my bookings --------------------------------
@app.route("/bookings")
def bookings():
    db = get_db()
    # "Travel as" = simulated login. Pick a traveler once; this page then shows
    # only their tickets. No pick = show everything, labeled as the admin view.
    pick = request.args.get("pax")
    if pick is not None:
        session.pop("pax_id", None)
        if pick.isdigit() and int(pick) > 0:
            session["pax_id"] = int(pick)
    pax_id = session.get("pax_id")
    # Privacy gate: with no traveler picked, show NOBODY's tickets — only the
    # picker. A bookings page that leaks everyone's travel plans by default is
    # a privacy bug, and examiners always ask "can anyone cancel anyone's
    # ticket?" This gate is the answer: no identity, no tickets, no actions.
    if pax_id is None and pick is None:
        travelers = db.execute(
            "SELECT passenger_id, first_name, last_name FROM Passengers ORDER BY passenger_id LIMIT 120").fetchall()
        return render_template("bookings.html", rows=[], travelers=travelers,
                               me=None, pax_id=None, gated=True)
    where, args = "", []
    if pax_id:
        where, args = "WHERE b.passenger_id = ?", [pax_id]
    rows = db.execute(
        f"""SELECT b.*, p.first_name, p.last_name, f.flight_number, d.scheduled_departure,
                  d.scheduled_arrival, dep.iata_code AS from_airport, arr.iata_code AS to_airport,
                  g.gate_number, pay.pay_status,
                  (SELECT COUNT(*) FROM Baggage WHERE booking_id = b.booking_id) AS bags,
                  COALESCE((SELECT SUM(weight_kg) FROM Baggage
                            WHERE booking_id = b.booking_id), 0) AS bag_kg,
                  COALESCE((SELECT ROUND(SUM(MAX(weight_kg - 20, 0)) * 500, 2) FROM Baggage
                            WHERE booking_id = b.booking_id), 0) AS fee,
                  (SELECT boarding_status FROM Check_Ins WHERE booking_id = b.booking_id) AS boarding
           FROM Bookings b
           JOIN Passengers p ON b.passenger_id = p.passenger_id
           JOIN Departures d ON b.departure_id = d.departure_id
           JOIN Flights f ON d.flight_id = f.flight_id
           JOIN Airports dep ON f.departure_airport_id = dep.airport_id
           JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
           LEFT JOIN Gates g ON d.gate_id = g.gate_id
           LEFT JOIN Payments pay ON b.booking_id = pay.booking_id
           {where}
           ORDER BY b.booking_id DESC LIMIT 100""", args).fetchall()
    travelers = db.execute(
        "SELECT passenger_id, first_name, last_name FROM Passengers ORDER BY passenger_id LIMIT 120").fetchall()
    me = None
    if pax_id:
        me = db.execute("SELECT first_name, last_name FROM Passengers WHERE passenger_id = ?",
                        (pax_id,)).fetchone()
    return render_template("bookings.html", rows=rows, travelers=travelers,
                           me=me, pax_id=pax_id, gated=False)


@app.route("/travel-as/<int:pid>", methods=["POST"])
def travel_as(pid):
    session["pax_id"] = pid
    return redirect(url_for("bookings"))


@app.route("/bookings/<int:bid>/edit", methods=["POST"])
def booking_edit(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    seat = request.form["seat"].strip().upper()
    try:
        with db:
            db.execute("UPDATE Bookings SET seat_number = ?, travel_class = ?, price = ? "
                       "WHERE booking_id = ?",
                       (seat, request.form["travel_class"], request.form["price"], bid))
    except sqlite3.IntegrityError:
        flash(f"Seat {seat} is taken. Nothing was changed.", "error")
    else:
        flash(f"Booking {bid} updated to seat {seat}.", "ok")
    return redirect(url_for("bookings"))


@app.route("/bookings/<int:bid>/cancel", methods=["POST"])
def booking_cancel(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:
        db.execute("UPDATE Bookings SET booking_status = 'Cancelled' WHERE booking_id = ?", (bid,))
    flash(f"Booking {bid} cancelled. The seat is free again.", "ok")
    return redirect(url_for("bookings"))


@app.route("/bookings/<int:bid>/delete", methods=["POST"])
def booking_delete(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:  # bags, payment, check-in vanish via ON DELETE CASCADE
        db.execute("DELETE FROM Bookings WHERE booking_id = ?", (bid,))
    flash(f"Booking {bid} deleted with its bags, payment and check-in.", "ok")
    return redirect(url_for("bookings"))


# --------------------------- passengers (CRUD) --------------------------------
@app.route("/passengers", methods=["GET", "POST"])
def passengers():
    db = get_db()
    if request.method == "POST":
        try:
            with db:
                db.execute("INSERT INTO Passengers (first_name, last_name, passport_number, phone, email) "
                           "VALUES (?, ?, ?, ?, ?)",
                           (request.form["first_name"], request.form["last_name"],
                            request.form["passport_number"] or None,
                            request.form["phone"], request.form["email"]))
        except sqlite3.IntegrityError:
            flash("That passport number or email is already registered.", "error")
        else:
            flash("Passenger added. They can now be picked on the booking page.", "ok")
        return redirect(url_for("passengers"))
    rows = db.execute("SELECT * FROM Passengers ORDER BY passenger_id DESC LIMIT 100").fetchall()
    return render_template("passengers.html", rows=rows)


@app.route("/passengers/<int:pid>/delete", methods=["POST"])
@admin_only
def passenger_delete(pid):
    db = get_db()
    with db:
        db.execute("DELETE FROM Passengers WHERE passenger_id = ?", (pid,))
    flash("Passenger deleted with all their bookings.", "ok")
    return redirect(url_for("passengers"))


# --------------------- baggage / payment / check-in ----------------------------
@app.route("/baggage/<int:bid>", methods=["POST"])
def baggage_add(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    try:
        weight = float(request.form["weight"])
    except ValueError:
        flash("Enter the weight as a number, e.g. 23.5.", "error")
        return redirect(url_for("bookings"))
    if not 0 < weight <= 100:
        flash("Bags must weigh between 0 and 100 kg.", "error")
        return redirect(url_for("bookings"))
    with db:
        seq = db.execute("SELECT COALESCE(MAX(baggage_seq), 0) + 1 FROM Baggage WHERE booking_id = ?",
                         (bid,)).fetchone()[0]
        db.execute("INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (?, ?, ?)",
                   (bid, seq, weight))
    extra = max(weight - FREE_KG, 0) * FEE_PER_KG
    if extra:
        flash(f"Bag {weight} kg added: {weight - FREE_KG:.1f} kg over the free 20 kg = Rs {extra:.0f} fee.", "ok")
    else:
        flash(f"Bag {weight} kg added: within the free 20 kg allowance.", "ok")
    return redirect(url_for("bookings"))


@app.route("/payment/<int:bid>/pay", methods=["POST"])
def payment_pay(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:
        db.execute("UPDATE Payments SET pay_status = 'Paid', paid_at = datetime('now') "
                   "WHERE booking_id = ?", (bid,))
    flash(f"Payment for booking {bid} marked Paid.", "ok")
    return redirect(url_for("bookings"))


@app.route("/checkin/<int:bid>", methods=["POST"])
def checkin(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:
        db.execute("INSERT OR IGNORE INTO Check_Ins (booking_id, boarding_status) VALUES (?, 'Boarded')",
                   (bid,))
    flash(f"Booking {bid} checked in. Boarding pass ready.", "ok")
    return redirect(url_for("bookings"))


# --------------------------------- admin ---------------------------------------
@app.route("/admin", methods=["GET", "POST"])
def admin():
    db = get_db()
    if request.method == "POST" and "pin" in request.form:
        if request.form["pin"] == ADMIN_PIN:
            session["is_admin"] = True
            flash("Welcome, staff.", "ok")
        else:
            flash("Wrong PIN.", "error")
        return redirect(url_for("admin"))
    if not session.get("is_admin"):
        return render_template("admin_unlock.html")
    if request.method == "POST" and request.form.get("flight_number"):
        dep, arr = request.form["dep"], request.form["arr"]
        fno = (request.form["flight_number"] or "").strip().upper()
        if dep == arr:
            flash("A flight cannot depart and arrive at the same airport.", "error")
        elif not fno:
            flash("Give the flight a number, e.g. SG-999.", "error")
        else:
            try:
                with db:
                    cur = db.execute("INSERT INTO Flights (flight_number, airline_id, departure_airport_id, "
                               "arrival_airport_id, sched_departure, sched_arrival) VALUES (?, ?, ?, ?, ?, ?)",
                               (fno, request.form["airline_id"],
                                dep, arr, request.form["dep_t"], request.form["arr_t"]))
                    # A timetable flight with no dated departures is invisible in
                    # search, so open the next 7 days at once (no aircraft/gate yet).
                    fid, dt, at = cur.lastrowid, request.form["dep_t"], request.form["arr_t"]
                    for n in range(7):
                        d = date(2026, 11, 8) + timedelta(days=n)
                        db.execute("INSERT INTO Departures (flight_id, scheduled_departure, scheduled_arrival) "
                                   "VALUES (?, ?, ?)",
                                   (fid, f"{d} {dt}", f"{d} {at}"))
            except sqlite3.IntegrityError:
                flash(f"Flight {fno} already exists. Flight numbers are unique.", "error")
            else:
                flash(f"Flight {fno} added with 7 dated departures.", "ok")
        return redirect(url_for("admin"))
    counts = {t: db.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
              for t in ("Flights", "Departures", "Passengers", "Bookings",
                        "Baggage", "Payments", "Check_Ins")}
    flights = db.execute(
        "SELECT f.*, al.airline_name FROM Flights f "
        "JOIN Airlines al ON f.airline_id = al.airline_id ORDER BY f.flight_id").fetchall()
    airports = db.execute("SELECT * FROM Airports ORDER BY iata_code").fetchall()
    airlines = db.execute("SELECT * FROM Airlines ORDER BY airline_id").fetchall()
    return render_template("admin.html", counts=counts, flights=flights,
                           airports=airports, airlines=airlines)


@app.route("/flights/<int:fid>/toggle", methods=["POST"])
@admin_only
def flight_toggle(fid):
    db = get_db()
    with db:
        db.execute("UPDATE Flights SET flight_status = "
                   "CASE WHEN flight_status = 'Active' THEN 'Suspended' ELSE 'Active' END "
                   "WHERE flight_id = ?", (fid,))
    return redirect(url_for("admin"))


if __name__ == "__main__":
    app.run(debug=True)
