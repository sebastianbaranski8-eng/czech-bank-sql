-- Question 4: Which regions and districts have the highest share of bad loans?

-- 4a. Ranking of regions by bad loan rate, with each region's share of all loans

WITH region_stats AS(
    SELECT
        region,
        COUNT(*) AS total_loans,
        COUNT(*) FILTER(WHERE is_bad_loan) AS bad_loans
    FROM clean.loan_overview
    GROUP BY region
)
SELECT
    RANK() OVER (ORDER BY 1.0 * bad_loans / total_loans DESC) AS risk_rank,
    region,
    total_loans,
    ROUND(100.0 * total_loans / SUM(total_loans) OVER (), 1)  AS share_of_loans_pct,
    bad_loans,
    ROUND(100.0 * bad_loans / total_loans, 1)                 AS bad_loan_rate_pct
FROM region_stats
ORDER BY risk_rank;

-- 4b. Ranking of districts with at least 10 loans
-- Smaller districts are excluded: with only a few loans, a single bad loan
-- would put a district at the top of the ranking by chance

WITH district_stats AS(
    SELECT
        district_name,
        region,
        COUNT(*) AS total_loans,
        COUNT(*) FILTER(WHERE is_bad_loan) AS bad_loans
    FROM clean.loan_overview
    GROUP BY district_name, region
    HAVING COUNT(*) >= 10
)

SELECT
    RANK() OVER (ORDER BY 1.0 * bad_loans / total_loans DESC) AS rank_with_gaps,
    DENSE_RANK() OVER (ORDER BY 1.0 * bad_loans / total_loans DESC) AS rank_without_gaps,
    ROW_NUMBER() OVER (ORDER BY 1.0 * bad_loans / total_loans DESC, district_name) AS row_num,
    district_name,
    region,
    total_loans,
    bad_loans,
    ROUND(100.0 * bad_loans / total_loans, 1) AS bad_loan_rate_pct
FROM district_stats
ORDER BY row_num;

-- 4c. Riskiest district within each region (districts with at least 10 loans)
WITH district_stats AS(
    SELECT
        district_name,
        region,
        COUNT(*) AS total_loans,
        COUNT(*) FILTER (WHERE is_bad_loan) AS bad_loans
    FROM clean.loan_overview
    GROUP BY district_name, region
    HAVING COUNT(*) >= 10
),
ranked AS(
    SELECT
        region,
        district_name,
        total_loans,
        bad_loans,
        RANK() OVER (PARTITION BY region ORDER BY 1.0 * bad_loans / total_loans DESC) AS rank_in_region
    FROM district_stats
)
SELECT
    region,
    district_name,
    bad_loans,
    ROUND(100.0 * bad_loans / total_loans, 1) AS bad_loan_rate_pct
FROM ranked
WHERE rank_in_region = 1
ORDER BY bad_loan_rate_pct DESC;


-- Findings:
-- 1. Region ranking by bad loan rate: west Bohemia (15.8%), north Moravia (15.4%)
--    and south Bohemia (15.0%) are the riskiest, north Bohemia is the lowest (1.6%).
-- 2. The rate alone is misleading: north Moravia holds 17.2% of all loans and 18 of
--    the 76 bad loans (almost a quarter), while west Bohemia has only 9. For the
--    bank, north Moravia is the main concentration of risk.
-- 3. Only 17 of 77 districts have at least 10 loans. Among them, three of the five
--    riskiest are in north Moravia (Ostrava, Olomouc, Karvina). The cities of Brno
--    and Ostrava rank high, while Prague is below average (8.3%).
-- 4. West Bohemia has no district with at least 10 loans, so it is missing from the
--    per-region ranking in 4c. District-level results rely on very small samples.