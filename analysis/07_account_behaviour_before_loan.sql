-- Question 7: How did the account behave in the 90 days before the loan, and
-- does this behaviour differ between good and bad loans?
-- Only transactions BEFORE the loan date are used (no information from the future)

-- 7a. Average account profile in the 90 days before the loan, good vs bad loans

WITH loan_features AS(
    SELECT 
        l.loan_id,
        l.is_bad_loan,
        COUNT(*) AS trans_count,
        AVG(t.balance) AS avg_balance,
        MIN(t.balance) AS min_balance,
        COALESCE(SUM(t.amount) FILTER (WHERE t.trans_type = 'credit'), 0) AS total_credits
    FROM clean.loan AS l
    JOIN clean.trans AS t
        ON  t.account_id  = l.account_id
      AND t.trans_date >= l.loan_date - 90
      AND t.trans_date <  l.loan_date
    GROUP BY l.loan_id, l.is_bad_loan
)
SELECT
    CASE 
        WHEN is_bad_loan THEN 'bad'
        ELSE 'good'
        END AS loan_quality,
        COUNT(*)                   AS total_loans,
    ROUND(AVG(trans_count), 1) AS avg_transactions,
    ROUND(AVG(avg_balance))    AS avg_balance,
    ROUND(AVG(min_balance))    AS avg_min_balance,
    ROUND(AVG(total_credits))  AS avg_total_credits
FROM loan_features
GROUP BY loan_quality
ORDER BY loan_quality DESC;

-- 7b. Bad loan rate by the lowest balance in the 90 days before the loan

WITH loan_features AS (
    SELECT
        l.loan_id,
        l.is_bad_loan,
        MIN(t.balance) AS min_balance
    FROM clean.loan AS l
    JOIN clean.trans AS t
        ON t.account_id = l.account_id
        AND t.trans_date >= l.loan_date - 90
        AND t.trans_date <  l.loan_date
    GROUP BY l.loan_id, l.is_bad_loan
)
SELECT
    CASE
        WHEN min_balance < 5000 THEN 'under 5000'
        WHEN min_balance < 10000 THEN 'between 5000 and 10000'
        WHEN min_balance < 20000 THEN 'between 10000 and 20000'
        ELSE '20000 and more'
    END AS min_balance_band,
    COUNT(*)                            AS total_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM loan_features
GROUP BY min_balance_band
ORDER BY MIN(min_balance);

-- Findings:
-- 1. In the 90 days before the loan, bad loans had a 32% lower average balance
--    (30,381 vs 44,928) and a 54% lower minimum balance (11,491 vs 25,050) than
--    good loans. Money coming in differed less (73,716 vs 87,874), so the gap is
--    driven more by spending than by income.
-- 2. The lowest balance gives a clear gradient: the bad loan rate falls from 59.1%
--    below 5,000 to 28.6%, 9.7% and 4.6% at 20,000 and more.
-- 3. Loans with a minimum balance below 5,000 are 6% of all loans (44) but 34% of
--    bad loans (26).
-- 4. Together with analysis 6, this shows that a lack of financial buffer before
--    the loan is the strongest risk signal in the data, far stronger than the loan
--    amount, age or region.
-- 5. All features use only transactions before the loan date, so they could be
--    used in a real credit decision.