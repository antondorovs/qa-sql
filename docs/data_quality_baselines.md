# Data Quality Baselines

The `data_quality_rule_report` view turns reusable QA checks into a single
regression report. Each row represents one business rule and includes:

- A stable rule identifier and description.
- A severity level.
- The expected number of known issues in the training dataset.
- The current number of issues.
- The difference between current and expected results.
- A baseline status: `MATCH`, `REGRESSION`, or `IMPROVEMENT`.

## Why the baseline contains known issues

The sample dataset intentionally includes invalid records for SQL practice.
A clean result is therefore not always zero. The baseline records the expected
fixture count so that tests detect accidental changes without removing useful
QA scenarios.

Completeness rules cover required QA review fields such as user ages,
non-blank user names, user countries, user statuses, order numbers, order
statuses, payment methods, payment statuses, address cities, address
countries, and address postal codes.

Eligibility rules flag non-positive ages and active accounts that do not meet
the minimum review age.

Coverage rules flag active users that still have no order history, countries
with non-deleted users but no order or primary-address coverage, countries with
partial user order coverage, and countries where active-user primary address
coverage is incomplete.
The active-user primary address rule counts each country with an uncovered,
non-deleted active user once. Duplicate primary addresses and addresses owned by
inactive users cannot compensate for another user's missing primary address.

Uniqueness rules cover both user email addresses and order numbers.

Format rules validate user email shape before downstream notification or
identity checks consume the record.

The report also includes zero-tolerance temporal and retention rules. These
checks ensure that deleted users do not retain related orders or addresses and
that creation, payment, and deletion timestamps follow a valid business-event
sequence. See
`docs/temporal_data_validation.md` for the investigation workflow.

Domain value rules validate status and payment-method fields against approved
sets. See `docs/domain_value_validation.md` for the allowed values and review
workflow.

Amount rules flag non-positive order or payment totals before they reach
checkout and settlement reports.

Relationship rules also include zero-tolerance checks that each user has at
most one primary address, each order has at most one payment record, and that
an address country matches its user country.

Payment lifecycle rules compare order status and payment status so shipped
orders have successful payments, cancelled orders retain a refunded payment,
refunded payments belong to cancelled orders, successful payments stay tied to
paid or shipped orders, successful, refunded, failed, and pending payments stay
tied to existing order records, new or cancelled orders do not appear with
successful payments, and refunded payments retain their audit timestamp. Failed
payments stay tied to new orders and remain timestamp-free until a later
successful or refunded event exists, pending payments stay tied to new orders
and remain timestamp-free until settlement, and checkout methods retain at
least one successful payment path.

## Review the report

Load the schema, data, and views, then run:

```sql
SELECT *
FROM data_quality_rule_report
ORDER BY severity, rule_id;
```

For a compact severity-level triage view, run:

```sql
SELECT *
FROM data_quality_rule_summary
ORDER BY severity;
```

A `REGRESSION` means more suspicious records exist than expected. An
`IMPROVEMENT` means a known fixture disappeared. Both results require review
because either can make exercises and regression tests unreliable.

## Add a rule

1. Add a new branch to the `rule_results` CTE in `datasets/views.sql`.
2. Use a stable lowercase `rule_id`.
3. Set an explicit severity and expected issue count.
4. Add or update assertions in `tests/quality_report_contract.sql`.
5. Run `tests/run_all.sql` against an empty PostgreSQL database.

Keep detailed row-level investigation queries in
`queries/qa_validation_queries.sql`. The report is intended for fast triage;
the investigation queries provide the evidence behind each count.
