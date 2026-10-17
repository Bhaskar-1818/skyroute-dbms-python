"""MySQL access for the SkyRoute Flask demo (mysql-connector-python).

Same helper shape as the reference AFMS project: fetch_all / fetch_one /
execute plus a transaction() context manager. Credentials come from the
repo .env file (never committed); DB_NAME defaults to skyroute_app.
Every helper opens its own connection and closes it — no connection
ever leaks past a request, and the booking/payment pair commits atomically.
"""
import os
from contextlib import contextmanager
from pathlib import Path

import mysql.connector
from dotenv import load_dotenv
from mysql.connector import errors as _errors

load_dotenv(Path(__file__).resolve().parent / ".env")

IntegrityError = _errors.IntegrityError


def _cfg(db=None):
    return dict(host=os.getenv("DB_HOST", "127.0.0.1"),
                port=int(os.getenv("DB_PORT", "3306")),
                user=os.getenv("DB_USER", "root"),
                password=os.getenv("DB_PASSWORD", ""),
                database=db or os.getenv("DB_NAME", "skyroute_app"))


def connect(db=None):
    """One MySQL connection (autocommit off — callers commit explicitly)."""
    return mysql.connector.connect(**_cfg(db))


def connect_admin():
    """Password-only connection for CREATE/DROP DATABASE (no database yet)."""
    cfg = _cfg()
    cfg.pop("database", None)
    return mysql.connector.connect(**cfg)


def fetch_all(sql, params=(), db=None):
    conn = connect(db)
    try:
        cur = conn.cursor(dictionary=True, buffered=True)
        cur.execute(sql, params)
        return cur.fetchall()
    finally:
        conn.close()


def fetch_one(sql, params=(), db=None):
    conn = connect(db)
    try:
        cur = conn.cursor(dictionary=True, buffered=True)
        cur.execute(sql, params)
        return cur.fetchone()
    finally:
        conn.close()


def execute(sql, params=(), db=None):
    """Single write: commits, returns lastrowid, rolls back on error."""
    conn = connect(db)
    try:
        cur = conn.cursor()
        cur.execute(sql, params)
        conn.commit()
        return cur.lastrowid
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


@contextmanager
def transaction(db=None):
    """Multi-statement write on one connection: all commit or all roll back.
    Yields a plain cursor (use cur.lastrowid for INSERT ids)."""
    conn = connect(db)
    cur = conn.cursor()
    try:
        yield cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def call_make_booking(passenger_id, departure_id, seat, tclass, price):
    """Book a seat + open its pending payment via sp_make_booking (the whole
    thing is one stored-procedure transaction). Returns the new booking_id.
    A seat that is genuinely taken trips the UNIQUE key inside the
    procedure; the raw IntegrityError is re-raised here, so app.py's
    existing except IntegrityError handling keeps working."""
    conn = connect()
    try:
        cur = conn.cursor()
        # The connector reads OUT parameters back for us: callproc() SETs
        # @_sp_make_booking_arg1..6, CALLs the procedure, then SELECTs those
        # variables back on this same connection and returns the row.
        # p_booking_id is the 6th argument, so it lands at index 5.
        args = cur.callproc("sp_make_booking",
                            (passenger_id, departure_id, seat, tclass, price, 0))
        booking_id = args[5] if args else None
        if not booking_id:
            # Older/other connector versions may not hand the OUT value
            # back; LAST_INSERT_ID() still holds it on this connection.
            cur.execute("SELECT LAST_INSERT_ID()")
            booking_id = cur.fetchone()[0]
        conn.commit()
        return booking_id
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def _clean(value):
    """MySQL returns DATETIME as datetime objects; SQLite returned the same
    columns as 'YYYY-MM-DD HH:MM:SS' strings and every template slices and
    prints them as strings. Converting here keeps all pages byte-identical."""
    import datetime as _dt
    if isinstance(value, (_dt.datetime, _dt.date)):
        return value.strftime("%Y-%m-%d %H:%M:%S")
    return value


class _Cur:
    def __init__(self, cur):
        self._cur = cur

    def fetchone(self):
        row = self._cur.fetchone()
        return {k: _clean(v) for k, v in row.items()} if row else None

    def fetchall(self):
        return [{k: _clean(v) for k, v in row.items()}
                for row in self._cur.fetchall()]

    def __iter__(self):
        return iter(self.fetchall())

    @property
    def lastrowid(self):
        return self._cur.lastrowid


class Conn:
    """Drop-in per-request connection behind the old get_db() call sites:
    conn.execute(sql, params) with %s placeholders, .fetchone()/.fetchall()
    of dict rows, .lastrowid, and `with conn:` for multi-statement commits."""

    def __init__(self, conn):
        self._conn = conn

    def execute(self, sql, params=()):
        # buffered: the full result set lands client-side at once, so a
        # partially-read SELECT can never block the next statement with
        # "Unread result found" on the shared per-request connection.
        cur = self._conn.cursor(dictionary=True, buffered=True)
        cur.execute(sql, params)
        return _Cur(cur)

    def commit(self):
        self._conn.commit()

    def rollback(self):
        self._conn.rollback()

    def close(self):
        self._conn.close()

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        if exc[0] is None:
            self._conn.commit()
        else:
            self._conn.rollback()
        return False
