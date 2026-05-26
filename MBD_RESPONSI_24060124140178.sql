use  bankdb;
show tables;

-- Nama : Raihan Lazuardi
-- Nim  : 24060124140178
-- Lab  : B2

-- Responsi
-- Soal 1
-- Buat view vw_recent_high_value_transactions yang menampilkan transaksi 30 hari terakhir dengan nilai > rata-rata seluruh transaksi. 
-- (Petunjuk: Gunakan fungsi CURDATE() atau NOW() di MySQL). 

-- Jawab
select * from transactions;
desc transactions;
-- view vw_recent_high_value
create view vw_recent_high_value_transactions as
select 
    transaction_id,
    account_id,
    amount,
    transaction_type,
    transaction_date,
    `description`
from transactions
where transaction_date >= date_sub(now(), interval 30 day) and amount > (select avg(amount) from transactions);

-- Soal 2
-- Buat view yang menampilkan jumlah transaksi per akun, dengan memisahkan transaksi deposit, transfer, dan withdrawal dalam kolom berbeda. 
select * from transactions;
select * from transaction_types;

create view showJumlahTransaksi as 
SELECT 
    account_id,
    count(case when transaction_type = 'deposit' then 1 end) as jumlah_deposit,
    count(case when transaction_type = 'transfer' then 1 end) as jumlah_transfer,
    count(case when transaction_type = 'withdrawal' then 1 end) as jumlah_withdrawal,
    count(*) as total_transaksi

from transactions
group by account_id;

-- soal 3
-- Buat view vw_account_card_transaction_detail yang menggabungkan data akun, kartu, dan transaksi yang terkait. 
select * from accounts;
select * from cards;
select * from transactions;

create view vw_account_card_transaction_detail as
select
    a.account_id,
    a.account_number,
    a.account_type,
    a.balance,
    c.card_number,
    c.card_type,
    t.transaction_id,
    tt.`name` as transaction_type,
    t.amount
from accounts a
left join cards c on a.account_id = c.account_id
left join transactions t on a.account_id = t.account_id
left join transaction_types tt on t.transaction_type_id = tt.transaction_type_id;

-- soal 4
-- Buat procedure sp_get_transactions_report dengan parameter p_account_id,
-- p_date_from, p_date_to. Di dalam procedure, tangani kondisi jika parameter tersebut
-- bernilai NULL untuk menggunakan nilai default (misal 30 hari terakhir semua akun).

select * from transactions;

drop procedure if exists sp_get_transactions_report;

DELIMITER //

create procedure sp_get_transactions_report(
    in p_account_id char(36),
    in p_date_from date,
    in p_date_to date
)
begin
    if p_date_to is null then
        set p_date_to = CURDATE();
    end if;
    if p_date_from is null then
        set p_date_from = DATE_SUB(p_date_to, interval 30 day);
    end if;
    select
        t.transaction_id,
        t.account_id,
        tt.`name` as transaction_type,
        t.amount,
        t.transaction_date,
        t.`description`
    from transactions t
    join transaction_types tt on t.transaction_type_id = tt.transaction_type_id
    where
        (p_account_id is null or t.account_id = p_account_id) and date(t.transaction_date) between p_date_from and p_date_to order by t.transaction_date desc;
end //
DELIMITER ;


-- Soal 5
-- Buat function (atau procedure) fn_customer_loans_info yang mengembalikan list semua
-- pinjaman customer lengkap dengan status dan selisih hari antara end_date dan tanggal
-- saat ini (CURDATE()).
drop procedure if exists fn_customer_loans_info;

DELIMITER //

create procedure fn_customer_loans_info(
    in p_customer_id char(36)
)
begin
    select
        l.loan_id,
        l.loan_amount,
        l.interest_rate,
        l.loan_terms_months,
        l.start_date,
        l.end_date,
        l.`status`,
        datediff(l.end_date, curdate()) as sisa_hari from loans l
    where l.customer_id = p_customer_id order by l.start_date;
END //

DELIMITER ;

-- soal 6
-- Buat Stored Procedure yang mengembalikan statistik berikut dalam satu set hasil: total
-- akun, total saldo, rata-rata saldo untuk customer_id tertentu

drop procedure if exists sp_customer_account_stats;

DELIMITER //

create procedure sp_customer_account_stats(
    in p_customer_id char(36)
)
begin
    select
        a.customer_id,
        count(a.account_id) as total_accounts,
        sum(a.balance) as total_balance,
        avg(a.balance) as average_balance
    from accounts a
    where a.customer_id = p_customer_id
    group by a.customer_id;
END //

DELIMITER ;

-- Soal 7
-- Cegah transaksi baru yang memiliki transaction_date lebih lama dari transaksi terakhir
-- untuk akun yang melakukan transaksi tersebut (Petunjuk: Gunakan Trigger BEFORE
-- INSERT dengan SIGNAL SQLSTATE '45000').

DELIMITER //

create trigger trg_prevent_backdated_transaction
before insert on transactions
for each row
begin
    declare v_last_date datetime;

    select max(transaction_date)
    into v_last_date
    from transactions
    where account_id = new.account_id;

    if v_last_date is not null and new.transaction_date < v_last_date then
        signal sqlstate '45000'
        set message_text = 'GA BISA NYAK !';
    end if;
end //

DELIMITER ;

-- soal 8
-- Buat cursor (di dalam Stored Procedure) yang membaca semua akun credit, lalu kurangi
-- saldo mereka 2% sebagai biaya bulanan.

DELIMITER //

create procedure sp_apply_monthly_fee_credit_accounts() -- kosong ygy
begin
    declare v_done int default 0;
    declare v_account_id char(36);
    declare v_balance decimal(18,2);
    declare cur_credit cursor for
        select account_id, balance
        from accounts
        where account_type = 'credit';

    declare continue handler for not found set v_done = 1;
    open cur_credit;

    read_loop: loop
        fetch cur_credit into v_account_id, v_balance;
        if v_done = 1 then
            leave read_loop;
        end if;
        update accounts
        set balance = balance - (balance * 0.02)
        where account_id = v_account_id;

    end loop;
    close cur_credit;
end$$


    
    
    

