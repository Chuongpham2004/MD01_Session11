CREATE TABLE products
(
    id    SERIAL PRIMARY KEY,
    name  VARCHAR(150) NOT NULL,
    stock INT DEFAULT 0 CHECK (stock >= 0)
);

-- 2. Tạo bảng đơn hàng (có thêm trạng thái đơn hàng)
CREATE TABLE orders
(
    id           SERIAL PRIMARY KEY,
    product_id   INT,
    quantity     INT NOT NULL CHECK (quantity > 0),
    order_status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, COMPLETED, CANCELLED...
    CONSTRAINT fk_product_id FOREIGN KEY (product_id) REFERENCES products (id)
);

CREATE OR REPLACE FUNCTION add_orders()
RETURNS TRIGGER
AS $$
    declare chk_stock int;
    BEGIN
        select stock into chk_stock from products WHERE id = new.product_id ;
        if chk_stock < new.quantity then
            raise exception 'Khong du stock';
        end if;
        UPDATE products set stock = stock - new.quantity where id = new.product_id;
        raise notice 'San pham id: % da tru: % trong kho',new.product_id,new.quantity;
        return new;
    END;
    $$
LANGUAGE plpgsql;

CREATE FUNCTION update_orders()
RETURNS TRIGGER
AS $$
    BEGIN
        if new.quantity > old.quantity then
        UPDATE products set stock = stock - (new.quantity - old.quantity) where id = new.id;
        raise notice 'San pham id: % da duoc cap nhat trong kho', new.id;
        return new;
        end if;
    END;
    $$
language plpgsql;

create trigger trg_before_insert
BEFORE INSERT ON orders
for each row
execute function update_orders();

CREATE OR REPLACE FUNCTION fn_trg_before_update()
returns trigger as
    $$
    declare v_change_quantity int;
        v_stock int;
    begin
        select stock into v_stock from products where id = new.product_id;
        if(new.quantity > old.quantity) then
            v_change_quantity := new.quantity - old.quantity;
            if(v_change_quantity > v_stock) then
                raise exception 'Khong du so luong';
            end if;

        update products set stock = stock - v_change_quantity where id = new.product_id;
        end if;
        return new;
    end;
    $$
language plpgsql;

create or replace trigger trg_before_update
before update on orders
for each row
execute function fn_trg_before_update();

CREATE OR REPLACE FUNCTION fn_after_update()
returns trigger
as $$
    BEGIN
        if new.status = 'Cancelled' then
            update products set stock  = stock + old.quantity where id = old.product_id;
        end if;
        return new;
    END;
    $$
language plpgsql;

CREATE or replace TRIGGER trg_update_by_status
AFTER UPDATE on orders
for each row
execute function fn_trg_before_update();

