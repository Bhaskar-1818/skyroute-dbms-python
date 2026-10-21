-- T4e : CASCADE proof on a throwaway booking (seeded rows are left alone).
USE skyroute_db;

INSERT INTO Bookings (passenger_id, departure_id, seat_number, travel_class, price)
VALUES (1, 2, '77Z', 'Economy', 1000.00);
SET @b = LAST_INSERT_ID();
INSERT INTO Baggage (booking_id, baggage_seq, weight_kg) VALUES (@b, 1, 10.00);
INSERT INTO Payments (booking_id, amount, pay_method, pay_status)
VALUES (@b, 1000.00, 'UPI', 'Paid');

SELECT @b AS test_booking,
       (SELECT COUNT(*) FROM Baggage  WHERE booking_id = @b) AS bags_before,
       (SELECT COUNT(*) FROM Payments WHERE booking_id = @b) AS payments_before;

DELETE FROM Bookings WHERE booking_id = @b;

SELECT (SELECT COUNT(*) FROM Baggage  WHERE booking_id = @b) AS bags_after,
       (SELECT COUNT(*) FROM Payments WHERE booking_id = @b) AS payments_after;
