CREATE TABLE customers
(
    customer_id SERIAL PRIMARY KEY,
    name        VARCHAR(100),
    balance     NUMERIC(12, 2)
);


CREATE TABLE products
(
    product_id SERIAL PRIMARY KEY,
    name       VARCHAR(100),
    stock      INT,
    price      NUMERIC(10, 2)
);


CREATE TABLE orders
(
    order_id     SERIAL PRIMARY KEY,
    customer_id  INT REFERENCES customers (customer_id),
    total_amount NUMERIC(12, 2),
    created_at   TIMESTAMP   DEFAULT NOW(),
    status       VARCHAR(20) DEFAULT 'PENDING'
);


CREATE TABLE order_items
(
    item_id    SERIAL PRIMARY KEY,
    order_id   INT REFERENCES orders (order_id),
    product_id INT REFERENCES products (product_id),
    quantity   INT,
    subtotal   NUMERIC(10, 2)
);


INSERT INTO customers (name, balance)
VALUES ('Phan Hoang Chuong', 5000000.00),
       ('Nguyen Van A', 10000000.00);


INSERT INTO products (name, stock, price)
VALUES ('Bàn phím cơ', 50, 1500000.00),
       ('Chuột Gaming', 20, 800000.00),
       ('Màn hình 24 inch', 10, 3000000.00);

create or replace procedure create_orders(cus_id int, pro1_id int, pro2_id int, quant_1 int, quant_2 int)
    language plpgsql
as
$$
declare
    v_balance      numeric(12, 2);
    v_price_1      numeric(10, 2);
    v_price_2      numeric(10, 2);
    v_total_amount numeric(12, 2) := 0;
    v_order_id     int;
begin
    select balance into v_balance from customers where customer_id = cus_id;
    insert into orders(customer_id, total_amount)
    values (cus_id, v_total_amount)
    returning order_id into v_order_id;
    begin
        update products
        set stock = stock - quant_1
        where product_id = pro1_id
          and stock >= quant_1
        returning price into v_price_1;
        if not FOUND then
            raise exception 'San pham ID: % het hang!',pro1_id;
        end if;
        update products
        set stock = stock - quant_2
        where product_id = pro2_id
          and stock >= quant_2
        returning price into v_price_2;
        if not FOUND then
            raise exception 'San pham ID: % het hang!',pro2_id;
        end if;
        v_total_amount := (v_price_1 * quant_1) + (v_price_2 * quant_2);
        if v_balance < v_total_amount then
            raise exception 'Khach hang khong du tien. Tong don: %, So du: %',v_total_amount,v_balance;
        end if;
        -- Them chi tiet don hang
        insert into order_items(order_id, product_id, quantity, subtotal)
        VALUES (v_order_id, pro1_id, quant_1, v_price_1 * quant_1);
        insert into order_items(order_id, product_id, quantity, subtotal)
        values (v_order_id, pro2_id, quant_2, v_price_2 * quant_2);

        --Tru tien khach hang
        update customers set balance = balance - v_total_amount where customer_id = cus_id;

        --Chot don
        update orders set total_amount = v_total_amount, status = 'COMPLETED' where order_id = v_order_id;
    exception
        when others then
            update orders set status = 'FAILED', total_amount = 0 where order_id = v_order_id;
            raise notice 'Giao dich that bai. Don hang % da bi huy. Loi: %',v_order_id,SQLERRM;
    end;
end;
$$;

call create_orders(1,1,2,1,1);

select * from customers;