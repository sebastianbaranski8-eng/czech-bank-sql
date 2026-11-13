SELECT district_name, region, avg_salary, unemployment_rate_1995, crimes_1995
FROM clean.district
WHERE unemployment_rate_1995 IS NULL;

SELECT 
    statement_frequency,
    COUNT(*) AS accounts,
    MIN(created_date) AS first_opened,
    MAX(created_date) AS last_opened
FROM clean.account
GROUP BY statement_frequency
ORDER BY accounts DESC;

SELECT 
    gender,
    COUNT(*) AS clients,
    MIN(EXTRACT(YEAR FROM birth_date)) AS oldest_birth_year,
    MAX(EXTRACT(YEAR FROM birth_date)) AS youngest_birth_year
FROM clean.client
GROUP BY gender;

SELECT 
    c.card_type,
    d.disp_type,
    COUNT(*) AS cards,
    MIN(c.issued_date) AS first_issued,
    MAX(c.issued_date) AS last_issued
FROM clean.card AS c
JOIN clean.disp AS d ON d.disp_id = c.disp_id
GROUP BY c.card_type, d.disp_type
ORDER BY cards DESC;

SELECT
    status,
    status_description,
    is_bad_loan,
    COUNT(*) AS loans,
    ROUND(AVG(amount)) AS avg_amount
FROM clean.loan
GROUP BY status, status_description, is_bad_loan
ORDER BY status;

SELECT
    r.k_symbol AS raw_value,
    c.payment_purpose,
    COUNT(*) AS orders
FROM raw.permanent_order AS r
JOIN clean.permanent_order AS c ON c.order_id = r.order_id
GROUP BY r.k_symbol, c.payment_purpose
ORDER BY orders DESC;

SELECT
    r.type AS raw_type,
    c.trans_type,
    COUNT(*)             AS transactions,
    SUM(c.signed_amount) AS total_signed_amount
FROM raw.trans AS r
JOIN clean.trans AS c ON c.trans_id = r.trans_id
GROUP BY r.type, c.trans_type
ORDER BY transactions DESC;

SELECT
    r.operation AS raw_operation,
    c.operation,
    COUNT(*) AS transactions
FROM raw.trans AS r
JOIN clean.trans AS c ON c.trans_id = r.trans_id
GROUP BY r.operation, c.operation
ORDER BY transactions DESC;

-- The loan overview view must have exactly one row per loan

SELECT
    COUNT(*)                AS total_rows,
    COUNT(DISTINCT loan_id) AS distinct_loans
FROM clean.loan_overview;