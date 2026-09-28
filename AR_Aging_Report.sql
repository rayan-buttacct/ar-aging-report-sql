-- Accounts Receivable Aging Report
-- Built on the Chinook sample database (Invoice, Customer tables)
--
-- Assumptions:
--   * Chinook has no payment data, so every invoice is treated as unpaid (open AR).
--   * AR is aged as of the reporting date, which is the latest invoice date in the data
--     (a period-end date), not today's date.
--   * Each invoice is bucketed by comparing its date to cutoff dates
--     30, 60, and 90 days before the reporting date.

-- Query 1: AR by aging bucket, with percentage of total AR
WITH aged AS (
    SELECT InvoiceId, CustomerId, InvoiceDate, Total,
           (SELECT MAX(InvoiceDate) FROM Invoice) AS report_date
    FROM Invoice
)
SELECT
    CASE
        WHEN InvoiceDate >= DATE(report_date, '-30 days') THEN '1) 0-30 days'
        WHEN InvoiceDate >= DATE(report_date, '-60 days') THEN '2) 31-60 days'
        WHEN InvoiceDate >= DATE(report_date, '-90 days') THEN '3) 61-90 days'
        ELSE '4) 90+ days'
    END AS age_bucket,
    COUNT(*) AS invoice_count,
    ROUND(SUM(Total), 2) AS total_ar,
    ROUND(SUM(Total) * 100.0 / (SELECT SUM(Total) FROM Invoice), 1) AS pct_of_ar
FROM aged
GROUP BY age_bucket
ORDER BY age_bucket;


-- Query 2: Top 10 customers by outstanding balance
-- Ranks customers by total open AR, highest first
SELECT Customer.FirstName, Customer.LastName, Customer.Country,
       COUNT(Invoice.InvoiceId) AS invoice_count,
       ROUND(SUM(Invoice.Total), 2) AS outstanding_balance
FROM Customer
JOIN Invoice ON Customer.CustomerId = Invoice.CustomerId
GROUP BY Customer.CustomerId
ORDER BY outstanding_balance DESC
LIMIT 10;


-- Query 3: AR aging pivot by customer
-- One row per customer, with a column for each aging bucket (conditional aggregation)
WITH aged AS (
    SELECT CustomerId, Total,
        CASE
            WHEN InvoiceDate >= DATE((SELECT MAX(InvoiceDate) FROM Invoice), '-30 days') THEN '0-30'
            WHEN InvoiceDate >= DATE((SELECT MAX(InvoiceDate) FROM Invoice), '-60 days') THEN '31-60'
            WHEN InvoiceDate >= DATE((SELECT MAX(InvoiceDate) FROM Invoice), '-90 days') THEN '61-90'
            ELSE '90+'
        END AS age_bucket
    FROM Invoice
)
SELECT Customer.FirstName, Customer.LastName,
    ROUND(SUM(CASE WHEN age_bucket = '0-30' THEN Total ELSE 0 END), 2) AS days_0_30,
    ROUND(SUM(CASE WHEN age_bucket = '31-60' THEN Total ELSE 0 END), 2) AS days_31_60,
    ROUND(SUM(CASE WHEN age_bucket = '61-90' THEN Total ELSE 0 END), 2) AS days_61_90,
    ROUND(SUM(CASE WHEN age_bucket = '90+' THEN Total ELSE 0 END), 2) AS days_90_plus,
    ROUND(SUM(Total), 2) AS total_ar
FROM aged
JOIN Customer ON Customer.CustomerId = aged.CustomerId
GROUP BY Customer.CustomerId
ORDER BY days_90_plus DESC;


-- Query 4: Oldest open invoice by customer
-- Earliest unpaid invoice date for each customer; the oldest dates flag the slowest payers
SELECT Customer.FirstName, Customer.LastName,
       MIN(Invoice.InvoiceDate) AS oldest_open_invoice,
       COUNT(Invoice.InvoiceId) AS open_invoices
FROM Customer
JOIN Invoice ON Customer.CustomerId = Invoice.CustomerId
GROUP BY Customer.CustomerId
ORDER BY oldest_open_invoice ASC
LIMIT 10;


-- Query 5: Completeness check
-- Adds up the aging buckets and compares them to the source Invoice table.
-- If the invoice count and dollar total both match, no records were dropped or double-counted.
WITH aged AS (
    SELECT Total,
        CASE
            WHEN InvoiceDate >= DATE((SELECT MAX(InvoiceDate) FROM Invoice), '-30 days') THEN '0-30'
            WHEN InvoiceDate >= DATE((SELECT MAX(InvoiceDate) FROM Invoice), '-60 days') THEN '31-60'
            WHEN InvoiceDate >= DATE((SELECT MAX(InvoiceDate) FROM Invoice), '-90 days') THEN '61-90'
            ELSE '90+'
        END AS age_bucket
    FROM Invoice
),
bucket_totals AS (
    SELECT age_bucket, COUNT(*) AS invoice_count, SUM(Total) AS bucket_total
    FROM aged
    GROUP BY age_bucket
)
SELECT
    (SELECT COUNT(*) FROM Invoice) AS source_invoice_count,
    SUM(invoice_count) AS bucketed_invoice_count,
    (SELECT ROUND(SUM(Total), 2) FROM Invoice) AS source_total,
    ROUND(SUM(bucket_total), 2) AS bucketed_total,
    CASE
        WHEN SUM(invoice_count) = (SELECT COUNT(*) FROM Invoice)
         AND ROUND(SUM(bucket_total), 2) = (SELECT ROUND(SUM(Total), 2) FROM Invoice)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS reconciliation_result
FROM bucket_totals;
