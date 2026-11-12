-- Question 1: How common are bad loans, and does the risk depend on
-- the loan amount and duration?
-- Bad loan = status B (finished, not paid) or D (running, in debt)

-- 1a. Overall bad loan rate

SELECT
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan;

-- 1b. Bad loan rate by loan duration

SELECT
    duration_months,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct,
    ROUND(AVG(amount))                  AS avg_amount
FROM clean.loan
GROUP BY duration_months
ORDER BY duration_months;

-- 1c. Bad loan rate by loan amount
SELECT
    CASE
        WHEN amount < 100000 THEN 'under 100k'
        WHEN amount < 200000 THEN '100k - 200k'
        WHEN amount < 300000 THEN '200k - 300k'
        ELSE '300k and more'
    END                                 AS amount_band,
    COUNT(*)                            AS total_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan
GROUP BY amount_band
ORDER BY MIN(amount);

-- Findings:
-- 1. 76 of 682 loans (11.1%) are bad.
-- 2. Loan duration has little effect: 8.4% for 12-month loans and 11.5% to 12.3%
--    for longer ones. Groups are small (130 to 145 loans), so these differences
--    are not reliable.
-- 3. Loan amount has a strong effect: the bad loan rate rises from 7.5% below 100k
--    to 20.7% at 300k and more, almost twice the overall rate.
-- 4. Longer loans are also larger (average 54k at 12 months, 244k at 60 months),
--    yet duration alone barely changes the risk. The size of the loan seems to
--    matter more than its length.