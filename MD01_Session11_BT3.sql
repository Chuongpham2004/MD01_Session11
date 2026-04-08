-- 1. Bảng Sản phẩm
CREATE TABLE products
(
    product_id   SERIAL PRIMARY KEY,
    product_name VARCHAR(100)   NOT NULL,
    stock        INT            NOT NULL CHECK (stock >= 0),
    price        NUMERIC(10, 2) NOT NULL CHECK (price >= 0)
);

-- 2. Bảng Đơn hàng
CREATE TABLE orders
(
    order_id      SERIAL PRIMARY KEY,
    customer_name VARCHAR(100) NOT NULL,
    total_amount  NUMERIC(10, 2) DEFAULT 0,
    created_at    TIMESTAMP      DEFAULT NOW()
);

-- 3. Bảng Chi tiết đơn hàng
CREATE TABLE order_items
(
    order_item_id SERIAL PRIMARY KEY,
    order_id      INT REFERENCES orders (order_id) ON DELETE CASCADE,
    product_id    INT REFERENCES products (product_id),
    quantity      INT            NOT NULL CHECK (quantity > 0),
    subtotal      NUMERIC(10, 2) NOT NULL
);

INSERT INTO products (product_name, stock, price)
VALUES ('iPhone 15 Pro', 10, 25000.00),
       ('MacBook Air M2', 5, 28000.00),
       ('AirPods Pro', 20, 5000.00);

CREATE OR REPLACE PROCEDURE sp_PlaceOrder(in p_customer_name varchar(100), in p_product_id int[], in p_quantities int[])
    language plpgsql
as
$$
declare
    v_order_id     int;
    i              int;
    v_price        numeric(15, 2);
    v_subtotal     numeric(15, 2);
    v_total_amount numeric(15, 2) := 0;
begin
    insert into orders(customer_name, total_amount)
    values (p_customer_name, 0)
    returning order_id into v_order_id;

    for i in 1 .. array_length(p_product_id, 1)
        loop
            update products
            set stock = stock - p_quantities[i]
            where product_id = p_product_id[i]
              and stock >= p_quantities[i]
            returning price into v_price;

            if not found then
                raise notice 'San pham ID % khong du so luong. Dang Rollback...',p_product_id[i];
                rollback;
                return;
            end if;

            v_subtotal := v_price * p_quantities[i];
            v_total_amount := v_subtotal + v_total_amount;

            insert into order_items(order_id, product_id, quantity, subtotal)
            values (v_order_id, p_product_id[i], p_quantities[i], v_subtotal);
        end loop;

    update orders set total_amount = v_total_amount where order_id = v_order_id;

    commit;
    raise notice 'Dat hang thanh cong! Don hang so: %. Tong tien can thanh toan: %',v_order_id,v_total_amount;
end;
$$;


call sp_PlaceOrder('Pham Hoang Chuong', ARRAY [1,2], ARRAY [9,1]);








