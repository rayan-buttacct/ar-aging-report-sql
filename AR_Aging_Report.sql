-- Accounts Receivable Aging Report
-- Built on the Chinook sample database (Invoice, Customer tables)

-- Query 1: AR by aging bucket, with percentage of total AR
-- Shows total outstanding AR in each bucket and what share of total AR it represents
SELECT
    CASE
        WHEN (DATE('now') - invoicedate) <= 30 THEN '0-30 days'
        WHEN (DATE('now') - invoicedate) > 30 AND (DATE('now') - invoicedate) <= 60 THEN '31-60 days'
        WHEN (DATE('now') - invoicedate) > 60 AND (DATE('now') - invoicedate) <= 90 THEN '61-90 days'
        ELSE '90+ days'
    END AS age_bucket,
    SUM(total) AS total_sum,
    SUM(total) * 100.0 / (SELECT SUM(total) FROM Invoice) AS percentage
FROM Invoice
GROUP BY age_bucket;


-- Query 2: Top 10 delinquent customers
-- Ranks customers by total outstanding balance, highest first
SELECT firstname, lastname, SUM(total) AS total_spent
FROM Customer
JOIN Invoice ON Customer.CustomerId = Invoice.CustomerId
GROUP BY firstname, lastname
ORDER BY total_spent DESC
LIMIT 10;


-- Query 3: AR aging pivot by customer
-- One row per customer, with a column for each aging bucket (conditional aggregation)
SELECT firstname, lastname,
    SUM(CASE WHEN (DATE('now') - invoicedate) <= 30 THEN total ELSE 0 END) AS current,
    SUM(CASE WHEN (DATE('now') - invoicedate) > 30 AND (DATE('now') - invoicedate) <= 60 THEN total ELSE 0 END) AS days_31_60,
    SUM(CASE WHEN (DATE('now') - invoicedate) > 60 AND (DATE('now') - invoicedate) <= 90 THEN total ELSE 0 END) AS days_61_90,
    SUM(CASE WHEN (DATE('now') - invoicedate) > 90 THEN total ELSE 0 END) AS days_91_plus
FROM Invoice
JOIN Customer ON Customer.CustomerId = Invoice.CustomerId
GROUP BY firstname, lastname
ORDER BY current DESC;


-- Query 4: Average days outstanding by customer
-- Shows each customer's average invoice age; higher values flag slower-paying customers
SELECT firstname, lastname, AVG(DATE('now') - invoicedate) AS avg_days_old
FROM Customer
JOIN Invoice ON Customer.CustomerId = Invoice.CustomerId
GROUP BY firstname, lastname
ORDER BY avg_days_old DESC;
