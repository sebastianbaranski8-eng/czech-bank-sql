-- Question 8: Is the balance after each transaction consistent with the previous
-- balance plus the transaction amount?

-- 8a. Check with transactions ordered by date, then by transaction id

WITH checked AS(
    SELECT
        account_id,
        trans_id,
        trans_date,
        signed_amount,
        balance,
        LAG(balance) OVER(
            PARTITION BY account_id
            ORDER BY trans_date, trans_id
        ) AS previous_balance
    FROM clean.trans
)
SELECT
    COUNT(*) AS checked_transactions,
    COUNT(*) FILTER (WHERE previous_balance + signed_amount = balance) AS balance_matches,
    ROUND(100.0 * COUNT(*) FILTER (WHERE previous_balance + signed_amount = balance)
          / COUNT(*), 1) AS match_pct
FROM checked
WHERE previous_balance IS NOT NULL;

-- 8b. Most common differences between the expected and the recorded balance

WITH checked AS (
    SELECT
        signed_amount,
        balance,
        LAG(balance) OVER(
            PARTITION BY account_id
            ORDER BY trans_date, trans_id
        ) AS previous_balance
    FROM clean.trans
)
SELECT
    balance - (previous_balance + signed_amount) AS difference,
    COUNT(*) AS transactions
FROM checked
WHERE previous_balance IS NOT NULL
    AND previous_balance + signed_amount <> balance
GROUP BY difference
ORDER BY transactions DESC
LIMIT 10;

-- 8c. Check with credits placed before debits within the same day
-- The day of a transaction is known, but not its time. Monthly statement fees
-- (mostly 14.60, 30.00 and 100.00) were recorded after interest credited on the
-- same day, so ordering by transaction id alone breaks the balance chain.

WITH checked AS(
    SELECT
        signed_amount,
        balance,
        LAG(balance) OVER(
            PARTITION BY account_id
            ORDER BY trans_date, signed_amount DESC, trans_id
        ) AS previous_balance
    FROM clean.trans
)
SELECT
    COUNT(*) AS checked_transactions,
    COUNT(*) FILTER (WHERE previous_balance + signed_amount = balance) AS exact_matches,
    ROUND(100.0 * COUNT(*) FILTER (WHERE previous_balance + signed_amount = balance)
          / COUNT(*), 1) AS exact_match_pct,
    COUNT(*) FILTER (WHERE ABS(balance - previous_balance - signed_amount) <= 0.10) AS matches_within_0_10,
    ROUND(100.0 * COUNT(*) FILTER (WHERE ABS(balance - previous_balance - signed_amount) <= 0.10)
          / COUNT(*), 1) AS match_within_0_10_pct
FROM checked
WHERE previous_balance IS NOT NULL;

-- Findings:
-- 1. With transactions ordered by date and transaction id (8a), only 49.5% of
--    balances match the previous balance plus the transaction amount.
-- 2. The most common gaps (8b) are -14.60, -30.00 and -100.00: the amounts of the
--    monthly statement fee. The fee is charged on the same day as interest is
--    credited, and the data have no time of day, so the order was wrong.
-- 3. Placing credits before debits within a day (8c) raises the exact match rate
--    to 88.7%, and to 92.9% when differences of up to 0.10 (likely rounding of
--    interest) are allowed.
-- 4. The remaining 74,407 transactions (7.1%) are not explained. They may come from
--    a more complex order within the day or from changes made during
--    anonymization. Balances should therefore be used with some caution.
-- 5. In window functions, ORDER BY is part of the logic: the same LAG() check gave
--    49.5% or 92.9% depending on the order of rows.