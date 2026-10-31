\set ON_ERROR_STOP on

\echo 'Resetting database objects'
\ir ../datasets/reset.sql

\echo 'Creating schema and loading sample data'
\ir ../datasets/schema.sql
\ir ../datasets/seed_data.sql
\ir ../datasets/views.sql

\echo 'Checking dataset contracts'
\ir data_contract.sql

\echo 'Checking schema contracts'
\ir schema_contract.sql

\echo 'Checking view contracts'
\ir view_contract.sql
\ir address_coverage_contract.sql

\echo 'Checking data quality baseline'
\ir quality_report_contract.sql
\ir blank_value_contract.sql

\echo 'Running query smoke tests'
\ir ../queries/filters.sql
\ir ../queries/aggregations.sql
\ir ../queries/assertions.sql
\ir ../queries/case_expressions.sql
\ir ../queries/cte.sql
\ir ../queries/joins.sql
\ir ../queries/qa_validation_queries.sql
\ir ../queries/schema_validation_queries.sql
\ir ../queries/solutions.sql
\ir ../queries/subqueries.sql
\ir ../queries/tasks.sql
\ir ../queries/transactions.sql
\ir ../queries/window_functions.sql

\echo 'All PostgreSQL checks passed'
