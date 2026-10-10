"""SkyRoute web app — Flask + stdlib sqlite3 (no ORM).
Every database call is visible SQL, so the app doubles as executable revision.

Run (from project root):  python flask_app/seed_sqlite.py   (builds the demo DB once)
                           python flask_app/app.py           (serves http://127.0.0.1:5000)
"""
import sqlite3
from pathlib import Path

from flask import Flask, g, redirect, render_template, request, url_for

ROOT = Path(__file__).resolve().parent
DB = ROOT / "skyroute.db"
FREE_KG, FEE_PER_KG = 20, 500  # baggage fee rule, single source of truth

app = Flask(__name__)

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

def fee_for(weight):
    return max(weight - FREE_KG, 0) * FEE_PER_KG

# ------------------------------- search -------------------------------------
@app.route("/", methods=["GET", "POST"])
def index():
    db = get_db()
    airports = db.execute("SELECT * FROM Airports ORDER BY iata_code").fetchall()
    results, msg = [], ""
    if request.method == "POST":
        dep, arr, day = request.form["dep"], request.form["arr"], request.form["day"]
        if dep == arr:
            msg = "Departure and arrival airports must differ."
        else:
            results = db.execute(
                """SELECT fi.instance_id, f.flight_number, al.airline_name,
                          fi.scheduled_departure, fi.scheduled_arrival,
                          g.gate_number, fi.instance_status,
                          (SELECT COUNT(*) FROM Bookings b
                            WHERE b.instance_id = fi.instance_id) AS sold,
                          ac.capacity
                   FROM Flight_Instances fi
                   JOIN Flights f ON fi.flight_id = f.flight_id
                   JOIN Airlines al ON f.airline_id = al.airline_id
                   JOIN Airports dep ON f.departure_airport_id = dep.airport_id
                   JOIN Airports arr ON f.arrival_airport_id = arr.airport_id
                   LEFT JOIN Aircraft ac ON fi.aircraft_id = ac.aircraft_id
                   LEFT JOIN Gates g ON fi.gate_id = g.gate_id
                   WHERE dep.iata_code = ? AND arr.iata_code = ?
                     AND date(fi.scheduled_departure) = ?
                   ORDER BY fi.scheduled_departure""",
                (dep, arr, day)).fetchall()
            if not results:
                msg = "No flights on this route and date."
    return render_template("index.html", airports=airports, results=results, msg=msg)

# -------------------------------- booking ------------------------------------
@app.route("/book/<int:instance_id>", methods=["GET", "POST"])
def book(instance_id):
    db = get_db()
    inst = db.execute(
        "SELECT fi.*, f.flight_number FROM Flight_Instances fi "
        "JOIN Flights f ON fi.flight_id = f.flight_id WHERE fi.instance_id = ?",
        (instance_id,)).fetchone()
    if inst is None:
        return "Unknown flight instance", 404
    taken = {r["seat_number"] for r in
             db.execute("SELECT seat_number FROM Bookings WHERE instance_id = ?", (instance_id,))}
    passengers = db.execute(
        "SELECT * FROM Passengers ORDER BY last_name, first_name").fetchall()
    msg = ""
    if request.method == "POST":
        seat = request.form["seat"].strip().upper()
        if seat in taken:
            # The UNIQUE(instance_id, seat_number) key would refuse this anyway;
            # we check first to explain it in plain words instead of a 500 page.
            msg = f"Seat {seat} is already taken on this flight. Pick another."
        else:
            try:
                with db:  # one transaction: booking + payment together or neither
                    cur = db.execute(
                        "INSERT INTO Bookings (passenger_id, instance_id, seat_number, travel_class, price) "
                        "VALUES (?, ?, ?, ?, ?)",
                        (request.form["passenger_id"], instance_id, seat,
                         request.form["travel_class"], request.form["price"]))
                    bid = cur.lastrowid
                    db.execute(
                        "INSERT INTO Payments (booking_id, amount, pay_method, pay_status, txn_reference) "
                        "VALUES (?, ?, 'UPI', 'Pending', ?)",
                        (bid, request.form["price"], f"TXNAPP{100000 + bid}"))
            except sqlite3.IntegrityError:
                msg = f"Seat {seat} was just taken by someone else. Pick another."
            else:
                return redirect(url_for("bookings"))
    return render_template("book.html", inst=inst, taken=sorted(taken),
                           passengers=passengers, msg=msg)

# --------------------------- bookings CRUD -----------------------------------
@app.route("/bookings")
def bookings():
    db = get_db()
    rows = db.execute(
        """SELECT b.*, p.first_name, p.last_name, f.flight_number, fi.scheduled_departure,
                  pay.pay_status,
                  COALESCE((SELECT SUM(MAX(weight_kg - 20, 0)) * 500 FROM Baggage
                            WHERE booking_id = b.booking_id), 0) AS fee
           FROM Bookings b
           JOIN Passengers p ON b.passenger_id = p.passenger_id
           JOIN Flight_Instances fi ON b.instance_id = fi.instance_id
           JOIN Flights f ON fi.flight_id = f.flight_id
           LEFT JOIN Payments pay ON b.booking_id = pay.booking_id
           ORDER BY b.booking_id DESC LIMIT 100""").fetchall()
    return render_template("bookings.html", rows=rows)

@app.route("/bookings/<int:bid>/edit", methods=["POST"])
def booking_edit(bid):
    db = get_db()
    seat = request.form["seat"].strip().upper()
    try:
        with db:
            db.execute("UPDATE Bookings SET seat_number = ?, travel_class = ?, price = ? "
                       "WHERE booking_id = ?",
                       (seat, request.form["travel_class"], request.form["price"], bid))
    except sqlite3.IntegrityError:
        pass  # seat taken: UNIQUE key refused the edit, booking unchanged
    return redirect(url_for("bookings"))

@app.route("/bookings/<int:bid>/cancel", methods=["POST"])
def booking_cancel(bid):
    db = get_db()
    with db:
        db.execute("UPDATE Bookings SET booking_status = 'Cancelled' WHERE booking_id = ?", (bid,))
    return redirect(url_for("bookings"))

@app.route("/bookings/<int:bid>/delete", methods=["POST"])
def booking_delete(bid):
    db = get_db()
    with db:  # bags, payment, check-in vanish via ON DELETE CASCADE
        db.execute("DELETE FROM Bookings WHERE booking_id = ?", (bid,))
    return redirect(url_for("bookings"))

# ------------------------------ passengers -----------------------------------
@app.route("/passengers", methods=["GET", "POST"])
def passengers():
    db = get_db()
    if request.method == "POST":
        with db:
            db.execute("INSERT INTO Passengers (first_name, last_name, passport_number, phone, email) "
                       "VALUES (?, ?, ?, ?, ?)",
                       (request.form["first_name"], request.form["last_name"],
                        request.form["passport_number"] or None,
                        request.form["phone"], request.form["email"]))
        return redirect(url_for("passengers"))
    rows = db.execute("SELECT * FROM Passengers ORDER BY passenger_id DESC LIMIT 100").fetchall()
    return render_template("passengers.html", rows=rows)

@app.route("/passengers/<int:pid>/delete", methods=["POST"])
def passenger_delete(pid):
    db = get_db()
    with db:
        db.execute("DELETE FROM Passengers WHERE passenger_id = ?", (pid,))
    return redirect(url_for("passengers"))

# --------------------------- baggage / pay / checkin --------------------------
@app.route("/baggage/<int:bid>", methods=["POST"])
def baggage_add(bid):
    db = get_db()
    weight = float(request.form["weight"])
    with db:
        seq = db.execute("SELECT COALESCE(MAX(baggage_seq), 0) + 1 FROM Baggage WHERE booking_id = ?",
                         (bid,)).fetchone()[0]
        db.execute("INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (?, ?, ?)",
                   (bid, seq, weight))
    return redirect(url_for("bookings"))

@app.route("/payment/<int:bid>/pay", methods=["POST"])
def payment_pay(bid):
    db = get_db()
    with db:
        db.execute("UPDATE Payments SET pay_status = 'Paid', paid_at = datetime('now') "
                   "WHERE booking_id = ?", (bid,))
    return redirect(url_for("bookings"))

@app.route("/checkin/<int:bid>", methods=["POST"])
def checkin(bid):
    db = get_db()
    with db:
        db.execute("INSERT OR IGNORE INTO Check_Ins (booking_id, boarding_status) VALUES (?, 'Boarded')",
                   (bid,))
    return redirect(url_for("bookings"))

# ------------------------------- admin ----------------------------------------
@app.route("/admin", methods=["GET", "POST"])
def admin():
    db = get_db()
    if request.method == "POST" and request.form.get("flight_number"):
        with db:
            db.execute("INSERT INTO Flights (flight_number, airline_id, departure_airport_id, "
                       "arrival_airport_id, sched_departure, sched_arrival) VALUES (?, ?, ?, ?, ?, ?)",
                       (request.form["flight_number"], request.form["airline_id"],
                        request.form["dep"], request.form["arr"],
                        request.form["dep_t"], request.form["arr_t"]))
        return redirect(url_for("admin"))
    counts = {t: db.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
              for t in ("Flights", "Flight_Instances", "Passengers", "Bookings",
                        "Baggage", "Payments", "Check_Ins")}
    flights = db.execute(
        "SELECT f.*, al.airline_name FROM Flights f "
        "JOIN Airlines al ON f.airline_id = al.airline_id ORDER BY f.flight_id").fetchall()
    airports = db.execute("SELECT * FROM Airports ORDER BY iata_code").fetchall()
    airlines = db.execute("SELECT * FROM Airlines ORDER BY airline_id").fetchall()
    return render_template("admin.html", counts=counts, flights=flights,
                           airports=airports, airlines=airlines)

@app.route("/flights/<int:fid>/toggle", methods=["POST"])
def flight_toggle(fid):
    db = get_db()
    with db:
        db.execute("UPDATE Flights SET flight_status = "
                   "CASE WHEN flight_status = 'Active' THEN 'Suspended' ELSE 'Active' END "
                   "WHERE flight_id = ?", (fid,))
    return redirect(url_for("admin"))

if __name__ == "__main__":
    app.run(debug=True)
