use bankdb;

-- Function

-- nah jadi function itu adalah ya fungsi wkwkkw
-- nanti dia bakal wajib ngembaliin return value ygy
-- nahh dia mirip sama sp, tapi doi tuh bisa dipanggil di select, kan kalo sp kaga bisa nyakk
-- doi ga bs parameter out, ya intinya function lebih ke arah fungsi dah pokok nya kek biasa ytta 

-- soal 1 

-- Buat function fn_GetCustomerTotalLoan yang menerima input
-- customer_id dan mengembalikan total nilai pinjaman customer tersebut
-- dari tabel loans.
-- cek dulu ah:
select * from customers;
select * from loans;
describe loans;
desc customers;

-- jawab

DELIMITER //

drop function if exists fn_GetCustomerTotalLoan //
create function fn_GetCustomerTotalLoan(
	p_customerID char(36)
)
returns decimal(18,2)
deterministic
begin
	declare count decimal(18,2);
    
    select coalesce(sum(loan_amount),0) into count
    from loans
    where customer_id = p_customerID;
    
    return count;
end //
DELIMITER ;
select fn_GetCustomerTotalLoan('29f948c1-0d27-4e13-9126-498a6e51a079') as totalPinjamanShi;

-- soal 2
-- Buat function fn_GetTransactionCountByAccount yang menerima input
-- account_id dan mengembalikan jumlah transaksi yang pernah dilakukan
-- oleh akun tersebut pada tabel transactions.


select * from transactions;    

-- jawaban
DELIMITER //

drop function if exists fn_GetTransactionCountByAccount //
create function fn_GetTransactionCountByAccount(
	p_accountID char(36)
)
returns int
deterministic
begin
	declare jumlah_transaksi int;
    
    select count(*) into jumlah_transaksi
    from transactions
    where account_id = p_accountID;
    
    return jumlah_transaksi;
end //
DELIMITER ;

select fn_GetTransactionCountByAccount('802b2efe-e1d1-465b-940f-5cf573a2c985');

-- soal 3
-- Buat function fn_GetAccountTypeByNumber yang menerima input
-- account_number dan mengembalikan jenis akun/account_type dari tabel
-- accounts

-- cek

select * from accounts
desc accounts;
-- jawab

DELIMITER //

drop function if exists fn_GetAccountTypeByNumber //
create function fn_GetAccountTypeByNumber(
	p_accountNumber char(10)
)
returns varchar(50)
deterministic
begin
	declare tipeAkunAnj varchar(50);
    
    select account_type into tipeAkunAnj
    from accounts
    where account_number = p_accountNumber;
    
    return tipeAkunAnj;
end //
DELIMITER ;

select fn_GetAccountTypeByNumber('8346813622') as tipeAkunAnj;


