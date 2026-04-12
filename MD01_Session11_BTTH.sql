-- 1. Bảng tài khoản ngân hàng
CREATE TABLE tai_khoan
(
    id            VARCHAR(10) PRIMARY KEY,
    ten_tai_khoan VARCHAR(100)   NOT NULL,
    so_du         DECIMAL(15, 2) NOT NULL DEFAULT 0,
    trang_thai    VARCHAR(20)             DEFAULT 'ACTIVE',
    ngay_tao      TIMESTAMP               DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng giao dịch
CREATE TABLE giao_dich
(
    id                   SERIAL PRIMARY KEY,
    tai_khoan_nguoi_gui  VARCHAR(10),
    tai_khoan_nguoi_nhan VARCHAR(10),
    so_tien              DECIMAL(15, 2),
    loai_giao_dich       VARCHAR(50),
    thoi_gian            TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    trang_thai           VARCHAR(20),
    mo_ta                TEXT
);

-- 3. Bảng vé xem phim
CREATE TABLE ve_phim
(
    id            SERIAL PRIMARY KEY,
    suat_chieu_id VARCHAR(10),
    ten_phim      VARCHAR(100),
    so_luong_con  INT NOT NULL,
    gia_ve        DECIMAL(10, 2),
    ngay_chieu    DATE
);

-- Thêm dữ liệu tài khoản

INSERT INTO tai_khoan (id, ten_tai_khoan, so_du, trang_thai)
VALUES ('TK001', 'Nguyen Van A', 5000000, 'ACTIVE'),

       ('TK002', 'Tran Thi B', 3000000, 'ACTIVE'),

       ('TK003', 'Le Van C', 1000000, 'LOCKED'),

       ('TK004', 'Pham Thi D', 2000000, 'ACTIVE'),

       ('TK005', 'Bank Fee Account', 0, 'ACTIVE');


-- Thêm dữ liệu vé phim

INSERT INTO ve_phim (suat_chieu_id, ten_phim, so_luong_con, gia_ve, ngay_chieu)
VALUES ('SC001', 'Avengers: Endgame', 5, 80000, '2024-01-15'),

       ('SC002', 'Spider-Man: No Way Home', 3, 75000, '2024-01-16'),

       ('SC003', 'The Batman', 1, 85000, '2024-01-17');
-- Chỉ còn 1 vé!

--1.1 Van de khong dung transaction
UPDATE tai_khoan
set so_du = so_du - 1000000
where id = 'TK001'; --Dong nay bi loi k thuc thi thanh cong => TK001 ko bi tru tien

UPDATE tai_khoan
set so_du = so_du + 1000000
where id = 'TK002'; -- Nhung TK002 lai duoc cong tien => ngan hang lỗ

--2. Giai phap voi transaction
CREATE OR REPLACE PROCEDURE funds_transfer(sender_id varchar(10), receiver_id varchar(10), amount_in decimal(15, 2))
    language plpgsql
as
$$
declare
    v_so_du decimal(15, 2);
    cnt_acc int;
    v_status_tk1 varchar(20);
    v_status_tk2 varchar(20);
begin
    begin
        select count(t.id) into cnt_acc from tai_khoan t where id like sender_id or id like receiver_id;
        if cnt_acc != 2 then
            raise exception 'Thong tin tai khoan khong dung hoac tai khoan khong ton tai';
        end if;

        select trang_thai into v_status_tk1 from tai_khoan where id = sender_id;
        if v_status_tk1 = 'LOCKED' then
            raise exception 'Tai khoan gui: % dang bi khoa',sender_id;
        end if;

        select trang_thai into v_status_tk2 from tai_khoan where id = receiver_id;
        if v_status_tk2 = 'LOCKED' then
            raise exception 'Tai khoan nhan: % dang bi khoa',receiver_id;
        end if;

        update tai_khoan set so_du = so_du - amount_in where id = sender_id and tai_khoan.so_du >= amount_in;
        if not FOUND then
            raise exception 'Tai khoan % khong du tien',sender_id;
        end if;

        update tai_khoan set so_du = so_du + amount_in where id = receiver_id;

        insert into giao_dich(tai_khoan_nguoi_gui, tai_khoan_nguoi_nhan, so_tien, loai_giao_dich, thoi_gian, trang_thai)
        values (sender_id, receiver_id, amount_in, 'Chuyen tien', now(), 'COMPLETED');

    exception
        when others then
            raise;
    end;
end;
$$;
-- chuyen tien thanh cong
call funds_transfer('TK001', 'TK002', 500000);
-- tai khoan bi khoa
call funds_transfer('TK001','TK003',1000000);
-- tai khoan khong ton tai
call funds_transfer('TK001','TK099',2000000);
-- tai khoan ko du tien
call funds_transfer('TK004','TK005',3000000);





