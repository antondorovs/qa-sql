# Temporal Data Validation

Temporal validation checks whether related business events happened in a
possible order. A row can satisfy its data type and relationship checks while
still describing an impossible sequence of events.

## Rules

The data quality baseline includes eight temporal and retention rules:

- A deleted user must include a deletion timestamp.
- A non-deleted user cannot include a deletion timestamp.
- A deleted user cannot retain related orders or addresses.
- A user cannot be deleted before the user was created.
- An address cannot be created before its user.
- An order cannot be created before its user.
- A payment timestamp cannot precede its order.

Each rule has an expected issue count of zero. Any matching row is therefore a
regression that requires investigation.

## Run the checks

Load the lab and review temporal rule results:

```sql
SELECT
    rule_id,
    severity,
    actual_issue_count,
    baseline_status
FROM data_quality_rule_report
WHERE rule_id IN (
    'deleted_user_without_timestamp',
    'non_deleted_user_with_timestamp',
    'deleted_user_with_orders',
    'deleted_user_with_addresses',
    'user_deleted_before_created',
    'address_created_before_user',
    'order_created_before_user',
    'payment_created_before_order'
)
ORDER BY rule_id;
```

The detailed queries in `queries/qa_validation_queries.sql` return the affected
record identifiers and the timestamps relevant to each rule.

## Testing guidance

When adding a timestamped entity:

1. Identify the event that must happen first.
2. Join only records with an existing parent when checking event order.
3. Keep missing-parent checks as separate referential integrity rules.
4. Define the expected issue count explicitly.
5. Add an assertion to `tests/quality_report_contract.sql`.

Separating temporal and referential checks keeps each failure easy to diagnose.
