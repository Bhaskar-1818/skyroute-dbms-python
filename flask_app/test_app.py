"""End-to-end check of the Flask app via its test client (no server needed).
Run from project root:  python flask_app/test_app.py"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from app import app  # noqa: E402

c = app.test_client()

r = c.get("/")
assert r.status_code == 200, "home failed"

r = c.post("/", data={"dep": "HYD", "arr": "BLR", "day": "2026-11-03"})
assert r.status_code == 200 and b"6E-501" in r.data, "search failed"
print("search HYD->BLR ok")

r = c.get("/book/1")
assert r.status_code == 200, "book page failed"

# create booking on free seat 99Z (outside normal seat map, guaranteed free)
r = c.post("/book/1", data={"passenger_id": "1", "seat": "99Z",
                            "travel_class": "Economy", "price": "4500"})
assert r.status_code == 302, f"booking create failed: {r.status_code}"
print("booking create ok")

# duplicate seat must be refused with words, not a 500
r = c.post("/book/1", data={"passenger_id": "2", "seat": "99Z",
                            "travel_class": "Economy", "price": "4500"})
assert r.status_code == 200 and b"already taken" in r.data, "double-booking guard failed"
print("double-booking refused ok")

r = c.get("/bookings")
assert r.status_code == 200 and b"99Z" in r.data, "bookings list failed"

import sqlite3
db = sqlite3.connect(Path(__file__).resolve().parent / "skyroute.db")
bid = db.execute("SELECT booking_id FROM Bookings WHERE seat_number = '99Z'").fetchone()[0]

# edit seat (Update), cancel, baggage+fee, pay, check-in, delete
r = c.post(f"/bookings/{bid}/edit",
           data={"seat": "98Z", "travel_class": "Business", "price": "14000"})
assert r.status_code == 302
assert db.execute("SELECT seat_number FROM Bookings WHERE booking_id = ?",
                  (bid,)).fetchone()[0] == "98Z", "edit failed"
print("booking edit ok")

c.post(f"/baggage/{bid}", data={"weight": "25"})
fee = db.execute("SELECT SUM(MAX(weight_kg - 20, 0)) * 500 FROM Baggage "
                 "WHERE booking_id = ?", (bid,)).fetchone()[0]
assert fee == 2500, f"fee wrong: {fee}"
print("baggage + fee (25kg -> Rs 2500) ok")

c.post(f"/payment/{bid}/pay")
assert db.execute("SELECT pay_status FROM Payments WHERE booking_id = ?",
                  (bid,)).fetchone()[0] == "Paid", "pay failed"
c.post(f"/checkin/{bid}")
assert db.execute("SELECT COUNT(*) FROM Check_Ins WHERE booking_id = ?",
                  (bid,)).fetchone()[0] == 1, "check-in failed"
print("payment + check-in ok")

c.post(f"/bookings/{bid}/cancel")
assert db.execute("SELECT booking_status FROM Bookings WHERE booking_id = ?",
                  (bid,)).fetchone()[0] == "Cancelled", "cancel failed"
print("cancel ok")

c.post(f"/bookings/{bid}/delete")
assert db.execute("SELECT COUNT(*) FROM Bookings WHERE booking_id = ?",
                  (bid,)).fetchone()[0] == 0, "delete failed"
assert db.execute("SELECT COUNT(*) FROM Baggage WHERE booking_id = ?",
                  (bid,)).fetchone()[0] == 0, "cascade failed"
print("delete + cascade ok")

# passengers CRUD
r = c.post("/passengers", data={"first_name": "Test", "last_name": "User",
                                "passport_number": "T999", "phone": "9000000001",
                                "email": "test.user@example.com"})
assert r.status_code == 302
pid = db.execute("SELECT passenger_id FROM Passengers WHERE email = 'test.user@example.com'").fetchone()[0]
c.post(f"/passengers/{pid}/delete")
assert db.execute("SELECT COUNT(*) FROM Passengers WHERE passenger_id = ?",
                  (pid,)).fetchone()[0] == 0, "passenger delete failed"
print("passenger add/delete ok")

r = c.get("/admin")
assert r.status_code == 200, "admin failed"
print("admin ok")
db.close()
print("ALL APP TESTS PASSED")
