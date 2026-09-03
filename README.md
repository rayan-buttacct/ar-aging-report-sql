# Accounts Receivable Aging Report (SQL)

An independent project built on the [Chinook sample database](https://github.com/lerocha/chinook-database) to practice real-world accounting/finance data analysis with SQL.

## What it does

The Chinook database models a digital media store, with `Customer` and `Invoice` tables that mirror a basic sales ledger. This project treats unpaid invoices like outstanding receivables and builds a standard AR aging analysis on top of them:

1. **AR by aging bucket** — buckets all outstanding invoices into 0–30, 31–60, 61–90, and 90+ day ranges, and calculates what percentage of total AR each bucket represents.
2. **Top 10 delinquent customers** — ranks customers by total outstanding balance, highest first.
3. **AR aging pivot by customer** — one row per customer, with a column for each aging bucket, using conditional aggregation (`SUM(CASE WHEN ...)`).
4. **Average days outstanding by customer** — flags which customers are consistently slow to pay.

## Skills used

- Joins (`Customer` to `Invoice`)
- Aggregation (`SUM`, `AVG`, `GROUP BY`)
- `CASE` statements for bucketing and pivoting
- A scalar subquery (percentage of total AR)
- Sorting/ranking with `ORDER BY` and `LIMIT`

## Files

- `AR_Aging_Report.sql` — all four queries, commented

## How to run it

1. Download the [Chinook SQLite database](https://github.com/lerocha/chinook-database) (or any SQL engine's version of it).
2. Open it in any SQLite client (e.g. [DB Browser for SQLite](https://sqlitebrowser.org/), or the `sqlite3` CLI).
3. Run the queries in `AR_Aging_Report.sql`.

## Notes

This was a self-study project done while learning SQL from the ground up (SQLBolt lessons, then this capstone). Window functions and CTEs were learned separately as part of the same study track but aren't used in these specific queries.
