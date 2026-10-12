"""End-to-end check of the booking site via Flask test client (no server needed).
Runs against a throwaway MySQL database (reseeded fresh every run), so the
demo skyroute_app is never dirtied. Run from repo root:
    python python/flask_app/test_app.py
Needs MySQL running + python/flask_app/.env credentials."""
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from app import app  # noqa: E402
from db import connect  # noqa: E402
from seed_mysql import main as seed_db  # noqa: E402

TDB = os.getenv("TEST_DB", "skyroute_test")
seed_db(TDB)
# Point the app itself at the test database too: get_db() reads DB_NAME
# per request, so every test-client call below hits the fresh reseed.
os.environ["DB_NAME"] = TDB

c = app.test_client()
c2 = app.test_client()  # stranger with no identity


class Rows:
    """Eagerly fetched rows (tuple-style, like the old sqlite3 rows)."""

    def __init__(self, rows):
        self._rows = rows

    def fetchone(self):
        return self._rows[0] if self._rows else None

    def fetchall(self):
        return self._rows

    def __iter__(self):
        return iter(self._rows)


class Q:
    """Fresh MySQL connection per SELECT (short-lived, closed at once).
    A single long-lived connection would pin a REPEATABLE READ snapshot
    and hide rows the app commits mid-test — each query must see the
    latest committed state, like the old shared-file reads did."""

    def execute(self, sql, params=()):
        conn = connect(TDB)
        try:
            cur = conn.cursor()
            cur.execute(sql, params)
            return Rows(cur.fetchall())
        finally:
            conn.close()

    def close(self):
        pass


db = Q()


def free_seat(dep_id, skip=()):
    taken = {r[0] for r in db.execute(
        "SELECT seat_number FROM Bookings WHERE departure_id = %s", (dep_id,))}
    taken |= set(skip)
    return next(f"{r}{l}" for r in range(1, 31) for l in "ABCDEF" if f"{r}{l}" not in taken)


r = c2.get("/bookings")
assert b"Who's traveling?" in r.data and b"SR-" not in r.data, "privacy gate failed"
print("privacy gate (no identity, no tickets) ok")

r = c.get("/")
assert r.status_code == 200 and b"SkyRoute" in r.data, "home failed"

r = c.post("/", data={"route": "HYD-BLR", "day": "2026-11-03"})
assert r.status_code == 200 and b"6E-501" in r.data, "search failed"
print("search HYD->BLR ok")

r = c.post("/", data={"route": "MAA-HYD", "day": "2026-11-03"})
assert r.status_code == 200 and b"6E-561" in r.data, "MAA chip search failed"
print("search MAA->HYD ok")

r = c.post("/", data={"route": "MAA-HYD", "day": "2026-11-02"})
assert r.status_code == 200 and b"No departures" in r.data, "sparse timetable broken"
print("sparse timetable (empty date) ok")

r = c.post("/", data={"day": "2026-11-03"})
assert r.status_code == 200 and b"Choose a departure" in r.data, "missing-field guard failed"
print("missing-field guard ok")

r = c.post("/", data={"route": "HYD-HYD", "day": "2026-11-03"})
assert b"must differ" in r.data, "same-airport guard failed"
print("same-airport refusal ok")

r = c.get("/manifest/1")
assert r.status_code == 302, "guest manifest not redirected"
r = c2.get("/manifest/1", follow_redirects=True)
assert b"Staff only" in r.data, "manifest not staff-gated"
print("manifest staff gate ok")

r = c.get("/book/1")
assert r.status_code == 302 and "/login" in r.headers.get("Location", ""), "guest booking not sent to login"
print("booking login wall ok")

r = c.post("/login", data={"passenger_id": "1", "password": "fly123"}, follow_redirects=True)
assert b"Welcome" in r.data, "login failed"
print("login ok")

r = c.get("/book/1")
assert r.status_code == 200 and b"Pick your seat" in r.data, "seat map page failed"
print("seat map ok")

seat_a = free_seat(1)
r = c.post("/book/1", data={"passenger_id": "1", "seat": seat_a,
                            "travel_class": "Economy", "price": "4500"})
assert r.status_code == 302, f"booking create failed: {r.status_code}"
print("booking create ok")

r = c.post("/book/1", data={"passenger_id": "2", "seat": "99Z",
                            "travel_class": "Economy", "price": "4500"})
assert r.status_code == 200 and b"on this plane" in r.data, "bad-seat guard failed"
assert db.execute("SELECT COUNT(*) FROM Bookings WHERE seat_number = '99Z'").fetchone()[0] == 0
print("bad seat refused ok")

r = c.post("/book/1", data={"passenger_id": "2", "seat": seat_a,
                            "travel_class": "Economy", "price": "4500"})
assert r.status_code == 200 and b"already taken" in r.data, "double-booking guard failed"
print("double-booking refused ok")

bid = db.execute("SELECT booking_id FROM Bookings WHERE departure_id = 1 "
                 "AND seat_number = %s ORDER BY booking_id DESC",
                 (seat_a,)).fetchone()[0]

seat_b = free_seat(1, skip=[seat_a])
c.post(f"/bookings/{bid}/edit",
       data={"seat": seat_b, "travel_class": "Business", "price": "14000"})
assert db.execute("SELECT seat_number FROM Bookings WHERE booking_id = %s",
                  (bid,)).fetchone()[0] == seat_b, "edit failed"
print("booking edit ok")

c.post(f"/baggage/{bid}", data={"weight": "25"})
fee = db.execute("SELECT SUM(GREATEST(weight_kg - 20, 0)) * 500 FROM Baggage "
                 "WHERE booking_id = %s", (bid,)).fetchone()[0]
assert fee == 2500, f"fee wrong: {fee}"
print("baggage + fee (25kg -> Rs 2500) ok")

c.post(f"/baggage/{bid}", data={"weight": "-5"})
assert db.execute("SELECT COUNT(*) FROM Baggage WHERE booking_id = %s",
                  (bid,)).fetchone()[0] == 1, "bad weight accepted!"
print("bad weight refused ok")

c.post(f"/payment/{bid}/pay")
assert db.execute("SELECT pay_status FROM Payments WHERE booking_id = %s",
                  (bid,)).fetchone()[0] == "Paid", "pay failed"
c.post(f"/checkin/{bid}")
assert db.execute("SELECT COUNT(*) FROM Check_Ins WHERE booking_id = %s",
                  (bid,)).fetchone()[0] == 1, "check-in failed"
print("payment + check-in ok")

c.post(f"/bookings/{bid}/cancel")
assert db.execute("SELECT booking_status FROM Bookings WHERE booking_id = %s",
                  (bid,)).fetchone()[0] == "Cancelled", "cancel failed"
print("cancel ok")

c.post(f"/bookings/{bid}/delete")
assert db.execute("SELECT COUNT(*) FROM Bookings WHERE booking_id = %s",
                  (bid,)).fetchone()[0] == 0, "delete failed"
assert db.execute("SELECT COUNT(*) FROM Baggage WHERE booking_id = %s",
                  (bid,)).fetchone()[0] == 0, "cascade failed"
print("delete + cascade ok")

r = c.post("/passengers", data={"first_name": "Test", "last_name": "User",
                                "passport_number": "T999", "phone": "9000000001",
                                "email": "test.user@example.com"})
assert r.status_code == 302
pid = db.execute("SELECT passenger_id FROM Passengers WHERE email = 'test.user@example.com'").fetchone()[0]
r = c.post(f"/passengers/{pid}/delete", follow_redirects=True)
assert b"Staff only" in r.data, "passenger delete not staff-gated"
assert db.execute("SELECT COUNT(*) FROM Passengers WHERE passenger_id = %s",
                  (pid,)).fetchone()[0] == 1, "ungated delete went through!"
print("passenger delete staff-gated ok")

r = c.get("/admin")
assert r.status_code == 200 and b"Staff only" in r.data, "admin not gated"
r = c.post("/admin", data={"pin": "1234"}, follow_redirects=True)
assert b"Timetable" in r.data, "admin unlock failed"
print("admin PIN gate ok")

r = c.post("/admin", data={"flight_number": "6E-501", "airline_id": "1", "dep": "1",
                           "arr": "2", "dep_t": "08:00", "arr_t": "09:30"},
           follow_redirects=True)
assert b"already exists" in r.data, "duplicate flight not refused"
print("duplicate flight refused ok")

r = c.post("/admin", data={"flight_number": "SG-999", "airline_id": "3", "dep": "3",
                           "arr": "3", "dep_t": "08:00", "arr_t": "09:30"},
           follow_redirects=True)
assert b"cannot depart and arrive" in r.data
assert db.execute("SELECT COUNT(*) FROM Flights WHERE flight_number = 'SG-999'").fetchone()[0] == 0
print("same-airport flight refused ok")

c.post(f"/passengers/{pid}/delete")
assert db.execute("SELECT COUNT(*) FROM Passengers WHERE passenger_id = %s",
                  (pid,)).fetchone()[0] == 0, "staff passenger delete failed"
print("passenger add/delete ok")

r = c.post("/travel-as/1")
assert r.status_code == 302
r = c.get("/bookings")
assert b"Filtered to" in r.data, "filter banner missing"
mine = db.execute("SELECT COUNT(*) FROM Bookings WHERE passenger_id = 1").fetchone()[0]
assert r.data.count(b"SR-") >= min(mine, 100), "filtered list wrong"
print("travel-as filter ok")

r = c.get("/bookings?pax=0")
assert b"admin view" in r.data and b"SR-" in r.data, "admin view failed"
print("admin view ok")

r = c.get("/")
assert b"Popular right now" in r.data and b"DEL" in r.data, "route chips missing"
print("network chips ok")

victim = db.execute("SELECT booking_id FROM Bookings LIMIT 1").fetchone()[0]
r = c2.post(f"/bookings/{victim}/delete", follow_redirects=True)
assert b"isn&#39;t yours" in r.data or b"isn't yours" in r.data, "cross-user delete not refused"
assert db.execute("SELECT COUNT(*) FROM Bookings WHERE booking_id = %s",
                  (victim,)).fetchone()[0] == 1, "cross-user delete went through!"
print("cross-user mutation refused ok")
db.close()
print("ALL APP TESTS PASSED")
