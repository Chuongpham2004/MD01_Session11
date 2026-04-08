CREATE TABLE flights
(
    flight_id       serial primary key,
    flight_name     varchar(100),
    available_seats int
);

CREATE TABLE bookings
(
    booking_id    serial primary key,
    flight_id     int references flights (flight_id),
    customer_name varchar(100)
);

INSERT INTO flights(flight_name, available_seats)
VALUES ('VN123', 3),
       ('VN456', 2);

CREATE PROCEDURE sp_BookTicket(in p_flight_id int, in p_customer_name varchar(100))
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE flights
    set available_seats = available_seats - 1
    where flight_id = p_flight_id
      and flights.available_seats > 0;

    IF NOT FOUND THEN
        RAISE NOTICE 'Hết ghế rồi, đang chuẩn bị rollback....';
        ROLLBACK;
        RETURN;
    end if;

    INSERT INTO bookings(flight_id, customer_name)
    VALUES (p_flight_id, p_customer_name);

    COMMIT;
    RAISE NOTICE 'Đặt vé thành công cho khách: %',p_customer_name;
END;
$$;

call sp_BookTicket(1, 'Nguyễn Văn A');