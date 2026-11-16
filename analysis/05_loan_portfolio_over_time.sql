-- Question 5: How did the loan portfolio grow over time, and does the bad loan
-- rate change with the year the loan was granted?

-- 5a. New loans per year, running totals and year-over-year change
-- Note: 1993 covers only July to December (first loan in the data: July 1993)

WITH yearly AS(
    SELECT
        EXTRACT(YEAR FROM loan_date):: INTEGER AS loan_year,
        COUNT(*) AS new_loans,
        SUM(amount) AS new_amount
    FROM clean.loan
    GROUP BY loan_year
)
SELECT
    loan_year,
    new_loans,
    new_amount,
    SUM(new_loans) OVER (ORDER BY loan_year) AS cumulative_loans,
    SUM(new_amount) OVER (ORDER BY loan_year) AS cumulative_amount,
    ROUND(
         100.0 * (new_amount - LAG(new_amount) OVER (ORDER BY loan_year))
              / LAG(new_amount) OVER (ORDER BY loan_year),
        1
    ) AS amount_charge_pct
FROM yearly
ORDER BY loan_year;

-- 5b. Bad loan rate by loan year (vintage), with the share of loans already finished

SELECT
    EXTRACT(YEAR FROM loan_date):: INTEGER AS loan_year,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (WHERE is_finished) AS finished_loans,
    COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan
GROUP BY loan_year
ORDER BY loan_year;

-- Findings:
-- 1. The portfolio grew to 682 loans worth 103.3 million CZK. Lending accelerated
--    in 1996 (+37.3%) and 1997 (+67.8%), then fell by 19.1% in 1998.
-- 2. The +410.8% change in 1994 is misleading: 1993 covers only July to December,
--    so a full year is compared with half a year.
-- 3. Mature vintages (1994 to 1997) have a stable bad loan rate of 13.3% to 13.9%.
-- 4. The 1998 vintage shows only 2.5% because none of its loans has finished yet:
--    loans need time to go bad (seasoning effect). It is not a sign of better
--    lending.
-- 5. As a result, the overall rate of 11.1% (analysis 1) understates the risk.
--    Without the 1998 vintage it is 13.7% (72 bad loans out of 524).