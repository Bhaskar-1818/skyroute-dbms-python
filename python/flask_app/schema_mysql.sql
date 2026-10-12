-- SkyRoute Flask demo : MySQL 8.0 schema (mysql-connector-python, no ORM).
-- Same 12-table design as schema_sqlite.sql: Departures (dated departures),
-- no runways, no crew assignments. Created inside the app database by
-- seed_mysql.py (DROP + CREATE per reseed). ENUM -> VARCHAR + CHECK.
CREATE TABLE Airports (
  airport_id   INT AUTO_INCREMENT PRIMARY KEY,
  iata_code    VARCHAR(8) NOT NULL,
  airport_name VARCHAR(120) NOT NULL,
  city         VARCHAR(80) NOT NULL,
  country      VARCHAR(80) NOT NULL DEFAULT 'India',
  UNIQUE (iata_code),
  UNIQUE (airport_name)
);

CREATE TABLE Airlines (
  airline_id   INT AUTO_INCREMENT PRIMARY KEY,
  airline_name VARCHAR(80) NOT NULL,
  iata_code    VARCHAR(8) NOT NULL,
  country      VARCHAR(80) NOT NULL DEFAULT 'India',
  UNIQUE (airline_name),
  UNIQUE (iata_code)
);

CREATE TABLE Aircraft (
  aircraft_id INT AUTO_INCREMENT PRIMARY KEY,
  tail_number VARCHAR(16) NOT NULL,
  model       VARCHAR(80) NOT NULL,
  capacity    INT NOT NULL CHECK (capacity > 0 AND capacity <= 850),
  airline_id  INT NOT NULL,
  UNIQUE (tail_number),
  FOREIGN KEY (airline_id) REFERENCES Airlines (airline_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Flights (
  flight_id            INT AUTO_INCREMENT PRIMARY KEY,
  flight_number        VARCHAR(16) NOT NULL,
  airline_id           INT NOT NULL,
  departure_airport_id INT NOT NULL,
  arrival_airport_id   INT NOT NULL,
  sched_departure      VARCHAR(16) NOT NULL,
  sched_arrival        VARCHAR(16) NOT NULL,
  flight_status        VARCHAR(16) NOT NULL DEFAULT 'Active'
                       CHECK (flight_status IN ('Active','Suspended')),
  UNIQUE (flight_number),
  -- No CHECK on departure_airport_id <> arrival_airport_id: MySQL rejects a
  -- CHECK on any column that also carries a FOREIGN KEY referential action.
  -- The same-airport guard lives in the admin form + test suite instead.
  FOREIGN KEY (airline_id) REFERENCES Airlines (airline_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (departure_airport_id) REFERENCES Airports (airport_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (arrival_airport_id) REFERENCES Airports (airport_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Terminals (
  terminal_id   INT AUTO_INCREMENT PRIMARY KEY,
  airport_id    INT NOT NULL,
  terminal_code VARCHAR(8) NOT NULL,
  terminal_name VARCHAR(80) NOT NULL,
  UNIQUE (airport_id, terminal_code),
  FOREIGN KEY (airport_id) REFERENCES Airports (airport_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Gates (
  gate_id     INT AUTO_INCREMENT PRIMARY KEY,
  terminal_id INT NOT NULL,
  gate_number VARCHAR(8) NOT NULL,
  gate_status VARCHAR(16) NOT NULL DEFAULT 'Open'
              CHECK (gate_status IN ('Open','Closed','Maintenance')),
  UNIQUE (terminal_id, gate_number),
  FOREIGN KEY (terminal_id) REFERENCES Terminals (terminal_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Departures (
  departure_id        INT AUTO_INCREMENT PRIMARY KEY,
  flight_id           INT NOT NULL,
  scheduled_departure DATETIME NOT NULL,
  scheduled_arrival   DATETIME NOT NULL,
  departure_status    VARCHAR(16) NOT NULL DEFAULT 'Scheduled'
                      CHECK (departure_status IN
                        ('Scheduled','Boarding','Departed','Arrived','Delayed','Cancelled')),
  aircraft_id INT,
  gate_id     INT,
  UNIQUE (flight_id, scheduled_departure),
  CHECK (scheduled_arrival > scheduled_departure),
  FOREIGN KEY (flight_id) REFERENCES Flights (flight_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (aircraft_id) REFERENCES Aircraft (aircraft_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (gate_id) REFERENCES Gates (gate_id)
    ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE TABLE Passengers (
  passenger_id    INT AUTO_INCREMENT PRIMARY KEY,
  first_name      VARCHAR(60) NOT NULL,
  last_name       VARCHAR(60) NOT NULL,
  passport_number VARCHAR(24),
  nationality     VARCHAR(60) NOT NULL DEFAULT 'India',
  phone           VARCHAR(24) NOT NULL,
  email           VARCHAR(120) NOT NULL,
  UNIQUE (passport_number),
  UNIQUE (email)
);

CREATE TABLE Bookings (
  booking_id   INT AUTO_INCREMENT PRIMARY KEY,
  passenger_id INT NOT NULL,
  departure_id INT NOT NULL,
  seat_number  VARCHAR(8) NOT NULL,
  travel_class VARCHAR(24) NOT NULL DEFAULT 'Economy'
               CHECK (travel_class IN ('Economy','Premium Economy','Business','First')),
  price        DOUBLE NOT NULL CHECK (price >= 0),
  booking_status VARCHAR(16) NOT NULL DEFAULT 'Confirmed'
               CHECK (booking_status IN ('Pending','Confirmed','Cancelled','Refunded')),
  booked_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (departure_id, seat_number),
  FOREIGN KEY (passenger_id) REFERENCES Passengers (passenger_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (departure_id) REFERENCES Departures (departure_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Baggage (
  booking_id  INT NOT NULL,
  baggage_seq INT NOT NULL,
  weight_kg   DOUBLE NOT NULL CHECK (weight_kg > 0 AND weight_kg <= 100),
  PRIMARY KEY (booking_id, baggage_seq),
  FOREIGN KEY (booking_id) REFERENCES Bookings (booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Payments (
  payment_id    INT AUTO_INCREMENT PRIMARY KEY,
  booking_id    INT NOT NULL UNIQUE,
  amount        DOUBLE NOT NULL CHECK (amount >= 0),
  pay_method    VARCHAR(24) NOT NULL,
  pay_status    VARCHAR(16) NOT NULL DEFAULT 'Pending'
                CHECK (pay_status IN ('Pending','Paid','Failed','Refunded')),
  txn_reference VARCHAR(32) UNIQUE,
  paid_at       DATETIME,
  FOREIGN KEY (booking_id) REFERENCES Bookings (booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Check_Ins (
  checkin_id      INT AUTO_INCREMENT PRIMARY KEY,
  booking_id      INT NOT NULL UNIQUE,
  checkin_time    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  boarding_status VARCHAR(16) NOT NULL DEFAULT 'Not Boarded'
                  CHECK (boarding_status IN ('Not Boarded','Boarding','Boarded','No Show')),
  FOREIGN KEY (booking_id) REFERENCES Bookings (booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE
);
