# QA SQL Lab

SQL learning repository focused on QA Engineering and PostgreSQL database validation practice.

## Purpose

This project is a small hands-on lab for learning SQL through realistic QA scenarios. It uses an e-commerce style dataset with users, addresses, orders, and payments.

The sample data includes both valid rows and intentional data quality problems, such as duplicate emails, orphan records, missing values, and invalid amounts.

## Structure

```text
datasets/
  reset.sql       -- drop lab views and tables
  schema.sql      -- create PostgreSQL tables
  seed_data.sql   -- insert sample data
  views.sql       -- create reusable QA views

docs/
  automated_validation.md
  data_quality_baselines.md
  domain_value_validation.md
  schema_contracts.md
  temporal_data_validation.md
  sql_basics.md
  qa_database_validation.md
  postgresql_qa_tips.md
  cte_and_views.md

tests/
  run_all.sql             -- complete PostgreSQL test runner
  data_contract.sql       -- sample data expectations
  quality_report_contract.sql -- data quality baseline expectations
  schema_contract.sql     -- table and primary key expectations
  view_contract.sql       -- reusable view expectations

queries/
  filters.sql
  aggregations.sql
  assertions.sql
  case_expressions.sql
  cte.sql
  joins.sql
  schema_validation_queries.sql
  subqueries.sql
  tasks.sql
  solutions.sql
  transactions.sql
  window_functions.sql
  qa_validation_queries.sql
```

## How to Run

From a PostgreSQL database:

```bash
psql -d qa-sql-lab -f datasets/reset.sql
psql -d qa-sql-lab -f datasets/schema.sql
psql -d qa-sql-lab -f datasets/seed_data.sql
psql -d qa-sql-lab -f datasets/views.sql
```

Then run examples or validation checks:

```bash
psql -d qa-sql-lab -f queries/qa_validation_queries.sql
```

## Automated Validation

Run the complete test suite against an empty PostgreSQL database:

```bash
psql -d qa-sql-lab -v ON_ERROR_STOP=1 -f tests/run_all.sql
```

The suite rebuilds the lab, checks expected data-quality scenarios and executes every query file. GitHub Actions runs the same suite for pushes and pull requests targeting `main`.

The hyphenated database name works directly with `psql`, `POSTGRES_DB`, and
`PGDATABASE`. When the name is used as an identifier inside a SQL statement,
quote it as `"qa-sql-lab"`.

GitLab CI runs the same PostgreSQL validation after changes reach the default
branch or a merge request. Both platforms use `tests/run_all.sql` as the single
test entry point.

## Data Quality Report

The `data_quality_rule_report` view provides a reusable baseline for known
training-data issues:

```sql
SELECT *
FROM data_quality_rule_report
ORDER BY severity, rule_id;
```

It distinguishes expected fixture counts from regressions and improvements.
See `docs/data_quality_baselines.md` for the rule format and extension workflow.
Completeness rules cover user ages, non-blank user names, user countries,
user statuses, order numbers, order statuses, payment methods, payment
statuses, address cities, address countries, and address postal codes.
Eligibility rules flag non-positive ages and active users below the minimum
account age.
Coverage rules flag active users without order history, countries without order
or primary-address coverage, countries with partial user order coverage, and
countries with incomplete active-user primary address coverage.
Uniqueness rules cover user emails and order numbers.
Format rules validate user email shape.
Temporal rules detect deletion status/timestamp mismatches, deleted-user order
or address links, and impossible creation, payment, and deletion event
sequences.
Domain rules validate status and payment-method fields against approved values.
Amount rules flag non-positive order or payment totals.
Relationship rules detect multiple primary addresses, orders with multiple
payment records, and address-country mismatches.
Payment lifecycle rules flag paid or shipped orders without successful payments,
cancelled orders without refunds, refunded payments on non-cancelled orders,
successful payments on non-payable orders, new or cancelled orders that still
have successful payments, successful, refunded, failed, or pending payments
without existing orders, refunded payments without timestamps, failed payments
with timestamps, and failed or pending payments on non-new orders. Pending
payments are expected to remain timestamp-free until settlement, and payment
methods keep at least one successful payment path.
The `data_quality_rule_summary` view aggregates rule counts and deviations by
severity for faster triage.
The `payment_method_summary` view aggregates checkout coverage by payment
method, including successful, failed, pending, and refunded outcomes with
their amounts, average payment size, and the unsettled balance requiring
follow-up, alongside timestamp coverage and its percentage.
The `payment_status_summary` view makes payment lifecycle totals, average
payment size, and timestamp coverage (including its percentage) easy to review
by status, including pending, failed, and refunded payments.
The `country_user_order_summary` view compares user and order coverage by
country, including the order coverage percentage for each country.
The `primary_address_coverage_summary` view shows primary address coverage by
country, including the coverage percentage for quick triage.
The `order_status_payment_summary` view compares payment coverage across order
statuses without double-counting orders that have multiple payment attempts.

## Schema Contracts

The test suite compares the live PostgreSQL schema with explicit contracts for
all 28 table columns, four primary keys, and four supporting indexes. This
catches missing or unexpected objects, type changes, nullability changes,
column reordering, primary key drift, and index definition drift.

Run `queries/schema_validation_queries.sql` to investigate differences. See
`docs/schema_contracts.md` for the migration workflow.

## Topics

- SQL basics
- Filtering and sorting
- Aggregations
- JOINs
- Subqueries
- Common table expressions
- Recursive CTEs
- PostgreSQL views
- CASE expressions
- Window functions
- Transaction safety
- Database schema contracts
- PostgreSQL index contracts
- Data quality checks
- Data quality baselines
- Domain value validation
- Temporal data validation
- QA database validation
- Automated SQL regression testing
- PostgreSQL practice

## Git Workflow

After completing a task:

```bash
git add .
git commit -m "Describe the SQL lab change"
git push origin main
git push gitlab main
```
