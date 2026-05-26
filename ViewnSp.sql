-- belajar buat responsi
-- materi : View, Stored Procedure, Function, Trigger, Indexing, Pointer

-- kita pake bankdb database yahhh
use bankdb;

show tables;

-- Materi 1 (View)

-- Jadi materi view ini adalah sebuah shortcut yang dibuat dari query select, data nya tuh
-- ga disimpen, view cuma mendefinisikan query nya doang 

-- Contoh soal
-- Soal 1
-- Buatlah view untuk menampilkan seluruh isi dari tabel customers
-- jawaban:
select * from customers;
describe customers;
Create view v_customers_all as 
select customer_id, first_name,last_name,email,phone_number,address,created_at
from customers;

select * from v_customers_all;

-- mencoba versi dua (sotoy)
create view v_customers_all2 as
select * from customers

select * from v_customers_all2;

-- oh bisa ges wkwkw

-- soal 2
-- buat view buat nampilin semua transaksi deposit

show tables;
desc transactions

create view v_deposit_transactions as
select * from transactions;

select * from v_deposit_transactions;

-- soal 3
--  buat view buat nampilin semua transaksi transfer

desc transaction_types
select * from transaction_types;
select * from transactions;
describe transactions;

create view v_transfer_transaction as
select * from transactions where transaction_type_id = 2;

select * from v_transfer_transaction;

-- oke view paham, skrg kita lanjut ke stored procedure

-- Stored procedure adalah kumpulan perintah sql yang disimpan di database dan bisa dipanggil berulang kali
-- Stored procedure bisa menerima 3 parameter, yaitu : in(hanya nilai masukan), out(hanya nilai keluaran / return) , inout(masukan dan nilai keluaran)  

-- contoh soal 
-- soal 1
-- Buat stored procedure untuk menambahkan customer baru ke dalam tabel customer
-- input : first_name,last_name, email,phone_number, address

-- jawab:
desc customers;
DELIMITER //
drop procedure if exists sp_CreateCustomer //
create procedure sp_CreateCustomer(
	in p_firstName varchar(50),
    in p_lastName varchar(50),
    in p_email varchar(50),
    in p_phoneNumber varchar(50),
    in p_address varchar(50)
)
begin
	insert into customers(first_name,last_name,email,phone_number,address) 
    values (p_firstName, p_lastName, p_email, p_phoneNumber, p_address);
end //
DELIMITER ;

select * from customers;
call sp_CreateCustomer('Raihan', 'Sukses Ya Allah Aamin', 'rlazuardi163@gmail.com', '(62)8967877443', 'California sonoan dikit');
select * from customers where first_name = 'Raihan';

-- Soal 2
-- Buat store procedure untuk buat akun baru untuk customer yang sudah ada
-- dengan catatan customer id harus udah ada pada tabel customers
--  input customer_id, account_number, account_type, balance
select * from customers;
show tables;
select * from accounts;
desc accounts;
-- jawaban

DELIMITER //

drop procedure if exists sp_CreateAccount //
create procedure sp_CreateAccount(
	in p_customerId  char(36),
    in p_accountNumber char(36),
    in p_accountType varchar(50),
    in p_balance decimal(18,2)
)
begin
	declare cek int;
    
    select count(*) into cek
    from customers 
    where customer_id = p_customerId;
    
    if cek = 0 then
		signal sqlstate '45000'
        set message_text = 'customer_id tidak ditemukan!!';
	end if;
    
    insert into accounts(customer_id, account_number, account_type, balance)
    values(p_customerId, p_accountNumber, p_accountType, p_balance);
end //

DELIMITER ; 

call sp_CreateAccount('1f72084e-90f3-4334-9b8f-a3b350c2beb0', '1234567891','savings', 9917.50);
select * from accounts where customer_id = '1f72084e-90f3-4334-9b8f-a3b350c2beb0';

-- soal 3
-- Procedure sp_MakeTransaction untuk menambahkan transaksi baru: input account_id, transaction_type_id, amount, description, reference_account (opsional). 
-- Catatan: Tambahkan validasi untuk transfer, jika jumlah transfer melebihi balance maka transaksi dihentikan.
select * from transactions;
show tables;
describe transactions;

-- jawaban

DELIMITER //

drop procedure if exists sp_MakeTransaction //
create procedure sp_MakeTransaction(
    in p_accountID char(36),
    in p_transactionTypeId int,
    in p_amount decimal(18,2),
    in p_description varchar(50)
)
begin
	declare cek int;
    
    select count(*) into cek 
    from accounts 
    where account_id = p_accountID and balance >= p_amount;
    
    if cek = 0 then 
		signal sqlstate '45000'
        set message_text = 'Tidak dapat melanjutkan transaksi karena saldo kurang';
	end if;
    
    insert into transactions(account_id,transaction_type_id,amount,`description`)
    values (p_accountID,p_transactionTypeId,p_amount,p_description);
end //
DELIMITER ;

call sp_MakeTransaction('9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7',2,9138.34, 'kontol');

select * from transactions;
select * from accounts where account_id = '9cd97ecb-58c9-4610-b4b1-d9f72bcae7f7';

-- soal 4
-- Procedure sp_GetCustomerSummary untuk menampilkan ringkasan data customer berdasarkan customer_id 
-- meliputi: Nama lengkap customer, Jumlah akun yang dimiliki, Jumlah total saldo semua akun, Jumlah pinjaman aktif, Total pinjaman amount aktif.

select * from customers;
select * from accounts;
select * from loans;
desc customers;
-- jawaban
DELIMITER //

drop procedure if exists sp_GetCustomerSummary //
create procedure sp_GetCustomerSummary(
	in p_customer_id char(36)
)
begin 
	select
        concat(c.first_name, ' ', c.last_name) as nama_lengkap,
        
        (select count(*) from accounts a
        where a.customer_id = c.customer_id) as jumlah_akun,
        
        (select coalesce(sum(balance),0) from accounts a
        where a.customer_id = c.customer_id) as total_saldo,
        
        (select count(*) from loans l 
        where l.customer_id = c.customer_id and l.status = 'active') as jumlah_pinjaman_aktif,
        
        (select coalesce(sum(loan_amount),0) from loans l
        where l.customer_id = c.customer_id and l.status = 'active') as total_pinjaman_amount_aktif
	
    from customers c
    where c.customer_id = p_customer_id;
end // 
DELIMITER ;

call sp_GetCustomerSummary('57829c08-247e-4dec-b528-cd1099fc1e81');
call sp_GetCustomerSummary('9d78736f-df51-4622-9cb1-c4db88dca2d0');
call sp_GetCustomerSummary('c3b4c3b8-0511-481d-bf7f-5da93c8014df');
call sp_GetCustomerSummary('86f4ec23-7064-4bb5-9aaf-b8e98e8d95ec');


        
        
        


