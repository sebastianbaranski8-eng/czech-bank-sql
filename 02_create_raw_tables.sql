-- Raw layer: exact copies of the source files, loaded without any changes
CREATE SCHEMA IF NOT EXISTS raw;

-- Demographic data for 77 districts 

CREATE TABLE raw.district (
    a1 INTEGER PRIMARY KEY,   -- district id
    a2 TEXT,                  -- district name
    a3 TEXT,                  -- region
    a4 INTEGER,               -- number of inhabitants
    a5  INTEGER,              -- municipalities with < 500 inhabitants
    a6  INTEGER,              -- municipalities with 500-1999 inhabitants
    a7  INTEGER,              -- municipalities with 2000-9999 inhabitants
    a8  INTEGER,              -- municipalities with >= 10000 inhabitants
    a9  INTEGER,              -- number of cities
    a10 NUMERIC,              -- ratio of urban inhabitants (%)
    a11 INTEGER,              -- average salary
    a12 TEXT,                 -- unemployment rate 1995 ('?' = missing)
    a13 NUMERIC,              -- unemployment rate 1996
    a14 INTEGER,              -- entrepreneurs per 1000 inhabitants
    a15 TEXT,                 -- crimes committed in 1995 ('?' = missing)
    a16 INTEGER               -- crimes committed in 1996
);

CREATE TABLE raw.account(
account_id INTEGER PRIMARY KEY,
district_id INTEGER,
frequency TEXT,         -- statement frequency
date INTEGER            -- account creation date YYMMDD
);

CREATE TABLE raw.client(
client_id INTEGER PRIMARY KEY,
birth_number TEXT,      -- YYMMDD, women have 50 added to the month
district_id INTEGER
);

CREATE TABLE raw.disp(
disp_id INTEGER PRIMARY KEY,
client_id INTEGER,
account_id INTEGER,
type TEXT               -- OWNER or DISPONENT (authorized user)
);

CREATE TABLE raw.card(
card_id INTEGER PRIMARY KEY,
disp_id INTEGER,
type TEXT,              -- junior, classic or gold
issued TEXT             -- 'YYMMDD 00:00:00'
);

CREATE TABLE raw.loan(
loan_id INTEGER PRIMARY KEY,
account_id INTEGER,
date INTEGER,           -- loan date YYMMDD
amount NUMERIC(12,2),  
duration INTEGER,       -- in months
payments NUMERIC(10,2), -- monthly payment
status TEXT             -- A,B,C or D 
);

CREATE TABLE raw.permanent_order(
order_id INTEGER PRIMARY KEY,
account_id INTEGER,
bank_to TEXT,
account_to TEXT,
amount NUMERIC(12,2),
k_symbol TEXT          --payment purpose (in Czech)
);

CREATE TABLE raw.trans( 
trans_id INTEGER PRIMARY KEY,
account_id INTEGER,
date INTEGER,           -- transaction date as YYMMDD
type TEXT,              -- credit or debit (in Czech)
operation TEXT,         -- mode of transaction (in Czech)
amount NUMERIC(12,2),
balance NUMERIC(12,2),  -- balance after the transaction 
k_symbol TEXT,          -- payment purpose (in Czech)
bank TEXT,              -- partner's bank 
account TEXT            -- partner's account number
);
