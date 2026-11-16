-- Question 6: Does a history of negative balances on the account, shown by
-- penalty interest, predict that a loan will go bad?

-- 6a. Bad loan rate for loans whose account was charged penalty interest
-- before the loan date

SELECT
    CASE 
        WHEN EXISTS(
            SELECT 1
            FROM clean.trans AS t
            WHERE t.account_id = l.account_id
                AND t.payment_purpose = 'penalty interest'
                AND t.trans_date < l.loan_date
        )
        THEN 'penalty before loan'
        ELSE 'no penalty before loan'
    END AS penalty_history,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan AS l
GROUP BY penalty_history;

-- 6b. The same analysis WITHOUT the date condition (penalty at any time)
-- This version is wrong for prediction: penalties charged after the loan date
-- are a consequence of non-payment, not a warning sign known in advance

SELECT
    CASE
        WHEN EXISTS(
            SELECT 1
            FROM clean.trans AS t
            WHERE t.account_id = l.account_id
                AND t.payment_purpose = 'penalty interest'
        )
        THEN 'penalty at any time'
        ELSE 'no penalty at any time'
    END AS penalty_history,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER(WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan AS l
GROUP BY penalty_history;

-- Findings:
-- 1. Penalty interest before the loan date is the strongest warning sign found:
--    26 of 29 such loans went bad (89.7%), against 7.7% for the other 653 loans.
-- 2. Rejecting these 29 applications would have avoided 26 of the 76 bad loans
--    (about a third) at the cost of only 3 good loans.
-- 3. Without the date condition (6b), the indicator seems almost perfect (72 of 76
--    bad loans caught, 0.7% bad loans without penalties). This is target leakage:
--    penalties charged after the loan date are a result of non-payment and are not
--    known when the loan is granted, so they cannot be used to predict it.
-- 4. Any feature used to assess a loan must be measured on or before the loan date.