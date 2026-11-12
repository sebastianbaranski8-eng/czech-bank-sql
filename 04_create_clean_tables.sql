-- Clean layer: typed, translated and documented tables built from the raw layer
-- The whole schema is rebuilt from scratch every time this script runs
DROP SCHEMA IF EXISTS clean CASCADE;
CREATE SCHEMA clean;

-- Districts: readable column names, '?' converted to NULL
CREATE TABLE clean.district AS
SELECT
    a1                        AS district_id,
    a2                        AS district_name,
    a3                        AS region,
    a4                        AS inhabitants,
    a5                        AS municipalities_under_500,
    a6                        AS municipalities_500_1999,
    a7                        AS municipalities_2000_9999,
    a8                        AS municipalities_over_10000,
    a9                        AS cities,
    a10                       AS urban_ratio,
    a11                       AS avg_salary,
    NULLIF(a12, '?')::NUMERIC AS unemployment_rate_1995,
    a13                       AS unemployment_rate_1996,
    a14                       AS entrepreneurs_per_1000,
    NULLIF(a15, '?')::INTEGER AS crimes_1995,
    a16                       AS crimes_1996
FROM raw.district;

ALTER TABLE clean.district ADD PRIMARY KEY (district_id);

-- Accounts: real dates and translated statement frequency
CREATE TABLE clean.account AS
SELECT
    account_id,
    district_id,
    CASE frequency
        WHEN 'POPLATEK MESICNE'   THEN 'monthly'
        WHEN 'POPLATEK TYDNE'     THEN 'weekly'
        WHEN 'POPLATEK PO OBRATU' THEN 'after transaction'
    END AS statement_frequency,
    MAKE_DATE(1900 + date / 10000, date / 100 % 100, date % 100) AS created_date
FROM raw.account;

ALTER TABLE clean.account ADD PRIMARY KEY (account_id);
ALTER TABLE clean.account ADD FOREIGN KEY (district_id) REFERENCES clean.district(district_id);


-- Clients: gender and birth date decoded from the Czech birth number
-- The number is YYMMDD, with 50 added to the month for women

CREATE TABLE clean.client AS
WITH parts AS (
    SELECT
        client_id,
        district_id,
        SUBSTRING(birth_number, 1, 2)::INTEGER AS yy,
        SUBSTRING(birth_number, 3, 2)::INTEGER AS mm,
        SUBSTRING(birth_number, 5, 2)::INTEGER AS dd
    FROM raw.client
)

SELECT
    client_id,
    district_id,
    CASE WHEN mm > 50 THEN 'F' ELSE 'M' END AS gender,
    MAKE_DATE(1900 + yy, CASE WHEN mm > 50 THEN mm - 50 ELSE mm END, dd) AS birth_date
FROM parts;

ALTER TABLE clean.client ADD PRIMARY KEY (client_id);
ALTER TABLE clean.client ADD FOREIGN KEY (district_id) REFERENCES clean.district(district_id);

-- Dispositions: link clients to accounts (owner or authorized user)
CREATE TABLE clean.disp AS
SELECT
    disp_id,
    client_id,
    account_id,
    CASE type
        WHEN 'OWNER' THEN 'owner'
        WHEN 'DISPONENT' THEN 'authorized user'
    END AS disp_type
FROM raw.disp;

ALTER TABLE clean.disp ADD PRIMARY KEY(disp_id);
ALTER TABLE clean.disp ADD FOREIGN KEY (client_id) REFERENCES clean.client(client_id);
ALTER TABLE clean.disp ADD FOREIGN KEY (account_id) REFERENCES clean.account(account_id);

-- Credit cards: real issue date
CREATE TABLE clean.card AS
SELECT
    card_id,
    disp_id,
    type AS card_type,
    TO_DATE('19' || LEFT(issued, 6), 'YYYYMMDD') AS issued_date
FROM raw.card;

ALTER TABLE clean.card ADD PRIMARY KEY (card_id);
ALTER TABLE clean.card ADD FOREIGN KEY (disp_id) REFERENCES clean.disp(disp_id);

-- Loans: real dates, status description and business flags
-- Status: A = finished and paid,      B = finished and not paid,
--         C = running and OK so far,  D = running and in debt

CREATE TABLE clean.loan AS
SELECT
    loan_id,
    account_id,
    MAKE_DATE(1900 + date / 10000, date / 100 % 100, date % 100) AS loan_date,
    amount,
    duration AS duration_months,
    payments AS monthly_payment,
    status,
    CASE status
        WHEN 'A' THEN 'finished and paid'
        WHEN 'B' THEN 'finished and not paid'
        WHEN 'C' THEN 'running and OK so far'
        WHEN 'D' THEN 'running and in debt'
    END AS status_description,
    status IN ('B', 'D') AS is_bad_loan,
    status IN ('A', 'B') AS is_finished
FROM raw.loan;

ALTER TABLE clean.loan ADD PRIMARY KEY (loan_id);
ALTER TABLE clean.loan ADD FOREIGN KEY (account_id) REFERENCES clean.account(account_id);

-- Permanent orders: translated payment purpose, blank values converted to NULL
CREATE TABLE clean.permanent_order AS
SELECT
    order_id,
    account_id,
    bank_to,
    account_to,
    amount,
    CASE k_symbol
        WHEN 'POJISTNE' THEN 'insurance payment'
        WHEN 'SIPO'     THEN 'household payment'
        WHEN 'LEASING'  THEN 'leasing'
        WHEN 'UVER'     THEN 'loan payment'
    END AS payment_purpose
FROM raw.permanent_order;
    
ALTER TABLE clean.permanent_order ADD PRIMARY KEY (order_id);
ALTER TABLE clean.permanent_order ADD FOREIGN KEY (account_id) REFERENCES clean.account(account_id);

-- Transactions: translated codes, signed amounts, blank values converted to NULL
-- Type VYBER (cash withdrawal) is not in the original documentation, treated as debit
CREATE TABLE clean.trans AS
SELECT
    trans_id,
    account_id,
    MAKE_DATE(1900 + date / 10000, date / 100 % 100, date % 100) AS trans_date,
    CASE type
        WHEN 'PRIJEM' THEN 'credit'
        WHEN 'VYDAJ'  THEN 'debit'
        WHEN 'VYBER'  THEN 'debit'
    END AS trans_type,
    CASE operation
        WHEN 'VKLAD'          THEN 'cash deposit'
        WHEN 'PREVOD Z UCTU'  THEN 'collection from another bank'
        WHEN 'VYBER'          THEN 'cash withdrawal'
        WHEN 'VYBER KARTOU'   THEN 'card withdrawal'
        WHEN 'PREVOD NA UCET' THEN 'remittance to another bank'
    END AS operation,
    amount,
    CASE WHEN type = 'PRIJEM' THEN amount ELSE -amount END AS signed_amount,
    balance,
    CASE k_symbol
        WHEN 'POJISTNE'    THEN 'insurance payment'
        WHEN 'SLUZBY'      THEN 'statement fee'
        WHEN 'UROK'        THEN 'interest credited'
        WHEN 'SANKC. UROK' THEN 'penalty interest'
        WHEN 'SIPO'        THEN 'household payment'
        WHEN 'DUCHOD'      THEN 'pension'
        WHEN 'UVER'        THEN 'loan payment'
    END AS payment_purpose,
    NULLIF(bank, '')    AS partner_bank,
    NULLIF(account, '') AS partner_account
FROM raw.trans;

ALTER TABLE clean.trans ADD PRIMARY KEY (trans_id);
ALTER TABLE clean.trans ADD FOREIGN KEY (account_id) REFERENCES clean.account (account_id);