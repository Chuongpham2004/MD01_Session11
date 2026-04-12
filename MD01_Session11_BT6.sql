CREATE TABLE accounts
(
    account_id SERIAL PRIMARY KEY,
    owner_name VARCHAR(100),
    balance    NUMERIC(12, 2),
    status     VARCHAR(10) DEFAULT 'ACTIVE'
);

CREATE TABLE transactions
(
    trans_id     SERIAL PRIMARY KEY,
    from_account INT REFERENCES accounts (account_id),
    to_account   INT REFERENCES accounts (account_id),
    amount       NUMERIC(12, 2),
    status       VARCHAR(20) DEFAULT 'PENDING',
    created_at   TIMESTAMP   DEFAULT NOW()
);

create or replace procedure funds_transfer(sender_id int, receiver_id int, amount_in numeric(12, 2))
    language plpgsql
as
$$
declare
    v_balance         numeric(12, 2);
    v_sender_status   varchar(10);
    v_receiver_status varchar(10);
begin
    begin
        select balance into v_balance from accounts where account_id = sender_id;
        select status into v_sender_status from accounts where account_id = sender_id;
        if v_balance < amount_in or v_sender_status != 'ACTIVE' then
            raise exception 'Id: % khong du so du hoac tai khoan ko con hoat dong',sender_id;
        end if;
        update accounts set balance = balance - amount_in where account_id = sender_id;

        select account_id into v_receiver_status from accounts where account_id = receiver_id;

        if not FOUND then
            raise exception 'Nguoi nhan: % ko ton tai',receiver_id;
        end if;
        if v_receiver_status != 'ACTIVE' then
            raise exception 'Tai khoan nguoi nhan ID: % dang bi khoa',receiver_id;
        end if;

        update accounts set balance = balance + amount_in where account_id = receiver_id;

        insert into transactions(from_account, to_account, amount, status)
        VALUES (sender_id, receiver_id, amount_in, 'COMPLETED');

    exception
        when others then
            raise;
    end;
end;
$$;