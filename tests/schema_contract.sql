-- Database schema contract tests

DO $$
DECLARE
    actual_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO actual_count
    FROM column_schema_contract_report;

    IF actual_count <> 28 THEN
        RAISE EXCEPTION 'Expected 28 column contracts, found %', actual_count;
    END IF;

    SELECT COUNT(*)
    INTO actual_count
    FROM column_schema_contract_report
    WHERE contract_status <> 'MATCH';

    IF actual_count <> 0 THEN
        RAISE EXCEPTION
            'Expected every column contract to match, found % deviations',
            actual_count;
    END IF;

    SELECT COUNT(*)
    INTO actual_count
    FROM primary_key_contract_report;

    IF actual_count <> 4 THEN
        RAISE EXCEPTION 'Expected 4 primary key contracts, found %', actual_count;
    END IF;

    SELECT COUNT(*)
    INTO actual_count
    FROM primary_key_contract_report
    WHERE contract_status <> 'MATCH';

    IF actual_count <> 0 THEN
        RAISE EXCEPTION
            'Expected every primary key contract to match, found % deviations',
            actual_count;
    END IF;

    SELECT COUNT(*)
    INTO actual_count
    FROM index_contract_report;

    IF actual_count <> 4 THEN
        RAISE EXCEPTION 'Expected 4 index contracts, found %', actual_count;
    END IF;

    SELECT COUNT(*)
    INTO actual_count
    FROM index_contract_report
    WHERE contract_status <> 'MATCH';

    IF actual_count <> 0 THEN
        RAISE EXCEPTION
            'Expected every index contract to match, found % deviations',
            actual_count;
    END IF;
END
$$;

-- A partial index cannot satisfy a contract requiring full table coverage.
BEGIN;

DO $$
DECLARE
    index_contract RECORD;
BEGIN
    FOR index_contract IN
        SELECT * FROM (VALUES
            ('users_email_idx', 'users', 'email'),
            ('addresses_user_id_idx', 'addresses', 'user_id'),
            ('orders_user_id_idx', 'orders', 'user_id'),
            ('payments_order_id_idx', 'payments', 'order_id')
        ) AS contracts(index_name, table_name, column_name)
    LOOP
        EXECUTE FORMAT('DROP INDEX %I', index_contract.index_name);
        EXECUTE FORMAT(
            'CREATE INDEX %I ON %I (%I) WHERE %I IS NOT NULL',
            index_contract.index_name, index_contract.table_name,
            index_contract.column_name, index_contract.column_name
        );

        IF NOT EXISTS (
            SELECT 1 FROM index_contract_report
            WHERE index_name = index_contract.index_name
              AND contract_status = 'INDEX_DEFINITION_MISMATCH'
        ) THEN
            RAISE EXCEPTION 'Partial index % passed the full index contract',
                index_contract.index_name;
        END IF;

        EXECUTE FORMAT('DROP INDEX %I', index_contract.index_name);
        EXECUTE FORMAT(
            'CREATE INDEX %I ON %I (%I)',
            index_contract.index_name, index_contract.table_name,
            index_contract.column_name
        );

        IF NOT EXISTS (
            SELECT 1 FROM index_contract_report
            WHERE index_name = index_contract.index_name
              AND contract_status = 'MATCH'
        ) THEN
            RAISE EXCEPTION 'Restored full index % failed its contract',
                index_contract.index_name;
        END IF;
    END LOOP;
END
$$;

ROLLBACK;
