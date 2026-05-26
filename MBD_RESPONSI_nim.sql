USE bankdb;

-- ============================================================
-- SOAL 1
-- View transaksi 30 hari terakhir dengan nilai > rata-rata
-- ============================================================

CREATE OR REPLACE VIEW vw_recent_high_value_transactions AS
SELECT
    t.transaction_id,
    t.account_id,
    tt.name AS transaction_type,
    t.amount,
    t.transaction_date,
    t.description,
    t.reference_account
FROM transactions t
JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
WHERE
    t.transaction_date >= DATE_SUB(CURDATE(), INTERVAL 30 DAY)
    AND t.amount > (SELECT AVG(amount) FROM transactions);


-- ============================================================
-- SOAL 2
-- View jumlah transaksi per akun, dipisah per jenis transaksi
-- ============================================================

CREATE OR REPLACE VIEW vw_transaction_count_per_account AS
SELECT
    a.account_id,
    a.account_number,
    SUM(CASE WHEN tt.name = 'deposit'    THEN 1 ELSE 0 END) AS deposit,
    SUM(CASE WHEN tt.name = 'transfer'   THEN 1 ELSE 0 END) AS transfer,
    SUM(CASE WHEN tt.name = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal
FROM accounts a
LEFT JOIN transactions t ON a.account_id = t.account_id
LEFT JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
GROUP BY a.account_id, a.account_number;


-- ============================================================
-- SOAL 3
-- View gabungan data akun, kartu, dan transaksi
-- ============================================================

CREATE OR REPLACE VIEW vw_account_card_transaction_detail AS
SELECT
    a.account_id,
    a.account_number,
    a.account_type,
    a.balance,
    c.card_number,
    c.card_type,
    t.transaction_id,
    tt.name AS transaction_type,
    t.amount
FROM accounts a
LEFT JOIN cards c ON a.account_id = c.account_id
LEFT JOIN transactions t ON a.account_id = t.account_id
LEFT JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id;


-- ============================================================
-- SOAL 4
-- Stored Procedure: laporan transaksi dengan parameter nullable
-- ============================================================

DROP PROCEDURE IF EXISTS sp_get_transactions_report;

DELIMITER $$

CREATE PROCEDURE sp_get_transactions_report(
    IN p_account_id  CHAR(36),
    IN p_date_from   DATE,
    IN p_date_to     DATE
)
BEGIN
    -- Jika p_date_to NULL, gunakan hari ini
    IF p_date_to IS NULL THEN
        SET p_date_to = CURDATE();
    END IF;

    -- Jika p_date_from NULL, default 30 hari sebelum p_date_to
    IF p_date_from IS NULL THEN
        SET p_date_from = DATE_SUB(p_date_to, INTERVAL 30 DAY);
    END IF;

    SELECT
        t.transaction_id,
        t.account_id,
        tt.name AS transaction_type,
        t.amount,
        t.transaction_date,
        t.description
    FROM transactions t
    JOIN transaction_types tt ON t.transaction_type_id = tt.transaction_type_id
    WHERE
        -- Jika p_account_id NULL, tampilkan semua akun
        (p_account_id IS NULL OR t.account_id = p_account_id)
        AND DATE(t.transaction_date) BETWEEN p_date_from AND p_date_to
    ORDER BY t.transaction_date DESC;
END$$

DELIMITER ;


-- ============================================================
-- SOAL 5
-- Function: info pinjaman customer + sisa hari
-- (Karena MySQL function hanya bisa return scalar,
--  maka dibuat sebagai Stored Procedure)
-- ============================================================

DROP PROCEDURE IF EXISTS fn_customer_loans_info;

DELIMITER $$

CREATE PROCEDURE fn_customer_loans_info(
    IN p_customer_id CHAR(36)
)
BEGIN
    SELECT
        l.loan_id,
        l.loan_amount,
        l.interest_rate,
        l.loan_terms_months,
        l.start_date,
        l.end_date,
        l.status,
        DATEDIFF(l.end_date, CURDATE()) AS sisa_hari
    FROM loans l
    WHERE l.customer_id = p_customer_id
    ORDER BY l.start_date;
END$$

DELIMITER ;


-- ============================================================
-- SOAL 6
-- Stored Procedure: statistik akun per customer
-- ============================================================

DROP PROCEDURE IF EXISTS sp_customer_account_stats;

DELIMITER $$

CREATE PROCEDURE sp_customer_account_stats(
    IN p_customer_id CHAR(36)
)
BEGIN
    SELECT
        a.customer_id,
        COUNT(a.account_id)    AS total_accounts,
        SUM(a.balance)         AS total_balance,
        AVG(a.balance)         AS average_balance
    FROM accounts a
    WHERE a.customer_id = p_customer_id
    GROUP BY a.customer_id;
END$$

DELIMITER ;


-- ============================================================
-- SOAL 7
-- Trigger: cegah transaksi baru dengan tanggal lebih lama
-- dari transaksi terakhir akun tersebut
-- ============================================================

DROP TRIGGER IF EXISTS trg_prevent_backdated_transaction;

DELIMITER $$

CREATE TRIGGER trg_prevent_backdated_transaction
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE v_last_date DATETIME;

    SELECT MAX(transaction_date)
    INTO v_last_date
    FROM transactions
    WHERE account_id = NEW.account_id;

    -- Hanya blok jika sudah ada transaksi sebelumnya
    IF v_last_date IS NOT NULL AND NEW.transaction_date < v_last_date THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Transaction date cannot be earlier than the last transaction date for this account.';
    END IF;
END$$

DELIMITER ;


-- ============================================================
-- SOAL 8
-- Stored Procedure dengan Cursor:
-- kurangi saldo akun credit sebesar 2% (biaya bulanan)
-- ============================================================

DROP PROCEDURE IF EXISTS sp_apply_monthly_fee_credit_accounts;

DELIMITER $$

CREATE PROCEDURE sp_apply_monthly_fee_credit_accounts()
BEGIN
    DECLARE v_done       INT DEFAULT 0;
    DECLARE v_account_id CHAR(36);
    DECLARE v_balance    DECIMAL(18,2);

    DECLARE cur_credit CURSOR FOR
        SELECT account_id, balance
        FROM accounts
        WHERE account_type = 'credit';

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    OPEN cur_credit;

    read_loop: LOOP
        FETCH cur_credit INTO v_account_id, v_balance;

        IF v_done = 1 THEN
            LEAVE read_loop;
        END IF;

        UPDATE accounts
        SET balance = balance - (balance * 0.02)
        WHERE account_id = v_account_id;

    END LOOP;

    CLOSE cur_credit;
END$$

DELIMITER ;
