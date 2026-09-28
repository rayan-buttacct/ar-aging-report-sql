# Accounts Receivable Aging Report (SQL)

An independent project built on the [Chinook sample database](https://github.com/lerocha/chinook-database) to practice real-world accounting data analysis with SQL.

## What it does

The Chinook database models a digital media store, with `Customer` and `Invoice` tables that mirror a basic sales ledger. Chinook has no payment data, so this project treats every invoice as unpaid (open AR) and builds a standard AR aging analysis on top of it.

AR is aged **as of the reporting date**, defined as the date of the latest invoice in the data (a period-end date), not today's date.

1. **AR by aging bucket**: buckets open invoices into 0-30, 31-60, 61-90, and 90+ day ranges and calculates each bucket's share of total AR.
2. **Top 10 customers by outstanding balance**: ranks customers by total open AR, highest first.
3. **AR aging pivot by customer**: one row per customer, with a column for each aging bucket, using conditional aggregation (`SUM(CASE WHEN ...)`).
4. **Oldest open invoice by customer**: finds each customer's earliest unpaid invoice; the oldest dates flag the slowest payers.
5. **Completeness check**: reconciles the aging buckets back to the source `Invoice` table (invoice count and dollar total) to confirm no records were dropped or double-counted.

## Results (as of the latest invoice date)

| Aging bucket | Invoices | AR ($) | % of AR |
|---|---|---|---|
| 0-30 days | 7 | 38.62 | 1.7% |
| 31-60 days | 7 | 49.62 | 2.1% |
| 61-90 days | 7 | 37.62 | 1.6% |
| 90+ days | 391 | 2,202.74 | 94.6% |
| **Total** | **412** | **2,328.60** | **100%** |

- 94.6% of AR is more than 90 days old, and all 59 customers carry a 90+ day balance.
- Completeness check: 412 of 412 invoices and $2,328.60 of $2,328.60 reconcile to the source table (PASS).

## Fix log

The first version calculated age as `DATE('now') - invoicedate`. In SQLite that subtracts the leading year numbers of the two dates, not the days between them, so every invoice landed in the 0-30 day bucket (100% "current"). That failed a basic reasonableness check, since every invoice in the data is years old. The fix compares each invoice date to cutoff dates 30, 60, and 90 days before a fixed reporting date (using `DATE()` with a day offset), and ages AR from that period-end date instead of today.

## Skills used

- CTEs (`WITH`) for the aged invoices and bucket totals
- `DATE()` with day offsets for aging cutoffs
- Joins (`Customer` to `Invoice`)
- Aggregation (`SUM`, `COUNT`, `MIN`, `GROUP BY`)
- `CASE` statements for bucketing and pivoting
- Scalar subqueries (percentage of total AR, reconciliation)

## How to run it

1. Download the [Chinook SQLite database](https://github.com/lerocha/chinook-database).
2. Open it in any SQLite client (e.g. [DB Browser for SQLite](https://sqlitebrowser.org/), or the `sqlite3` CLI).
3. Run the queries in `AR_Aging_Report.sql`.
