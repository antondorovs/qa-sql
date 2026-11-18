# CTEs and Views for QA

Common table expressions and views help turn complex validation logic into readable, reusable SQL.

## Common table expressions

A CTE is a named result set available to one SQL statement:

```sql
WITH paid_orders AS (
    SELECT *
    FROM orders
    WHERE status = 'PAID'
)
SELECT *
FROM paid_orders
WHERE amount > 100;
```

Use CTEs to split multi-step validation into understandable stages. A recursive CTE can generate rows such as a date range, which is useful for detecting days with missing activity.

## Views

A view stores a query definition and exposes it like a table:

```sql
SELECT *
FROM order_payment_validation
WHERE qa_status <> 'CONSISTENT';
```

Views are useful when the same QA report is run repeatedly. `CREATE OR REPLACE VIEW` updates the definition without requiring a separate drop statement.

The lab provides:

- `active_user_order_summary` for active-user order metrics.
- `primary_address_coverage_summary` for country-level primary address coverage.
- `country_user_order_summary` for country-level user and order coverage.
- `order_status_payment_summary` for payment coverage by order status.
- `order_payment_validation` for missing orders or users, payment status, and amount checks.
- `payment_method_summary` for checkout coverage by payment method.
- `data_quality_rule_summary` for severity-level data quality triage.

`PAID` and `SHIPPED` orders both require successful payments. Moving a paid
order to `SHIPPED` keeps a matching successful payment `CONSISTENT`; a pending,
failed, or refunded payment reports `PAYMENT_NOT_SUCCESSFUL`. Successful payments
on other order statuses report `ORDER_NOT_MARKED_PAID`. Missing records and
amount mismatches retain their earlier diagnostic priority.

For primary-address coverage, use
`active_users_without_primary_address_count` to identify active users who lack a
primary address. The view excludes users with a deletion timestamp.
`primary_address_count` counts address rows, so duplicate primary addresses can
make it equal to the active-user count while another user still lacks an address.
The coverage percentage counts distinct users across all included statuses.

To list countries with active-user gaps:

```sql
SELECT country, active_user_count, active_users_without_primary_address_count
FROM primary_address_coverage_summary
WHERE active_users_without_primary_address_count > 0
ORDER BY country;
```

Views do not store independent copies of these rows. Their results reflect the current data in the underlying tables.
