"""SkyRoute booking site - Flask + MySQL via mysql-connector-python (no ORM).
A customer books a real ticket in 3 steps: 1 Search, 2 Choose seat, 3 My bookings.
Every database call is visible SQL, so the app doubles as executable revision.

Run (from repo root):  python python/flask_app/seed_mysql.py        (builds skyroute_app once)
                       python python/flask_app/app.py                 (serves http://127.0.0.1:5000)
Needs MySQL running + python/flask_app/.env credentials.
(SQLite skyroute.db via seed_sqlite.py stays as the offline fallback.)
"""
import re
from datetime import date, timedelta
from functools import wraps
from pathlib import Path

from flask import Flask, flash, g, redirect, render_template, request, session, url_for

from db import Conn, IntegrityError, call_make_booking, connect

ROOT = Path(__file__).resolve().parent
DB = ROOT / "skyroute.db"
FREE_KG, FEE_PER_KG = 20, 500  # baggage fee rule, single source of truth
ADMIN_PIN = "1234"  # demo staff gate (classroom stand-in for staff login)
CUSTOMER_PASSWORD = "fly123"  # demo customer password: ID is unique per traveler, password shared for the demo
# Only routes the airline actually operates — the search offers these and
# nothing else, so same-airport or fantasy routes can't even be picked.
ROUTES = [("HYD-BLR", "HYD → BLR"), ("BLR-HYD", "BLR → HYD"),
          ("DEL-BOM", "DEL → BOM"), ("BLR-DEL", "BLR → DEL"),
          ("HYD-BOM", "HYD → BOM"), ("MAA-HYD", "MAA → HYD"),
          ("HYD-MAA", "HYD → MAA")]

app = Flask(__name__)
app.secret_key = "skyroute-demo-key"  # flash messages only; demo app


def get_db():
    """One MySQL connection per request (skyroute_app via db.py)."""
    if "db" not in g:
        g.db = Conn(connect())
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
            "SELECT first_name, last_name FROM Passengers WHERE passenger_id = %s",
            (pid,)).fetchone()
    return {"traveler": me}


def owns(bid):
    """Staff (admin PIN) can touch any ticket; otherwise only the ticket's
    own traveler can. Every mutating route checks this."""
    if session.get("is_admin"):
        return True
    pid = session.get("pax_id")
    if not pid:
        return False
    r = get_db().execute("SELECT passenger_id FROM Bookings WHERE booking_id = %s",
                         (bid,)).fetchone()
    return bool(r and r["passenger_id"] == pid)


def refuse():
    flash("That ticket isn't yours. Travel as its owner to manage it.", "error")
    return redirect(url_for("bookings"))


def go_next(fallback):
    """Send staff back to the manifest they came from (hidden `next`
    field), otherwise fall back. Keeps old forms working (no `next`)."""
    nxt = (request.form.get("next") or request.args.get("next") or "").strip()
    if nxt.startswith("/") and not nxt.startswith("//"):
        return redirect(nxt)
    return redirect(fallback)


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


def valid_seats(capacity):
    """Every seat number that physically exists on this plane — exactly the
    set seat_map() renders, so input validation can never disagree with
    the seat map (no phantom extra row, no phantom partial-row columns)."""
    cap = capacity or 180
    out, n = set(), 1
    while len(out) < cap:
        for l in "ABCDEF"[: cap - len(out)]:
            out.add(f"{n}{l}")
        n += 1
    return out


CLASSES = ("Economy", "Premium Economy", "Business", "First")


# ------------------------------- 1. search ----------------------------------
@app.route("/", methods=["GET", "POST"])
def index():
    db = get_db()
    airports = db.execute("SELECT * FROM Airports ORDER BY iata_code").fetchall()
    results = []
    if request.method == "POST":
        route = (request.form.get("route") or "").strip().upper()
        day = (request.form.get("day") or "").strip()
        # Forgiving parse: HYD-BLR, HYD → BLR, hyd blr, HYD,BLR all work.
        codes = [t for t in re.split(r"[\s,\-]+", route.replace("→", " ")) if t]
        known = {a["iata_code"] for a in airports}
        if not route or not day or len(codes) != 2:
            flash("Choose a departure route and a date first.", "error")
        elif codes[0] not in known or codes[1] not in known:
            flash("Unknown route. Type one like HYD-BLR.", "error")
        elif codes[0] == codes[1]:
            flash("Departure and arrival airports must differ.", "error")
        else:
            dep, arr = codes
            # Multi-table JOIN lives in the database: v_departure_board
            # already carries flight, airline, airports, gate, aircraft
            # and the non-cancelled seat count (sold).
            results = db.execute(
                """SELECT * FROM v_departure_board
                    WHERE from_airport = %s AND to_airport = %s
                      AND DATE(scheduled_departure) = %s
                    ORDER BY scheduled_departure""",
                (dep, arr, day)).fetchall()
            # Remember the search (with or without hits) so the booking page
            # can offer the way back to these very results.
            session["last_search"] = {"route": dep + "-" + arr, "day": day}
            if not results:
                flash("No departures on this route and date. Try HYD to BLR on 2026-11-03.", "error")
    return render_template("index.html", airports=airports, results=results, routes=ROUTES)


# ------------------------------ 2. choose seat --------------------------------
@app.route("/book/<int:departure_id>", methods=["GET", "POST"])
def book(departure_id):
    db = get_db()
    dep = db.execute(
        "SELECT * FROM v_departure_detail WHERE departure_id = %s",
        (departure_id,)).fetchone()
    if dep is None:
        return "Unknown departure", 404
    # Bookings belong to travelers: staff may book for anyone, a logged-in
    # traveler books only as themselves, guests log in first. Booking never
    # changes who you are logged in as.
    if not session.get("is_admin") and not session.get("pax_id"):
        flash("Log in first — bookings belong to travelers.", "error")
        return redirect(url_for("login"))
    taken = {r["seat_number"] for r in
             db.execute("SELECT seat_number FROM Bookings WHERE departure_id = %s "
                        "AND booking_status != 'Cancelled'",
                        (departure_id,))}
    passengers = db.execute(
        "SELECT * FROM Passengers ORDER BY last_name, first_name").fetchall()
    if request.method == "POST":
        seat = (request.form.get("seat") or "").strip().upper()
        if session.get("is_admin"):
            pid = request.form.get("passenger_id")  # staff books for anyone
        else:
            pid = str(session.get("pax_id"))  # travelers book only as themselves
        tclass = request.form.get("travel_class")
        try:
            price = float(request.form.get("price") or "")
            price_ok = price >= 0
        except ValueError:
            price_ok = False
        cap = dep["capacity"] or 180
        seat_ok = seat in valid_seats(cap)
        pax_ok = pid and pid.isdigit() and db.execute(
            "SELECT 1 FROM Passengers WHERE passenger_id = %s", (int(pid),)).fetchone()
        if not pax_ok:
            flash("Pick a traveler from the list first.", "error")
        elif not seat_ok:
            flash(f"Seat {seat or '?'} doesn't exist on this plane. Tap a white seat on the map.", "error")
        elif not price_ok:
            flash("Price must be a number, zero or more.", "error")
        elif tclass not in CLASSES:
            flash("Pick a valid travel class.", "error")
        elif seat in taken:
            # The UNIQUE(departure_id, seat_number) key would refuse this anyway;
            # we check first to explain it in plain words instead of a crash page.
            flash(f"Seat {seat} is already taken on this departure. Pick a green seat.", "error")
        else:
            try:
                # One stored-procedure call books the seat and opens its
                # payment atomically (all-or-nothing, inside the database).
                # A cancelled booking still holding this (departure, seat)
                # key is cleared by the procedure first; its stale payment,
                # bags and check-in vanish with it via ON DELETE CASCADE.
                bid = call_make_booking(int(pid), departure_id, seat, tclass, price)
            except IntegrityError:
                # Only reachable through a true race now: inputs above are valid,
                # so a constraint failure here means the seat just got taken.
                flash(f"Seat {seat} was just taken by someone else. Pick a green seat.", "error")
            else:
                flash(f"Booked! Seat {seat} on {dep['flight_number']} (booking {bid}).", "ok")
                return redirect(url_for("bookings"))
    grid = seat_map(dep["capacity"] or 180, taken)
    # Traveler directory for the staff autocomplete. Guests get an empty
    # list: the full name+email directory must never leak into page source.
    pax_list = []
    if session.get("is_admin"):
        pax_list = [{"id": p["passenger_id"],
                     "label": f"{p['first_name']} {p['last_name']} ({p['email']})"}
                    for p in passengers]
    return render_template("book.html", dep=dep, grid=grid,
                           taken=sorted(taken), passengers=passengers,
                           pax_list=pax_list,
                           last_search=session.get("last_search"))


# ------------------------------ 3. my bookings --------------------------------
@app.route("/bookings")
def bookings():
    db = get_db()
    # "Travel as" = simulated login. Pick a traveler once; this page then shows
    # only their tickets. No pick = show everything, labeled as the admin view.
    # Identity can only be set via login (password) or staff preview.
    # Direct ?pax= URLs no longer log anyone in: guests go to /login,
    # and the everyone-view (?pax=0) needs the staff PIN.
    pick = request.args.get("pax")
    if pick is not None:
        if pick == "0" or pick == "":
            session.pop("pax_id", None)
            if not session.get("is_admin"):
                flash("Staff only. Unlock the Staff page with the PIN first.", "error")
                return redirect(url_for("login"))
        elif session.get("is_admin"):
            session.pop("pax_id", None)
            if pick.isdigit() and int(pick) > 0:
                session["pax_id"] = int(pick)
            return redirect(url_for("bookings"))
        else:
            flash("Log in with your traveler ID first.", "error")
            return redirect(url_for("login"))
    pax_id = session.get("pax_id")
    # Privacy gate: with no traveler picked, show NOBODY's tickets — only the
    # picker. A bookings page that leaks everyone's travel plans by default is
    # a privacy bug, and examiners always ask "can anyone cancel anyone's
    # ticket?" This gate is the answer: no identity, no tickets, no actions.
    if pax_id is None and pick is None:
        travelers = db.execute(
            "SELECT passenger_id, first_name, last_name FROM Passengers ORDER BY passenger_id LIMIT 120").fetchall()
        return render_template("bookings.html", rows=[], travelers=travelers,
                               me=None, pax_id=None, gated=True, trav_list=[])
    where, args = "", []
    if pax_id:
        where, args = "WHERE passenger_id = %s", [pax_id]
    # Every JOIN the ticket list needs (passenger, flight, airports, gate,
    # payment, bags/boarding aggregates) lives in v_booking_list.
    rows = db.execute(
        f"""SELECT * FROM v_booking_list
            {where}
            ORDER BY booking_id DESC LIMIT 100""", args).fetchall()
    travelers = db.execute(
        "SELECT passenger_id, first_name, last_name FROM Passengers ORDER BY passenger_id LIMIT 120").fetchall()
    me = None
    if pax_id:
        me = db.execute("SELECT first_name, last_name FROM Passengers WHERE passenger_id = %s",
                        (pax_id,)).fetchone()
    trav_list = []
    if session.get("is_admin"):
        trav_list = [{"id": t["passenger_id"],
                      "label": f"{t['first_name']} {t['last_name']}"}
                     for t in travelers]
    return render_template("bookings.html", rows=rows, travelers=travelers,
                           me=me, pax_id=pax_id, gated=False, trav_list=trav_list)


@app.route("/travel-as/<int:pid>", methods=["POST"])
@admin_only
def travel_as(pid):
    """Staff preview tool: view the system as one traveler."""
    session["pax_id"] = pid
    return redirect(url_for("bookings"))


@app.route("/login", methods=["GET", "POST"])
def login():
    """Customer login: unique traveler ID + demo password.
    Classroom stand-in for real auth — the ID proves WHO, the demo
    password proves it's really them. Sets the same session the
    bookings privacy gate already filters on, so a traveler sees
    only their own tickets."""
    if request.method == "POST":
        pid = (request.form.get("passenger_id") or "").strip()
        pw = request.form.get("password") or ""
        me = None
        if pid.isdigit() and int(pid) > 0:
            me = get_db().execute(
                "SELECT passenger_id, first_name, last_name FROM Passengers "
                "WHERE passenger_id = %s", (int(pid),)).fetchone()
        if me is None:
            flash("No traveler with that ID. Find your ID on the Passengers page.", "error")
        elif pw != CUSTOMER_PASSWORD:
            flash("Wrong demo password.", "error")
        else:
            session["pax_id"] = me["passenger_id"]
            flash(f"Welcome, {me['first_name']} — showing only your tickets.", "ok")
            return redirect(url_for("bookings"))
    return render_template("login.html")


@app.route("/logout", methods=["GET", "POST"])
def logout():
    session.pop("pax_id", None)
    flash("Logged out. No tickets are shown until the next login.", "ok")
    return redirect(url_for("index"))


@app.route("/staff-logout", methods=["POST"])
def staff_logout():
    """Lock the staff portal again (clears staff PIN + any preview)."""
    session.pop("is_admin", None)
    session.pop("pax_id", None)
    flash("Staff portal locked.", "ok")
    return redirect(url_for("index"))


@app.route("/manifest/<int:departure_id>")
def manifest(departure_id):
    """Staff manifest: pick a flight departure, see every passenger on it.
    Staff-only: guests are sent to unlock the Staff page first."""
    if not session.get("is_admin"):
        flash("Staff only. Unlock the Staff page with the PIN first.", "error")
        return redirect(url_for("admin"))
    db = get_db()
    # Header + seat rows come straight from the two staff views; the header
    # view also carries the non-cancelled seat count (sold) for the stats.
    dep = db.execute(
        "SELECT * FROM v_departure_board WHERE departure_id = %s",
        (departure_id,)).fetchone()
    if dep is None:
        return "Unknown departure", 404
    rows = db.execute(
        "SELECT * FROM v_manifest WHERE departure_id = %s ORDER BY seat_number",
        (departure_id,)).fetchall()
    cap = dep["capacity"] or 180
    sold = dep["sold"] or 0
    revenue = sum((r["price"] or 0) for r in rows
                  if r["booking_status"] != "Cancelled")
    checked = sum(1 for r in rows if r["boarding"])
    stats = {"capacity": cap, "sold": sold,
             "load": round(sold / cap * 100) if cap else 0,
             "revenue": revenue, "checked": checked,
             "bags": sum((r["bags"] or 0) for r in rows)}
    return render_template("manifest.html", dep=dep, rows=rows, stats=stats,
                           back=(request.args.get("back") or ""))


@app.route("/bookings/<int:bid>/edit", methods=["POST"])
def booking_edit(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    # Two plain single-table reads instead of one JOIN: Bookings is keyed
    # by booking_id, and v_departure_detail already carries the aircraft
    # capacity. A missing booking stays the same plain 404; a departure
    # missing under it keeps the old JOIN's None result (same 404).
    booking = db.execute(
        "SELECT departure_id FROM Bookings WHERE booking_id = %s", (bid,)).fetchone()
    if booking is None:
        return "Unknown booking", 404
    dep = db.execute(
        "SELECT capacity FROM v_departure_detail WHERE departure_id = %s",
        (booking["departure_id"],)).fetchone()
    if dep is None:
        return "Unknown booking", 404
    seat = (request.form.get("seat") or "").strip().upper()
    tclass = request.form.get("travel_class")
    try:
        price = float(request.form.get("price") or "")
        price_ok = price >= 0
    except ValueError:
        price_ok = False
    clash = db.execute(
        "SELECT 1 FROM Bookings WHERE departure_id = %s AND seat_number = %s "
        "AND booking_id != %s AND booking_status != 'Cancelled'",
        (booking["departure_id"], seat, bid)).fetchone()
    if seat not in valid_seats(dep["capacity"]):
        flash(f"Seat {seat or '?'} doesn't exist on this plane.", "error")
    elif not price_ok:
        flash("Price must be a number, zero or more.", "error")
    elif tclass not in CLASSES:
        flash("Pick a valid travel class.", "error")
    elif clash:
        flash(f"Seat {seat} is taken. Nothing was changed.", "error")
    else:
        try:
            with db:
                db.execute("UPDATE Bookings SET seat_number = %s, travel_class = %s, price = %s "
                           "WHERE booking_id = %s",
                           (seat, tclass, price, bid))
        except IntegrityError:
            flash(f"Seat {seat} is taken. Nothing was changed.", "error")
        else:
            flash(f"Booking {bid} updated to seat {seat}.", "ok")
    return go_next(url_for("bookings"))


@app.route("/bookings/<int:bid>/cancel", methods=["POST"])
def booking_cancel(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:
        db.execute("UPDATE Bookings SET booking_status = 'Cancelled' WHERE booking_id = %s", (bid,))
    flash(f"Booking {bid} cancelled. The seat is free again.", "ok")
    return go_next(url_for("bookings"))


@app.route("/bookings/<int:bid>/delete", methods=["POST"])
def booking_delete(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:  # bags, payment, check-in vanish via ON DELETE CASCADE
        db.execute("DELETE FROM Bookings WHERE booking_id = %s", (bid,))
    flash(f"Booking {bid} deleted with its bags, payment and check-in.", "ok")
    return go_next(url_for("bookings"))


# --------------------------- passengers (register) ------------------------------
@app.route("/passengers", methods=["GET", "POST"])
def passengers():
    """Public traveler registration. New travelers sign up here and get
    their numeric ID (their login ID). The full traveler list lives only
    in the staff portal — showing everyone's details publicly would
    defeat the login's privacy."""
    db = get_db()
    if request.method == "POST":
        try:
            with db:
                cur = db.execute("INSERT INTO Passengers (first_name, last_name, passport_number, phone, email) "
                           "VALUES (%s, %s, %s, %s, %s)",
                           (request.form["first_name"], request.form["last_name"],
                            request.form["passport_number"] or None,
                            request.form["phone"], request.form["email"]))
                pid = cur.lastrowid
        except IntegrityError:
            flash("That passport number or email is already registered.", "error")
        else:
            flash(f"Registered! Your traveler ID is {pid} — log in with it + demo password fly123.", "ok")
        return redirect(url_for("passengers"))
    return render_template("passengers.html")


@app.route("/passengers/<int:pid>/delete", methods=["POST"])
@admin_only
def passenger_delete(pid):
    db = get_db()
    with db:
        db.execute("DELETE FROM Passengers WHERE passenger_id = %s", (pid,))
    flash("Passenger deleted with all their bookings.", "ok")
    return redirect(url_for("passengers"))


@app.route("/passengers/<int:pid>/edit", methods=["POST"])
@admin_only
def passenger_edit(pid):
    """Staff Update: correct a passenger's details (the U in CRUD)."""
    db = get_db()
    try:
        with db:
            db.execute("UPDATE Passengers SET first_name = %s, last_name = %s, "
                       "passport_number = %s, phone = %s, email = %s "
                       "WHERE passenger_id = %s",
                       (request.form["first_name"].strip(),
                        request.form["last_name"].strip(),
                        request.form.get("passport_number", "").strip() or None,
                        request.form["phone"].strip(),
                        request.form["email"].strip(), pid))
    except IntegrityError:
        flash("That passport number or email belongs to someone else. Nothing changed.", "error")
    else:
        flash(f"Passenger {pid} updated.", "ok")
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
        return go_next(url_for("bookings"))
    if not 0 < weight <= 100:
        flash("Bags must weigh between 0 and 100 kg.", "error")
        return go_next(url_for("bookings"))
    with db:
        seq = db.execute("SELECT COALESCE(MAX(baggage_seq), 0) + 1 AS n FROM Baggage WHERE booking_id = %s",
                         (bid,)).fetchone()["n"]
        db.execute("INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (%s, %s, %s)",
                   (bid, seq, weight))
    extra = max(weight - FREE_KG, 0) * FEE_PER_KG
    if extra:
        flash(f"Bag {weight} kg added: {weight - FREE_KG:.1f} kg over the free 20 kg = Rs {extra:.0f} fee.", "ok")
    else:
        flash(f"Bag {weight} kg added: within the free 20 kg allowance.", "ok")
    return go_next(url_for("bookings"))


@app.route("/payment/<int:bid>/pay", methods=["POST"])
def payment_pay(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:
        db.execute("UPDATE Payments SET pay_status = 'Paid', paid_at = NOW() "
                   "WHERE booking_id = %s", (bid,))
    flash(f"Payment for booking {bid} marked Paid.", "ok")
    return go_next(url_for("bookings"))


@app.route("/checkin/<int:bid>", methods=["POST"])
def checkin(bid):
    if not owns(bid):
        return refuse()
    db = get_db()
    with db:
        db.execute("INSERT IGNORE INTO Check_Ins (booking_id, boarding_status) VALUES (%s, 'Boarded')",
                   (bid,))
    flash(f"Booking {bid} checked in. Boarding pass ready.", "ok")
    return go_next(url_for("bookings"))


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
                               "arrival_airport_id, sched_departure, sched_arrival) VALUES (%s, %s, %s, %s, %s, %s)",
                               (fno, request.form["airline_id"],
                                dep, arr, request.form["dep_t"], request.form["arr_t"]))
                    # A timetable flight with no dated departures is invisible in
                    # search, so open the next 7 days at once (no aircraft/gate yet).
                    fid, dt, at = cur.lastrowid, request.form["dep_t"], request.form["arr_t"]
                    for n in range(7):
                        d = date(2026, 11, 8) + timedelta(days=n)
                        db.execute("INSERT INTO Departures (flight_id, scheduled_departure, scheduled_arrival) "
                                   "VALUES (%s, %s, %s)",
                                   (fid, f"{d} {dt}", f"{d} {at}"))
            except IntegrityError:
                flash(f"Flight {fno} already exists. Flight numbers are unique.", "error")
            else:
                flash(f"Flight {fno} added with 7 dated departures.", "ok")
        return redirect(url_for("admin"))
    counts = {t: db.execute(f"SELECT COUNT(*) AS n FROM {t}").fetchone()["n"]
              for t in ("Flights", "Departures", "Passengers", "Bookings",
                        "Baggage", "Payments", "Check_Ins")}
    flights = db.execute(
        "SELECT * FROM v_flight_list ORDER BY flight_id").fetchall()
    airports = db.execute("SELECT * FROM Airports ORDER BY iata_code").fetchall()
    airlines = db.execute("SELECT * FROM Airlines ORDER BY airline_id").fetchall()
    departures = db.execute(
        """SELECT departure_id, flight_number, from_airport, to_airport,
                  DATE(scheduled_departure) AS day, sold
           FROM v_departure_board
           ORDER BY scheduled_departure LIMIT 60""").fetchall()
    travelers = db.execute("SELECT * FROM Passengers ORDER BY passenger_id DESC LIMIT 200").fetchall()
    return render_template("admin.html", counts=counts, flights=flights,
                           airports=airports, airlines=airlines,
                           departures=departures, travelers=travelers)


@app.route("/flights/<int:fid>/toggle", methods=["POST"])
@admin_only
def flight_toggle(fid):
    db = get_db()
    with db:
        db.execute("UPDATE Flights SET flight_status = "
                   "CASE WHEN flight_status = 'Active' THEN 'Suspended' ELSE 'Active' END "
                    "WHERE flight_id = %s", (fid,))
    return redirect(url_for("admin"))


@app.route("/flights/<int:fid>/delete", methods=["POST"])
@admin_only
def flight_delete(fid):
    """Staff Delete: remove a timetable flight with no dated departures."""
    db = get_db()
    n = db.execute("SELECT COUNT(*) AS n FROM Departures WHERE flight_id = %s",
                   (fid,)).fetchone()["n"]
    if n:
        flash(f"Flight has {n} dated departure(s). Suspend it instead of deleting.", "error")
        return redirect(url_for("admin"))
    with db:
        db.execute("DELETE FROM Flights WHERE flight_id = %s", (fid,))
    flash("Flight deleted.", "ok")
    return redirect(url_for("admin"))


if __name__ == "__main__":
    app.run(debug=True)
