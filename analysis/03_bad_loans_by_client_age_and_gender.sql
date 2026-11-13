-- Question 3: Does the risk of a loan depend on the age and gender of the borrower?
-- Borrower = owner of the account (accounts can also have an authorized user,
-- who is excluded so that each loan is counted once)

-- 3a. Sanity check: one row per loan, and the range of borrower ages
WITH loan_owner AS (
    SELECT
        l.loan_id,
        l.is_bad_loan,
        c.gender,
        EXTRACT(YEAR FROM AGE(l.loan_date, c.birth_date)) AS age_at_loan
    FROM clean.loan AS l
    JOIN clean.disp AS dp ON dp.account_id = l.account_id AND dp.disp_type = 'owner'
    JOIN clean.client AS c ON c.client_id = dp.client_id
)

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT loan_id) AS distinct_loans,
    MIN(age_at_loan) AS youngest_borrower,
    MAX(age_at_loan) AS oldest_borrower
FROM loan_owner;

-- Data issue found in 3a: the youngest borrower is 13 years old at the loan date.
-- 30 loans have an owner aged 13 to 17, which is not plausible for a bank loan.

-- 3b. Bad loan rate by age at loan date
-- Handling of borrowers under 18:
--   The dataset is anonymized, and the most likely cause is that birth numbers
--   were altered during anonymization. Another possibility is that a guardian
--   signed the loan while the minor was recorded as the account owner.
--   These loans are neither removed nor mixed with adult borrowers: they form
--   a separate band, so they do not distort the results for young adults.

WITH loan_owner AS(
    SELECT
        l.loan_id,
        l.is_bad_loan,
        c.gender,
        EXTRACT(YEAR FROM AGE(l.loan_date, c.birth_date)) AS age_at_loan
    FROM clean.loan AS l
    JOIN clean.disp AS dp on dp.account_id = l.account_id AND dp.disp_type = 'owner'
    JOIN clean.client AS c ON c.client_id = dp.client_id
)
SELECT
    CASE
        WHEN age_at_loan < 18 THEN 'under 18 (data issue)'
        WHEN age_at_loan < 25 THEN '18 - 24'
        WHEN age_at_loan < 35 THEN '25 - 34'
        WHEN age_at_loan < 45 THEN '35 - 44'
        WHEN age_at_loan < 55 THEN '45 - 54'
        ELSE '55 and more'
    END AS age_band,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM loan_owner
GROUP BY age_band
ORDER BY MIN(age_at_loan); 

-- 3c. Bad loan rate by gender

WITH loan_owner AS (
    SELECT
        l.loan_id,
        l.is_bad_loan,
        c.gender,
        EXTRACT(YEAR FROM AGE(l.loan_date, c.birth_date)) AS age_at_loan
    FROM clean.loan AS l
    JOIN clean.disp AS dp ON dp.account_id = l.account_id AND dp.disp_type = 'owner'
    JOIN clean.client AS c ON c.client_id = dp.client_id 
)
SELECT
    gender,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM loan_owner
GROUP BY gender;

-- Findings:
-- 1. Data issue: 30 loans have an owner aged 13 to 17 at the loan date, which is
--    not plausible. They are reported as a separate band (6.7%, 2 bad loans).
-- 2. Risk by age follows a U shape: 15.7% for borrowers aged 18 to 24, the lowest
--    rate of 8.4% at 25 to 34, about 11% between 35 and 54, and 14.1% at 55 and
--    more. Groups at both ends are small (102 and 78 loans).
-- 3. Because the relationship is not linear, age should be used in bands rather
--    than as a single number in a credit scoring model.
-- 4. Gender makes little difference: 11.8% for women and 10.5% for men, a gap
--    small enough to be chance.