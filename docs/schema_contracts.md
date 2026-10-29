# Database Schema Contracts

Schema contracts make structural database changes visible during regression
testing. The lab checks column definitions, primary keys, and supporting indexes
before running view and query tests.

## Column contract

The `column_schema_contract_report` view compares the expected table structure
with PostgreSQL metadata from `information_schema.columns`.

It validates:

- Column presence.
- Column order.
- PostgreSQL data type.
- Character length.
- Numeric precision and scale.
- Nullability.

Possible results include `MATCH`, `MISSING_COLUMN`, `UNEXPECTED_COLUMN`,
`POSITION_MISMATCH`, `TYPE_MISMATCH`, and `NULLABILITY_MISMATCH`.

## Primary key contract

The `primary_key_contract_report` view compares expected primary key columns
with the constraints registered by PostgreSQL. It detects missing, unexpected,
or changed primary keys.

## Index contract

The `index_contract_report` view reads PostgreSQL index metadata from
`pg_index`, `pg_class`, `pg_namespace`, and `pg_attribute`. It verifies index
names, table ownership, ordered column lists, uniqueness, and full table coverage.
Replacing an expected full index with a partial index reports
`INDEX_DEFINITION_MISMATCH`, even when the name and indexed columns are unchanged.
Expression keys remain in the ordered column list as `NULL` entries. Replacing
an expected column index with an expression or mixed column/expression index
reports `INDEX_DEFINITION_MISMATCH`; additional expression indexes report
`UNEXPECTED_INDEX`.

The lab expects supporting indexes for:

- User email lookups.
- Address-to-user joins.
- Order-to-user joins.
- Payment-to-order joins.

Possible results include `MATCH`, `MISSING_INDEX`, `UNEXPECTED_INDEX`, and
`INDEX_DEFINITION_MISMATCH`.

## Review deviations

Run:

```bash
psql -d qa-sql-lab -f queries/schema_validation_queries.sql
```

The deviation result sets should be empty. The final result sets print the
complete current column and index contracts for migration review.

## Update after an intentional migration

1. Change the table definition in `datasets/schema.sql`.
2. Update the expected metadata in `datasets/views.sql`.
3. Update index definitions and expected metadata when access patterns change.
4. Update the expected contract counts when columns, tables, or indexes are
   added.
5. Add representative data and query coverage where needed.
6. Run `tests/run_all.sql` against an empty PostgreSQL database.

Keeping the schema definition and its contract in the same change makes
intentional migrations explicit and accidental drift easy to diagnose.
