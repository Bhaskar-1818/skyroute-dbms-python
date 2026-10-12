-- ============================================================================
-- SkyRoute : Airline Booking, Baggage & Staff Operations System (multi-airport) — SCHEMA v2
-- File 01 : travel-core schema  (MySQL 8.0, InnoDB, utf8mb4)
-- Run from dbms/ :  mysql -u root -p  ->  SOURCE schema/01-travel-core.sql;
-- Order : 01 -> 02-staff-roles.sql -> seed -> queries -> advanced
-- v2 changes: Flight_Instances renamed Departures (same concept, plain name),
--             Runways table removed (gate + terminal cover the clash story).
-- Decisions C1..C9 are viva answers. Learn them.
-- ============================================================================

DROP DATABASE IF EXISTS skyroute_db;
CREATE DATABASE skyroute_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE skyroute_db;

-- C1: Airports is the root master table. iata_code is the real-world business
-- key (UNIQUE) but the PK is a surrogate integer so every FK stays small and
-- fast no matter how many airports we add later.
CREATE TABLE Airports (
  airport_id   INT AUTO_INCREMENT PRIMARY KEY,
  iata_code    CHAR(3) NOT NULL,
  airport_name VARCHAR(100) NOT NULL,
  city         VARCHAR(50) NOT NULL,
  country      VARCHAR(50) NOT NULL DEFAULT 'India',
  UNIQUE KEY uq_airports_iata (iata_code),
  UNIQUE KEY uq_airports_name (airport_name)
) ENGINE=InnoDB;

-- C2: Airline and Aircraft are separate masters, not free-text columns.
-- A free-text airline_name inside Flights can never answer "all aircraft of
-- IndiGo" reliably. Masters make it a JOIN instead of a guess.
CREATE TABLE Airlines (
  airline_id   INT AUTO_INCREMENT PRIMARY KEY,
  airline_name VARCHAR(80) NOT NULL,
  iata_code    CHAR(2) NOT NULL,
  country      VARCHAR(50) NOT NULL DEFAULT 'India',
  UNIQUE KEY uq_airlines_name (airline_name),
  UNIQUE KEY uq_airlines_iata (iata_code)
) ENGINE=InnoDB;

CREATE TABLE Aircraft (
  aircraft_id INT AUTO_INCREMENT PRIMARY KEY,
  tail_number VARCHAR(12) NOT NULL,
  model       VARCHAR(60) NOT NULL,
  capacity    INT NOT NULL CHECK (capacity > 0 AND capacity <= 850),
  airline_id  INT NOT NULL,
  UNIQUE KEY uq_aircraft_tail (tail_number),
  CONSTRAINT fk_aircraft_airline FOREIGN KEY (airline_id)
    REFERENCES Airlines (airline_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- C3: A Flight is the TIMETABLE template (e.g. "6E-501 flies HYD->BLR daily at
-- 08:00"). One row here can own unlimited dated departures. This split is what
-- lets the system hold "as many flights as possible".
-- C4: departure AND arrival airports. A CHECK cannot guard this pair: MySQL
-- rejects a CHECK on any column that also carries a FOREIGN KEY referential
-- action (ERROR 3823), and these columns do. The trigger below makes a
-- HYD->HYD nonsense row impossible at the database level instead.
CREATE TABLE Flights (
  flight_id            INT AUTO_INCREMENT PRIMARY KEY,
  flight_number        VARCHAR(10) NOT NULL,
  airline_id           INT NOT NULL,
  departure_airport_id INT NOT NULL,
  arrival_airport_id   INT NOT NULL,
  sched_departure      TIME NOT NULL,
  sched_arrival        TIME NOT NULL,
  flight_status        ENUM('Active','Suspended') NOT NULL DEFAULT 'Active',
  UNIQUE KEY uq_flights_number (flight_number),
  CONSTRAINT fk_flights_airline   FOREIGN KEY (airline_id)
    REFERENCES Airlines (airline_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  -- C5: RESTRICT on airports, deliberately NOT cascade. Deleting an airport
  -- must never silently wipe out flights. The DB refuses until an admin moves
  -- the flights first. Safety over convenience for root masters.
  CONSTRAINT fk_flights_departure FOREIGN KEY (departure_airport_id)
    REFERENCES Airports (airport_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_flights_arrival   FOREIGN KEY (arrival_airport_id)
    REFERENCES Airports (airport_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

DELIMITER $$
CREATE TRIGGER trg_flights_route BEFORE INSERT ON Flights
FOR EACH ROW
BEGIN
  IF NEW.departure_airport_id = NEW.arrival_airport_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Route must differ: same-airport flight refused';
  END IF;
END$$
CREATE TRIGGER trg_flights_route_upd BEFORE UPDATE ON Flights
FOR EACH ROW
BEGIN
  IF NEW.departure_airport_id = NEW.arrival_airport_id THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Route must differ: same-airport flight refused';
  END IF;
END$$
DELIMITER ;

-- C6: Terminal -> Gate hang under one Airport. The composite UNIQUE keys are
-- the schema-level answer to gate clashes: two rows can never claim the same
-- physical gate of the same terminal.
CREATE TABLE Terminals (
  terminal_id   INT AUTO_INCREMENT PRIMARY KEY,
  airport_id    INT NOT NULL,
  terminal_code VARCHAR(4) NOT NULL,
  terminal_name VARCHAR(100) NOT NULL,
  terminal_status ENUM('Operational','Under Construction','Closed')
    NOT NULL DEFAULT 'Operational',
  UNIQUE KEY uq_terminal (airport_id, terminal_code),
  CONSTRAINT fk_terminal_airport FOREIGN KEY (airport_id)
    REFERENCES Airports (airport_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Gates (
  gate_id     INT AUTO_INCREMENT PRIMARY KEY,
  terminal_id INT NOT NULL,
  gate_number VARCHAR(6) NOT NULL,
  gate_status ENUM('Open','Closed','Maintenance') NOT NULL DEFAULT 'Open',
  UNIQUE KEY uq_gate (terminal_id, gate_number),
  CONSTRAINT fk_gate_terminal FOREIGN KEY (terminal_id)
    REFERENCES Terminals (terminal_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- C7: Departures holds ONE dated departure of a Flight: "6E-501 on Nov 3,
-- boards 08:00 at gate G2". Actual times start NULL and get filled in by
-- operations, plus the aircraft and gate actually assigned that day. Status is
-- a closed ENUM so junk values cannot enter.
CREATE TABLE Departures (
  departure_id        INT AUTO_INCREMENT PRIMARY KEY,
  flight_id           INT NOT NULL,
  scheduled_departure DATETIME NOT NULL,
  scheduled_arrival   DATETIME NOT NULL,
  actual_departure    DATETIME NULL,
  actual_arrival      DATETIME NULL,
  departure_status    ENUM('Scheduled','Boarding','Departed','Arrived','Delayed','Cancelled')
    NOT NULL DEFAULT 'Scheduled',
  aircraft_id INT NULL,
  gate_id     INT NULL,
  UNIQUE KEY uq_departure (flight_id, scheduled_departure),
  CONSTRAINT fk_departure_flight   FOREIGN KEY (flight_id)
    REFERENCES Flights (flight_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_departure_aircraft FOREIGN KEY (aircraft_id)
    REFERENCES Aircraft (aircraft_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_departure_gate     FOREIGN KEY (gate_id)
    REFERENCES Gates (gate_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_departure_times CHECK (scheduled_arrival > scheduled_departure)
) ENGINE=InnoDB;

CREATE TABLE Passengers (
  passenger_id    INT AUTO_INCREMENT PRIMARY KEY,
  first_name      VARCHAR(60) NOT NULL,
  last_name       VARCHAR(60) NOT NULL,
  passport_number VARCHAR(20) NULL,
  nationality     VARCHAR(50) NOT NULL DEFAULT 'India',
  phone           VARCHAR(20) NOT NULL,
  email           VARCHAR(100) NOT NULL,
  UNIQUE KEY uq_passenger_passport (passport_number),
  UNIQUE KEY uq_passenger_email (email)
) ENGINE=InnoDB;

-- C8: UNIQUE(departure_id, seat_number) kills double seat booking inside the
-- database itself (problem statement #1). No application code needed; even a
-- buggy app cannot insert a duplicate because the storage engine refuses.
CREATE TABLE Bookings (
  booking_id   INT AUTO_INCREMENT PRIMARY KEY,
  passenger_id INT NOT NULL,
  departure_id INT NOT NULL,
  seat_number  VARCHAR(5) NOT NULL,
  travel_class ENUM('Economy','Premium Economy','Business','First') NOT NULL DEFAULT 'Economy',
  price        DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  booking_status ENUM('Pending','Confirmed','Cancelled','Refunded')
    NOT NULL DEFAULT 'Confirmed',
  booked_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_booking_seat (departure_id, seat_number),
  CONSTRAINT fk_booking_passenger FOREIGN KEY (passenger_id)
    REFERENCES Passengers (passenger_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_booking_departure FOREIGN KEY (departure_id)
    REFERENCES Departures (departure_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- C9: Baggage is a WEAK entity: no booking, no baggage. So it has no
-- independent id; its PK is (booking_id + sequence). Deleting a booking wipes
-- its bags via CASCADE, which is exactly the real-world semantics.
CREATE TABLE Baggage (
  booking_id  INT NOT NULL,
  baggage_seq INT NOT NULL,
  weight_kg   DECIMAL(5,2) NOT NULL CHECK (weight_kg > 0 AND weight_kg <= 100),
  PRIMARY KEY (booking_id, baggage_seq),
  CONSTRAINT fk_baggage_booking FOREIGN KEY (booking_id)
    REFERENCES Bookings (booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Payments (
  payment_id    INT AUTO_INCREMENT PRIMARY KEY,
  booking_id    INT NOT NULL,
  amount        DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  pay_method    ENUM('UPI','Credit Card','Debit Card','Net Banking','Cash') NOT NULL,
  pay_status    ENUM('Pending','Paid','Failed','Refunded') NOT NULL DEFAULT 'Pending',
  txn_reference VARCHAR(50) NULL,
  paid_at       DATETIME NULL,
  UNIQUE KEY uq_payment_booking (booking_id),
  UNIQUE KEY uq_payment_txn (txn_reference),
  CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id)
    REFERENCES Bookings (booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Check_Ins (
  checkin_id      INT AUTO_INCREMENT PRIMARY KEY,
  booking_id      INT NOT NULL,
  checkin_time    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  boarding_status ENUM('Not Boarded','Boarding','Boarded','No Show')
    NOT NULL DEFAULT 'Not Boarded',
  UNIQUE KEY uq_checkin_booking (booking_id),
  CONSTRAINT fk_checkin_booking FOREIGN KEY (booking_id)
    REFERENCES Bookings (booking_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;
