-- SkyRoute Flask project : SQLite schema v2 (stdlib sqlite3, no ORM).
-- Same design as the MySQL build: Departures (dated departures), no runways,
-- no crew assignments. ENUM -> TEXT + CHECK. Run once via seed_sqlite.py.
PRAGMA foreign_keys = ON;

CREATE TABLE Airports (
  airport_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  iata_code    TEXT NOT NULL,
  airport_name TEXT NOT NULL,
  city         TEXT NOT NULL,
  country      TEXT NOT NULL DEFAULT 'India',
  UNIQUE (iata_code),
  UNIQUE (airport_name)
);

CREATE TABLE Airlines (
  airline_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  airline_name TEXT NOT NULL,
  iata_code    TEXT NOT NULL,
  country      TEXT NOT NULL DEFAULT 'India',
  UNIQUE (airline_name),
  UNIQUE (iata_code)
);

CREATE TABLE Aircraft (
  aircraft_id INTEGER PRIMARY KEY AUTOINCREMENT,
  tail_number TEXT NOT NULL,
  model       TEXT NOT NULL,
  capacity    INTEGER NOT NULL CHECK (capacity > 0 AND capacity <= 850),
  airline_id  INTEGER NOT NULL REFERENCES Airlines (airline_id)
              ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE (tail_number)
);

CREATE TABLE Flights (
  flight_id            INTEGER PRIMARY KEY AUTOINCREMENT,
  flight_number        TEXT NOT NULL,
  airline_id           INTEGER NOT NULL REFERENCES Airlines (airline_id)
                       ON DELETE CASCADE ON UPDATE CASCADE,
  departure_airport_id INTEGER NOT NULL REFERENCES Airports (airport_id)
                       ON DELETE RESTRICT ON UPDATE CASCADE,
  arrival_airport_id   INTEGER NOT NULL REFERENCES Airports (airport_id)
                       ON DELETE RESTRICT ON UPDATE CASCADE,
  sched_departure      TEXT NOT NULL,
  sched_arrival        TEXT NOT NULL,
  flight_status        TEXT NOT NULL DEFAULT 'Active'
                       CHECK (flight_status IN ('Active','Suspended')),
  UNIQUE (flight_number),
  CHECK (departure_airport_id <> arrival_airport_id)
);

CREATE TABLE Terminals (
  terminal_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  airport_id    INTEGER NOT NULL REFERENCES Airports (airport_id)
                ON DELETE CASCADE ON UPDATE CASCADE,
  terminal_code TEXT NOT NULL,
  terminal_name TEXT NOT NULL,
  UNIQUE (airport_id, terminal_code)
);

CREATE TABLE Gates (
  gate_id     INTEGER PRIMARY KEY AUTOINCREMENT,
  terminal_id INTEGER NOT NULL REFERENCES Terminals (terminal_id)
              ON DELETE CASCADE ON UPDATE CASCADE,
  gate_number TEXT NOT NULL,
  gate_status TEXT NOT NULL DEFAULT 'Open'
              CHECK (gate_status IN ('Open','Closed','Maintenance')),
  UNIQUE (terminal_id, gate_number)
);

CREATE TABLE Departures (
  departure_id        INTEGER PRIMARY KEY AUTOINCREMENT,
  flight_id           INTEGER NOT NULL REFERENCES Flights (flight_id)
                      ON DELETE CASCADE ON UPDATE CASCADE,
  scheduled_departure TEXT NOT NULL,
  scheduled_arrival   TEXT NOT NULL,
  departure_status    TEXT NOT NULL DEFAULT 'Scheduled'
                      CHECK (departure_status IN
                        ('Scheduled','Boarding','Departed','Arrived','Delayed','Cancelled')),
  aircraft_id INTEGER REFERENCES Aircraft (aircraft_id)
              ON DELETE SET NULL ON UPDATE CASCADE,
  gate_id     INTEGER REFERENCES Gates (gate_id)
              ON DELETE SET NULL ON UPDATE CASCADE,
  UNIQUE (flight_id, scheduled_departure),
  CHECK (scheduled_arrival > scheduled_departure)
);

CREATE TABLE Passengers (
  passenger_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  first_name      TEXT NOT NULL,
  last_name       TEXT NOT NULL,
  passport_number TEXT,
  nationality     TEXT NOT NULL DEFAULT 'India',
  phone           TEXT NOT NULL,
  email           TEXT NOT NULL,
  UNIQUE (passport_number),
  UNIQUE (email)
);

CREATE TABLE Bookings (
  booking_id   INTEGER PRIMARY KEY AUTOINCREMENT,
  passenger_id INTEGER NOT NULL REFERENCES Passengers (passenger_id)
               ON DELETE CASCADE ON UPDATE CASCADE,
  departure_id INTEGER NOT NULL REFERENCES Departures (departure_id)
               ON DELETE CASCADE ON UPDATE CASCADE,
  seat_number  TEXT NOT NULL,
  travel_class TEXT NOT NULL DEFAULT 'Economy'
               CHECK (travel_class IN ('Economy','Premium Economy','Business','First')),
  price        REAL NOT NULL CHECK (price >= 0),
  booking_status TEXT NOT NULL DEFAULT 'Confirmed'
               CHECK (booking_status IN ('Pending','Confirmed','Cancelled','Refunded')),
  booked_at    TEXT NOT NULL DEFAULT (datetime('now')),
  UNIQUE (departure_id, seat_number)
);

CREATE TABLE Baggage (
  booking_id  INTEGER NOT NULL REFERENCES Bookings (booking_id)
              ON DELETE CASCADE ON UPDATE CASCADE,
  baggage_seq INTEGER NOT NULL,
  weight_kg   REAL NOT NULL CHECK (weight_kg > 0 AND weight_kg <= 100),
  PRIMARY KEY (booking_id, baggage_seq)
);

CREATE TABLE Payments (
  payment_id    INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id    INTEGER NOT NULL UNIQUE REFERENCES Bookings (booking_id)
                ON DELETE CASCADE ON UPDATE CASCADE,
  amount        REAL NOT NULL CHECK (amount >= 0),
  pay_method    TEXT NOT NULL,
  pay_status    TEXT NOT NULL DEFAULT 'Pending'
                CHECK (pay_status IN ('Pending','Paid','Failed','Refunded')),
  txn_reference TEXT UNIQUE,
  paid_at       TEXT
);

CREATE TABLE Check_Ins (
  checkin_id      INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id      INTEGER NOT NULL UNIQUE REFERENCES Bookings (booking_id)
                  ON DELETE CASCADE ON UPDATE CASCADE,
  checkin_time    TEXT NOT NULL DEFAULT (datetime('now')),
  boarding_status TEXT NOT NULL DEFAULT 'Not Boarded'
                  CHECK (boarding_status IN ('Not Boarded','Boarding','Boarded','No Show'))
);
