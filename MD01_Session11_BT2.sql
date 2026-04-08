CREATE TABLE accounts
(
    account_id serial primary key,
    owner_name varchar(100),
    balance    numeric(10, 2)
);

INSERT INTO accounts(owner_name, balance)
VALUES ('A', 500),
       ('B', 300);

CREATE OR REPLACE PROCEDURE sp_TransferMoney(in p_sender_id int, in p_receiver_id int, in p_amount numeric)
    LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE accounts set balance = balance - p_amount where account_id = p_sender_id and accounts.balance >= p_amount;
    IF NOT FOUND THEN
        RAISE NOTICE 'Loi: Nguoi gui ko ton tai hoac ko du so du!';
        ROLLBACK;
        RETURN;
    end if;

    UPDATE accounts set balance = balance + p_amount where account_id = p_receiver_id;
    IF NOT FOUND THEN
        RAISE NOTICE 'Loi: Nguoi nhan ko ton tai(ID:%), dang tien hanh ROLLBACK',p_receiver_id;
        ROLLBACK;
        RETURN;
    end if;

    COMMIT;
    RAISE NOTICE 'Giao dich thanh cong!';
END;
$$;

call sp_TransferMoney(1,3,100);