-- Question 2: Does the risk of a loan depend on the region and the local economy?
-- Region data come from the district of the bank branch that holds the account

-- 2a. Bad loan rate by region

SELECT
    d.region,
    COUNT(*) AS total_loans,
    COUNT(*) FILTER (WHERE l.is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE l.is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan AS l
JOIN clean.account AS a ON a.account_id = l.account_id
JOIN clean.district AS d ON d.district_id = a.district_id
GROUP BY d.region
ORDER BY bad_loan_rate_pct DESC;

-- 2b. Bad loan rate by district unemployment rate (1996)

SELECT
    CASE
        WHEN d.unemployment_rate_1996 < 2 THEN 'under 2%'
        WHEN d.unemployment_rate_1996 < 4 THEN '2% - 4%'
        WHEN d.unemployment_rate_1996 < 6 THEN '4% - 6%'
        ELSE '6% and more'
    END AS unemployment_band,
    COUNT(*)                              AS total_loans,
    COUNT(*) FILTER (WHERE l.is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE l.is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan AS l
JOIN clean.account AS a ON a.account_id = l.account_id
JOIN clean.district AS d ON d.district_id = a.district_id
GROUP BY unemployment_band 
ORDER BY MIN(d.unemployment_rate_1996);

-- 2c. Bad loan rate by district average salary

SELECT
    CASE
        WHEN d.avg_salary < 8500 THEN 'under 8500'
        WHEN d.avg_salary < 9500 THEN '8500-9500'
        ELSE '9500 and more'
    END AS salary_band,
    COUNT(*)                              AS total_loans,
    COUNT(*) FILTER (WHERE l.is_bad_loan) AS bad_loans,
    ROUND(100.0 * COUNT(*) FILTER (WHERE l.is_bad_loan) / COUNT(*), 1) AS bad_loan_rate_pct
FROM clean.loan AS l
JOIN clean.account AS a ON a.account_id = l.account_id
JOIN clean.district AS d ON d.district_id = a.district_id
GROUP BY salary_band
ORDER BY MIN(d.avg_salary);


-- Findings:
-- 1. Bad loan rates differ between regions, from 1.6% (north Bohemia) to 15.8%
--    (west Bohemia), but groups are small (57 to 129 loans). North Bohemia has
--    only 1 bad loan out of 61, so most of these differences may be chance.
-- 2. District unemployment shows no clear pattern: 9.1% below 2% unemployment,
--    and 11.1% to 12.6% in all higher bands, with no rising trend.
-- 3. Districts with higher average salaries have slightly fewer bad loans
--    (12.6%, 11.2%, 10.3%), but the gap is small and may also be chance.
-- 4. Regional factors explain much less of the risk than the loan amount
--    (analysis 1). The characteristics of the loan and the client matter more
--    than the location of the bank branch.