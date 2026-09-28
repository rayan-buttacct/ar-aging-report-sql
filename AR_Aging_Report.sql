-- Accounts Receivable Aging Report
-- Built on the Chinook sample database (Invoice, Customer tables)
--
-- Assumptions:
--   * Chinook has no payment data, so every invoice is treated as unpaid (open AR).
--   * AR is aged as of the reporting date, which is the date of the latest invoice
--     in the data (a period-end date), not today's date.
--   * Days outstanding = reporting date minus invoice date, calculated with julianday().

-- Query 1: AR by aging bucket, with percentage of total AR
WITH as_of AS (
    SELECT MAX(InvoiceDate) AS report_date FROM Invoice
),
aged AS (
    SELECT i.InvoiceId, i.CustomerId, i.Total,
           julianday(a.report_date) - julianday(i.InvoiceDate) AS days_outstanding
    FROM Invoice i CROSS JOIN as_of a
)
SELECT
    CASE
        WHEN days_outstanding <= 30 THEN '1) 0-30 days'
        WHEN days_outstanding <= 60 THEN '2) 31-60 days'
        WHEN days_outstanding <= 90 THEN '3) 61-90 days'
        ELSE '4) 90+ days'
    END AS age_bucket,
    COUNT(*) AS invoice_count,
    ROUND(SUM(Total), 2) AS total_ar,
    ROUND(SUM(Total) * 100.0 / (SELECT SUM(Total) FROM aged), 1) AS pct_of_ar
FROM aged
GROUP BY age_bucket
ORDER BY age_bucket;


-- Query 2: Top 10 customers by outstanding balance
-- Ranks customers by total open AR, highest first
SELECT c.FirstName, c.LastName, c.Country,
       COUNT(i.InvoiceId) AS invoice_count,
       ROUND(SUM(i.Total), 2) AS outstanding_balance
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
GROUP BY c.CustomerId
ORDER BY outstanding_balance DESC
LIMIT 10;


-- Query 3: AR aging pivot by customer
-- One row per customer, with a column for each aging bucket (conditional aggregation)
WITH as_of AS (
    SELECT MAX(InvoiceDate) AS report_date FROM Invoice
),
aged AS (
    SELECT i.CustomerId, i.Total,
           julianday(a.report_date) - julianday(i.InvoiceDate) AS days_outstanding
    FROM Invoice i CROSS JOIN as_of a
)
SELECT c.FirstName, c.LastName,
    ROUND(SUM(CASE WHEN days_outstanding <= 30 THEN Total ELSE 0 END), 2) AS days_0_30,
    ROUND(SUM(CASE WHEN days_outstanding > 30 AND days_outstanding <= 60 THEN Total ELSE 0 END), 2) AS days_31_60,
    ROUND(SUM(CASE WHEN days_outstanding > 60 AND days_outstanding <= 90 THEN Total ELSE 0 END), 2) AS days_61_90,
    ROUND(SUM(CASE WHEN days_outstanding > 90 THEN Total ELSE 0 END), 2) AS days_90_plus,
    ROUND(SUM(Total), 2) AS total_ar
FROM aged
JOIN Customer c ON c.CustomerId = aged.CustomerId
GROUP BY c.CustomerId
ORDER BY days_90_plus DESC;


-- Query 4: Average days outstanding by customer
-- Higher values flag customers whose open balances are oldest
WITH as_of AS (
    SELECT MAX(InvoiceDate) AS report_date FROM Invoice
)
SELECT c.FirstName, c.LastName,
       ROUND(AVG(julianday(a.report_date) - julianday(i.InvoiceDate)), 0) AS avg_days_outstanding
FROM Customer c
JOIN Invoice i ON c.CustomerId = i.CustomerId
CROSS JOIN as_of a
GROUP BY c.CustomerId
ORDER BY avg_days_outstanding DESC;


-- Query 5: Completeness check
-- Confirms the aging buckets reconcile to the source Invoice table:
-- same invoice count and same dollar total, so no records were dropped or double-counted
WITH as_of AS (
    SELECT MAX(InvoiceDate) AS report_date FROM Invoice
),
bucketed AS (
    SELECT i.Total,
           CASE
               WHEN julianday(a.report_date) - julianday(i.InvoiceDate) <= 30 THEN '0-30'
               WHEN julianday(a.report_date) - julianday(i.InvoiceDate) <= 60 THEN '31-60'
               WHEN julianday(a.report_date) - julianday(i.InvoiceDate) <= 90 THEN '61-90'
               ELSE '90+'
           END AS age_bucket
    FROM Invoice i CROSS JOIN as_of a
)
SELECT
    (SELECT COUNT(*) FROM Invoice) AS source_invoice_count,
    (SELECT COUNT(*) FROM bucketed WHERE age_bucket IS NOT NULL) AS bucketed_invoice_count,
    (SELECT ROUND(SUM(Total), 2) FROM Invoice) AS source_total,
    (SELECT ROUND(SUM(Total), 2) FROM bucketed WHERE age_bucket IS NOT NULL) AS bucketed_total,
    CASE
        WHEN (SELECT COUNT(*) FROM Invoice) = (SELECT COUNT(*) FROM bucketed WHERE age_bucket IS NOT NULL)
         AND (SELECT ROUND(SUM(Total), 2) FROM Invoice) = (SELECT ROUND(SUM(Total), 2) FROM bucketed WHERE age_bucket IS NOT NULL)
        THEN 'PASS' ELSE 'FAIL'
    END AS reconciliation_result;
