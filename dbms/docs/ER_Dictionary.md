# SkyRoute ER dictionary (companion to Fig. 1)

Entity names match CREATE TABLE statements exactly.

## Airports — master list of airports served.
Key: airport_id. Columns: airport_id [PK], iata_code, airport_name, city, country
Relationships: has_terminal, departs_from, arrives_at, based_at, posted_at

## Airlines — master list of carriers.
Key: airline_id. Columns: airline_id [PK], airline_name, iata_code, country
Relationships: has_fleet, operates

## Passengers — travelers who can hold bookings.
Key: passenger_id. Columns: passenger_id [PK], first_name, last_name, passport_number, nationality, phone, email
Relationships: makes_booking

## Terminals — terminals inside airports.
Key: terminal_id. Columns: terminal_id [PK], airport_id [FK], terminal_code, terminal_name, terminal_status
Relationships: has_terminal, contains_gate

## Aircraft — fleet with seating capacity.
Key: aircraft_id. Columns: aircraft_id [PK], tail_number, model, capacity, airline_id [FK]
Relationships: has_fleet, aircraft_assigned

## Bookings — seat reservations linking traveler and departure.
Key: booking_id. Columns: booking_id [PK], passenger_id [FK], departure_id [FK], seat_number, travel_class, price, booking_status, booked_at
Relationships: makes_booking, has_baggage, holds, has_payment, has_checkin

## Gates — boarding gates inside terminals.
Key: gate_id. Columns: gate_id [PK], terminal_id [FK], gate_number, gate_status
Relationships: contains_gate, gate_assigned

## Flights — timetable templates, one row per flight number.
Key: flight_id. Columns: flight_id [PK], flight_number, airline_id [FK], departure_airport_id [FK], arrival_airport_id [FK], sched_departure, sched_arrival, flight_status
Relationships: scheduled_as, operates, departs_from, arrives_at

## Payments — one payment record per booking.
Key: payment_id. Columns: payment_id [PK], booking_id [FK], amount, pay_method, pay_status, txn_reference, paid_at
Relationships: has_payment

## Check_Ins — boarding record per booking.
Key: checkin_id. Columns: checkin_id [PK], booking_id [FK], checkin_time, boarding_status
Relationships: has_checkin

## Baggage — weak entity: bags belonging to a booking.
Key: booking_id, baggage_seq. Columns: booking_id [PK], baggage_seq [PK], weight_kg
Relationships: has_baggage

## Departures — dated departures of timetable flights.
Key: departure_id. Columns: departure_id [PK], flight_id [FK], scheduled_departure, scheduled_arrival, actual_departure, actual_arrival, departure_status, aircraft_id [FK], gate_id [FK]
Relationships: scheduled_as, aircraft_assigned, holds, gate_assigned

## Pilots — licensed pilots (role table).
Key: employee_id. Columns: employee_id [PK], license_number, license_type
Relationships: has_pilot

## Employees — staff base records.
Key: employee_id. Columns: employee_id [PK], full_name, email, phone, base_airport [FK], hire_date
Relationships: based_at, has_pilot, has_ground

## Ground_Staff — airport ground roles (role table).
Key: employee_id. Columns: employee_id [PK], ground_role, airport_id [FK]
Relationships: posted_at, has_ground, has_crew

## Crew_Members — cabin-crew roles (role table).
Key: employee_id. Columns: employee_id [PK], crew_role
Relationships: has_crew

## Relationships

| Relationship | Ends (cardinality) |
|---|---| 
| has_terminal | Airports (1) — Terminals (N) |
| contains_gate | Terminals (1) — Gates (N) |
| has_fleet | Airlines (1) — Aircraft (N) |
| scheduled_as | Flights (1) — Departures (N) |
| makes_booking | Passengers (1) — Bookings (N) |
| has_baggage | Bookings (1) — Baggage (N) |
| operates | Airlines (1) — Flights (N) |
| aircraft_assigned | Aircraft (1) — Departures (0..N) |
| holds | Bookings (1) — Departures (N) |
| departs_from | Airports (1) — Flights (N) |
| arrives_at | Airports (1) — Flights (N) |
| gate_assigned | Gates (1) — Departures (0..N) |
| based_at | Airports (1) — Employees (0..N) |
| posted_at | Airports (1) — Ground_Staff (0..N) |
| has_payment | Bookings (1) — Payments (1) |
| has_checkin | Bookings (1) — Check_Ins (0..1) |
| has_pilot | Pilots (1) — Employees (1) |
| has_ground | Employees (1) — Ground_Staff (1) |
| has_crew | Ground_Staff (1) — Crew_Members (1) |
