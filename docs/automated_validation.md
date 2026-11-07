# Automated PostgreSQL Validation

The repository includes a repeatable test suite that creates the lab from scratch and validates it against PostgreSQL.

## What is tested

- Schema and seed scripts execute without errors.
- Dataset row counts match the documented sample data.
- Intentional QA defects remain available for exercises.
- Reusable views return stable columns and expected classifications.
- Address coverage counts users once when duplicate primary addresses exist,
  excludes deleted users and orphan addresses, and retains users without addresses.
- Every SQL example and solution executes successfully.

The checks treat the known bad records as test fixtures. A duplicate email or orphan payment is expected in this lab, so the tests verify that each scenario exists exactly once.

## Run locally

Create an empty PostgreSQL database and run:

```bash
psql -d qa-sql-lab -v ON_ERROR_STOP=1 -f tests/run_all.sql
```

The runner resets the lab tables and views and loads the sample data in one
transaction. If setup fails, PostgreSQL rolls back that reset and load. A
successful setup replaces the lab data, so use a disposable database.

## Continuous integration

GitHub Actions starts PostgreSQL 16 and runs the same `tests/run_all.sql` entry point for every push and pull request targeting `main`.

When a SQL statement fails or a dataset contract changes unexpectedly, `psql` exits with an error and the workflow fails.

GitLab CI runs the same SQL suite. Its database readiness wait is limited to
60 seconds, with a further five seconds before forced termination if needed.
An unavailable PostgreSQL service therefore fails the job instead of waiting
indefinitely and holding a runner until the overall job timeout.
