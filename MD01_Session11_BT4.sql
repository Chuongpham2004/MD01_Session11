create table accounts
(
    account_id    serial primary key,
    customer_name varchar(100),
    balance       numeric(12, 2)
);

create table transactions
(
    trans_id   serial primary key,
    account_id int,
    foreign key (account_id) references accounts (account_id),
    amount     numeric(12, 2),
    trans_type varchar(20),
    create_at  timestamp default now()
);

INSERT INTO accounts (customer_name, balance)
VALUES ('Nguyen Van A', 5000000.00),
       ('Tran Thi B', 10000000.00);

CREATE OR REPLACE PROCEDURE with_draw_money(account_id_in int, amount_in numeric(12, 2))
    language plpgsql
as
$$
declare
    v_balance numeric;
begin
    begin
        select balance into v_balance from accounts where account_id = account_id_in;
        if(v_balance < amount_in) then
            raise exception 'Khong du so du trong tai khoan: % ',account_id_in;
        end if;

        update accounts set balance = balance - amount_in where account_id = account_id_in;

        insert into transactions(account_id, amount, trans_type) VALUES
        (account_id_in,amount_in,'WITHDRAW');

        exception
            when others then
            raise;
    end;
end;
$$;

call with_draw_money(1,5000000);