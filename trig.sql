use bankdb;
-- TRIGGERRRRRRRRRRRRRRRRRRRRRRRRRRRR


DELIMITER //
CREATE TRIGGER tr_BlockInvalidReferenceAccount
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_ada INT DEFAULT 0;
    IF NEW.transaction_type_id = 2 THEN
        IF NEW.reference_account IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Transfer harus ada akun tujuannya';
        END IF;
        SELECT COUNT(*) INTO v_ada
        FROM accounts
        WHERE account_id = NEW.reference_account;
        IF v_ada = 0 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Akun tujuan tidak ditemukan, transfer dibatalkan';
        END IF;
    END IF;
END //
DELIMITER ;

INSERT INTO transactions (account_id, transaction_type_id, amount, description, reference_account)
VALUES ('f9341b55-2686-40af-9e1b-2986672efd92', 2, 50.00, 'test transfer', 'akun-ga-ada-123');


DELIMITER //
CREATE TRIGGER tr_LimitAccountsPerCustomer
BEFORE INSERT ON accounts
FOR EACH ROW
BEGIN
    DECLARE v_jumlah_akun INT DEFAULT 0;
    SELECT COUNT(*) INTO v_jumlah_akun
    FROM accounts
    WHERE customer_id = NEW.customer_id;

    IF v_jumlah_akun >= 3 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Customer sudah punya 3 akun, tidak bisa menambah akun baru';
    END IF;
END //
DELIMITER ;

INSERT INTO accounts (customer_id, account_number, account_type, balance)
VALUES ('9d78736f-df51-4622-9cb1-c4db88dca2d0', '1234567890', 'savings', 5000.00);


DELIMITER //
CREATE TRIGGER tr_EnsureMinimumBalance
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_saldo_sekarang DECIMAL(18,2);
    DECLARE v_saldo_nanti    DECIMAL(18,2);
    IF NEW.transaction_type_id IN (2, 3) THEN
        SELECT balance INTO v_saldo_sekarang
        FROM accounts
        WHERE account_id = NEW.account_id;

        SET v_saldo_nanti = v_saldo_sekarang - NEW.amount;

        IF v_saldo_nanti < 1000.00 THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saldo minimal harus tersisa 1000.00 setelah transaksi';
        END IF;
    END IF;
END //
DELIMITER ;

INSERT INTO transactions (account_id, transaction_type_id, amount, description, reference_account)
VALUES ('f9341b55-2686-40af-9e1b-2986672efd92', 3, 9000.00, 'test tarik tunai', NULL);