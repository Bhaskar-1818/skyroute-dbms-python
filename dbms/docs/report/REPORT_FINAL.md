ICFAI FOUNDATION FOR HIGHER EDUCATION
Faculty of Science & Technology
B.Tech. Computer Science and Engineering

DATABASE MANAGEMENT SYSTEMS - MINI PROJECT REPORT

SkyRoute: Airline Booking, Baggage & Staff Operations System

Submitted by
D.Sivasai Bhaskar Sarma
Roll Number: 25STUCHH010868        Section: D

Course: CS/AI/AIM/DS202
Semester III, First Semester, A.Y. 2026-27
Course Instructor: Dr. Meena Kumari Parigi

--- PAGE BREAK ---

# SkyRoute: Airline Booking, Baggage & Staff Operations System
### DBMS Mini Project - Database Management System (CS/AI/AIM/DS202)

## Abstract

Booking a seat at an airline counter still runs on a printed seat chart, a whiteboard for gates, and a calculator for excess baggage. Two agents can sell the same seat within the same minute. Two flights can be given the same gate. The fee depends on who is at the counter, and each station keeps a passenger list that the other station cannot see.

SkyRoute puts the whole operation into one MySQL database: five airports, three airlines, sixteen scheduled flights and 336 dated departures. The design separates a timetable flight from the dated departure it produces, so one schedule row owns as many departures as the calendar needs. Staff sit in a shared employee table, with three role tables hanging off the same key.

The rules that used to sit in people's heads now sit in the database. A unique key stops the double sale. A trigger stops the oversold flight. A check stops the negative price. The baggage fee is a view, so every receipt adds up the same way. A stored procedure books the seat and opens the payment in one transaction.

By the end of the build the database held 34,708 bookings, 43,314 bags and 4,000 passengers, and each rule was tested against that data rather than against three sample rows.

## Step 1: Title Selection

The title names the three things the system does: bookings, baggage and staff operations. It avoids "Airport Management System", a phrase that could mean anything from runway maintenance to retail concessions, and it avoids the single-route shuttle framing as well.

The subtitle carried through the report is "one database for every station", which is the point of the project in five words.

## Step 2: Problem Statement

The work started from the booking counters at Hyderabad (HYD) and Bengaluru (BLR). Seat charts were printed per flight. Gate changes went on a whiteboard. Baggage fees were worked out by hand, and each station kept its own passenger list.

Five failures follow from that, and each one is closed by a mechanism described later in this report.

1. Two agents sell the same seat. Nothing serialises them, so the second sale overwrites the first. Closed by a unique key on (departure_id, seat_number), with the capacity trigger as a second guard.
2. Two flights are given the same gate. The clash is written on a whiteboard and nobody checks it. Closed by a unique key on (terminal_id, gate_number), so a physical gate is one row.
3. Baggage fees come out differently depending on who is at the counter. Closed by moving the rule into a view: 20 kg free per bag, Rs 500 for each kilo above that.
4. Passenger lists disagree between stations. Closed by one database for all five airports, with airports as the root table.
5. A flight sells more seats than the aircraft holds. Closed by a before-insert trigger that counts the seats already sold and refuses the next row with SQLSTATE 45000.

## Step 3: Objectives

- Schedule flights and allocate gates across five airports from one database.
- Make a double sale and an oversold flight impossible inside the database, whichever application writes the row.
- Compute the baggage fee from weighed kilograms, in the same way on every receipt.
- Answer the departure board, manifest, revenue, load factor and gate utilisation questions with one query each.
- Give the three staff roles only the access they need, and check that against the live grant tables.
- Measure the cost of the four busiest query patterns before and after indexing.
- Carry the same design into a Flask application with working create, read, update and delete.

## Step 4: Requirements Gathering

The system adds, edits and views airports, airlines, aircraft, timetable flights and dated departures. It assigns an aircraft and a gate to each departure, sells seats, records bag weights, takes payments, checks passengers in, and manages staff records.

It also has to stay responsive at tens of thousands of rows, keep seat allocation correct when two sellers act at once, and follow least privilege for the three roles.

Three things were left out on purpose. Crew rostering is a scheduling problem, so staff exist as records and daily assignment belongs to the application. Runways are not modelled separately, because gate and terminal already carry the clash story. Fares are stored per booking rather than computed, since revenue is reported and not priced.

The model also assumes one currency (INR), one time zone (IST) and single-leg itineraries. Codeshares are out of scope, so a flight belongs to exactly one airline. These are stated because each one would change the schema if it were relaxed.

## Step 5: Entity-Relationship Modeling

Sixteen entities cover the operation: Airport, Airline, Aircraft, Flight, Departure, Terminal, Gate, Passenger, Booking, Baggage, Payment, Check_In, Employees, Pilots, Crew_Members and Ground_Staff. Baggage is drawn as a weak entity, because a bag has no identity outside its booking.

- Airline 1-N Aircraft. A fleet belongs to one airline.
- Flight N-1 Airports, twice: once as departure, once as arrival.
- Flight 1-N Departures. The timetable row is the template, the departure is a date.
- Airport 1-N Terminals, Terminal 1-N Gates.
- Passenger 1-N Bookings N-1 Departures. A booking resolves one passenger onto one departure and carries seat, class and price.
- Booking 1-N Baggage, through an identifying relationship.
- Booking 1-1 Payment, and 1-1 Check_In.
- Employees 1-1 each role table on the shared key, so a licence row cannot exist without its employee.

Keys, cardinality and participation were settled on the diagram before any CREATE TABLE was written. The notation is Chen: rectangles for entities, diamonds for relationships, ovals for attributes, and double borders for the weak entity and its identifying relationship.

Two relationships carry most of the traffic. A booking sits between one passenger and one departure, and it is where seat, class and price are stored, so the same passenger can fly twice without their details being copied. Baggage hangs off that booking through a weak relationship and is numbered per booking, which is why bag 2 of booking 817 cannot exist once booking 817 is gone.

The diagram was drawn once and then left alone. Every later change to the schema was checked against it first, so the tables follow the model rather than the model being redrawn to match the tables.

## Step 6: Schema Design (Relational Model)

The ER model becomes sixteen tables. Surrogate integer keys keep the foreign keys narrow. Business keys such as IATA codes, tail numbers, emails and transaction references carry UNIQUE constraints instead of serving as primary keys.

Master tables are referenced, never copied, so an airline name appears once rather than in every flight row. That single choice removes most of the update anomalies before they can happen.

Normalisation was checked against one flat booking sheet: passenger name, passport, flight number, departure date, seat, class, price, bag tag, bag weight and fee, all on a single row.

- 1NF: a booking with two bags repeats the tag and the weight, so those columns move to Baggage, keyed by (booking_id, baggage_seq).
- 2NF: passenger details depend on the passenger, not on the pair (passenger, departure), so Passengers splits out.
- 3NF: city depends on the airport, and the airline name depends on the airline, so neither belongs on a booking row.
- BCNF: every determinant that remains is a key, which the unique constraints enforce.

What is left is sixteen tables and nineteen foreign keys, with no repeating group and no transitive dependency.

The rules attached to the tables:

- CASCADE where a child cannot outlive its parent. Bookings, bags and payments disappear with a deleted departure.
- RESTRICT on airports, so a timetable flight is never silently wiped out.
- SET NULL on optional assignments, so removing an aircraft unassigns it rather than deleting history.
- ENUMs for statuses, classes, methods and roles.
- CHECKs for capacity ranges, non-negative prices, weights up to 100 kg, and arrival after departure.

## Step 7: SQL Implementation

The schema was built in two passes. The first pass created the twelve travel tables, the second created the four staff tables and the three database users. Every constraint from the previous step appears in the CREATE statements.

Access control is part of the schema rather than an afterthought. sky_admin has full rights, sky_staff can read and write, and sky_viewer can only read. Each grant is checked with SHOW GRANTS against the exact database name, because a grant on a misspelled name succeeds and protects nothing.

![[Screenshot 2026-10-21 223843.png]]

The booking table carries three rules at once: a unique key on the departure and seat pair, a check that the price is not negative, and two foreign keys that point at real passengers and real departures. When the same seat is sold twice, the database refuses the second row and names the constraint that stopped it.

![[Screenshot 2026-10-21 222750.png]]

```sql
CREATE TABLE Bookings (
  booking_id     INT AUTO_INCREMENT PRIMARY KEY,
  passenger_id   INT NOT NULL,
  departure_id   INT NOT NULL,
  seat_number    VARCHAR(5) NOT NULL,
  travel_class   ENUM('Economy','Business','First') NOT NULL,
  price          DECIMAL(10,2) NOT NULL CHECK (price >= 0),
  booking_status ENUM('Confirmed','Cancelled','Refunded') DEFAULT 'Confirmed',
  booked_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_booking_seat (departure_id, seat_number),
  FOREIGN KEY (passenger_id) REFERENCES Passengers(passenger_id),
  FOREIGN KEY (departure_id) REFERENCES Departures(departure_id)
);
GRANT SELECT, INSERT, UPDATE ON skyroute_db.* TO 'sky_staff'@'localhost';
REVOKE INSERT, UPDATE ON skyroute_db.* FROM 'sky_staff'@'localhost';
CREATE INDEX idx_bookings_status ON Bookings (booking_status);
```

The seed was generated with seed 42. It builds five airports, three airlines, sixteen routes, twenty-one days of departures and four thousand passengers. Bookings sit between 35 and 80 per cent load, with seats sampled without replacement.

Payments are 92 per cent settled. Baggage averages about 1.2 bags per booking, split 80/20 around the 20 kg allowance. Check-ins cover seventy per cent of past departures. The seed is checked before loading: no duplicate seat pair, and every foreign key inside its parent range.

One row shows how the pieces fit. Booking 38 is Riya Mehta, seat 10C on 6E-501 from HYD to BLR on 1 November 2026, Business class, Rs 13,879, two bags of 11.23 kg and 7.46 kg, paid by UPI. Nothing in that sentence is stored twice: the passenger is one row in Passengers, the route is one row in Flights, and the bags are two rows in Baggage keyed by (38, 1) and (38, 2).

The Flask application uses a second database that holds the twelve operational tables and none of the staff tables. Table names, keys and rules are identical. The application simply never touches HR data.

## Step 8: Advanced SQL Features

Two views carry the application's read paths. The departure board view joins the timetable to both airport roles, the airline, the aircraft, the gate and the terminal, so the board is one query.

The receipt view returns the price plus the computed baggage fee through a scalar subquery, which keeps it valid under ONLY_FULL_GROUP_BY.

```sql
CREATE OR REPLACE VIEW booking_receipt_view AS
SELECT b.booking_id,
       CONCAT(p.first_name, ' ', p.last_name) AS passenger,
       f.flight_number, d.scheduled_departure,
       b.seat_number, b.travel_class, b.price, b.booking_status,
       pay.pay_status,
       COALESCE(
         (SELECT SUM(GREATEST(weight_kg - 20, 0)) * 500
          FROM Baggage WHERE booking_id = b.booking_id), 0
       ) AS baggage_fee_rs
FROM Bookings b
JOIN Passengers p ON b.passenger_id = p.passenger_id
JOIN Departures d ON b.departure_id = d.departure_id
JOIN Flights f    ON d.flight_id = f.flight_id
LEFT JOIN Payments pay ON b.booking_id = pay.booking_id;
```

The join queries answer the questions the desk asks every day. The first joins five tables to print a flight schedule with both airport names, the airline and the aircraft.

![[Screenshot 2026-10-21 214245.png]]

A LEFT JOIN keeps bookings that have no bags or no check-in, so a missing child row never hides a real booking. The counts come back as zero rather than dropping the row.

![[Screenshot 2026-10-21 214304.png]]

The three staff role tables share the employee key, so one join lists pilots, cabin crew and ground staff in a single directory without a union.

![[Screenshot 2026-10-21 214328.png]]

The analytics side starts with the simplest question: which route sells the most seats. MAA to BOM leads with 2,688 bookings.

![[Screenshot 2026-10-21 222504.png]]

Load factor is seats sold divided by aircraft capacity, grouped by flight. The HAVING clause keeps only the flights below sixty per cent, which is where the airline would look first.

![[Screenshot 2026-10-21 222616.png]]

The baggage fee report sums the excess weight per booking and multiplies by the rate. It finds 8,704 overweight bags and Rs 2,69,74,740 in fees across the seeded data.

![[Screenshot 2026-10-21 222646.png]]

A correlated subquery returns the passengers who spend more than the average fare. It is the one place where a per-row subquery earns its cost, because the average is computed once.

![[Screenshot 2026-10-21 222721.png]]

MakeBooking(passenger, departure, seat, class, price, OUT id) writes the booking and opens its Pending payment in one transaction. An EXIT HANDLER rolls back and re-signals on any error, so a taken seat fails the whole call and leaves nothing behind.

![[Screenshot 2026-10-21 222852.png]]

The capacity trigger fires before every insert on Bookings, whether the row comes from the shell, the procedure or the web application. It counts seats sold against the aircraft capacity and signals SQLSTATE 45000 when the flight is full.

```sql
CREATE TRIGGER trg_booking_capacity
BEFORE INSERT ON Bookings
FOR EACH ROW
BEGIN
  DECLARE sold INT DEFAULT 0;
  DECLARE cap  INT DEFAULT NULL;
  SELECT COUNT(*) INTO sold FROM Bookings WHERE departure_id = NEW.departure_id;
  SELECT a.capacity INTO cap
  FROM Departures d JOIN Aircraft a ON d.aircraft_id = a.aircraft_id
  WHERE d.departure_id = NEW.departure_id;
  IF cap IS NOT NULL AND sold >= cap THEN
    SIGNAL SQLSTATE '45000'
      SET MESSAGE_TEXT = 'Booking refused: flight is fully booked';
  END IF;
END
```

![[Screenshot 2026-10-21 222926.png]]

Load factor, revenue, gate utilisation and fee revenue only mean something at volume. On three rows they are arithmetic. On thirty thousand they are the report.

## Step 9: Transaction Management

Three transaction scenarios were run against the live database. Each one starts from a known state and ends by restoring it.

- Demo A commits a booking and its payment together. Both rows appear, or neither does.
- Demo B inserts a passenger, then a second passenger with the same passport number. The second insert breaks UNIQUE and the rollback removes the first row. A count afterwards returns zero.

![[Screenshot 2026-10-21 223031.png]]

- Demo C needs two sessions. The first holds a row with SELECT ... FOR UPDATE, and the second's UPDATE waits. When the first rolls back, the second completes, which proves the lock was real.

![[zz-lock-wait.png]]

Reading the row again before commit returns the old value. That is isolation, not a definition of it. The second session sees the old value until the first one commits or rolls back.

## Step 10: Indexing and Optimization

MySQL already indexes single-column foreign keys, so those were left alone. Four indexes were added for four observed workloads.

- booking_status, because every operations query filters on refunds and pending payments.
- scheduled_departure, because the departure board searches by date range.
- (last_name, first_name), because desk staff look passengers up by family name.
- weight_kg, because the fee report is a range over twenty kilograms.

Each one is tested the same way: EXPLAIN before the index, read the access type and row estimate, create the index, then EXPLAIN again.

The booking-status pair is the clearest. The query uses the index over 5,449 rows, falls to a full scan of 33,904 rows when the index is dropped, and returns to the index once it is rebuilt.

![[zz-step10-index.png]]

The other three indexes follow the same pattern, and each one is listed by SHOW INDEX with the columns in the order the query needs them.

## Step 11: Testing and Validation

Twenty-four checks were run in eight groups. Each check states its expected result before it runs, so the log works as a protocol as well as evidence.

- Joins (J1-J10): ten clean result sets; the LEFT JOIN keeps bookings with no bags; the overweight list is non-empty by construction.
- Analytics (A1-A8): routes match the scheduled frequencies; every load factor sits between 35 and 80 per cent; fee revenue is positive.
- Constraints (C-a to C-e): a duplicate seat gives ERROR 1062, a same-airport flight gives ERROR 1644, a zero-weight bag is refused, deleting an airport gives ERROR 1451, and deleting a booking removes its bag, payment and check-in.
- Procedure and trigger (T-a to T-c): MakeBooking returns an id with a Pending payment, a second call on the same seat inserts nothing, and a booking past capacity raises ERROR 45000.
- Transactions (D-A to D-C): commit keeps both rows, rollback frees the seat, and a second session sees the old value.
- Indexes (I-a, I-b): EXPLAIN pairs captured, and SHOW INDEX lists exactly the four new indexes.
- Access control (R-a to R-c): the three grants match the three roles, the viewer is refused an INSERT, and grant names are character exact.
- Scale (S-a, S-b): 336 departures with bookings and bags in the tens of thousands, and the daily snapshot covers all twenty-one days.

The constraint checks are the ones that matter most, because they prove the database refuses bad data rather than merely storing whatever it is given. The row counts afterwards show that each refusal left the data exactly as it was.

![[Screenshot 2026-10-21 222956.png]]

At the end of the run the six largest tables hold the volumes the generator promised: 336 departures, 34,708 bookings, 43,314 bags and 4,000 passengers.

![[Screenshot 2026-10-21 223914.png]]

The checks stop where the application begins. Two people booking at the same instant are covered only by the row-lock demo, and restore from backup is not tested at all. Both would need a second host and a second database to do properly.

## Step 12: Documentation

This report follows the thirteen project steps in order. Each step says what was built and, where a choice mattered, why it beat the obvious alternative.

The ER diagram and the schema diagram are reproduced in full rather than cropped, and every query result used as evidence is a screenshot with a caption naming the point it proves.

## Step 13: Presentation and Reporting

The deck runs to eleven slides: the problem, the mechanism that answers each failure, the ER model, the schema, the data at volume, the advanced SQL, the transactions, the index measurements, access control and the Flask screen. Each mechanism slide names the check that proves it, so the deck cannot claim more than the tests show.

The demonstration keeps the same order as the report. It opens the departure board, books a seat through the procedure, attempts the same seat a second time to show the refusal, drops an index to show the plan change, and finishes on a receipt with the fee worked out.

## Future work

- Partition Bookings by departure month once the table passes a few million rows, so the board query reads one partition instead of the whole table.
- Replace the capacity trigger with a seat-counter row per departure, updated in the same transaction as the booking.
- Move the fee rule into a stored function, so the receipt view and the application call the same code.
- Give the staff tables their own schema and user, so HR data never shares a grant with the travel tables.

Each item is additive. None of them requires the booking, baggage or payment tables to be rebuilt.

## Conclusion

Each item in the problem statement is answered by a mechanism that can be pointed at, and each mechanism has a test with a stated expectation behind it. The database holds production-shaped volume while answering board, manifest, revenue and load questions in single queries.

The Flask application reuses the same tables through mysql-connector-python: a staff portal with PIN-gated manifests, check-ins and edits, plus a traveller login restricted to their own bookings. Both screens go through the same views and the same procedure, so a change made at the desk appears on the traveller page without a second code path.

Two limits are worth stating. Bookings are not partitioned by date, so the table will need range partitioning around the point it passes a few million rows. The capacity trigger also counts rows on every insert, which is fine at 34,708 bookings but would become a seat inventory counter under heavier load.

At 34,708 bookings the difference between a good plan and a bad one shows up in milliseconds rather than in correctness. The query returns the same rows either way. What changes is how many rows the engine has to read to find them, and that is the whole point of the index measurements in Step 10.
