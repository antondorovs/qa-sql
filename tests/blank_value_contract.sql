-- Blank-value rules must recognize whitespace beyond ordinary spaces.
BEGIN;

DO $$
DECLARE
    field_contract RECORD;
    blank_value TEXT;
    original_value TEXT;
BEGIN
    FOR field_contract IN
        SELECT * FROM (VALUES
            ('users', 'first_name', 'blank_user_name'),
            ('users', 'last_name', 'blank_user_name'),
            ('users', 'country', 'blank_user_country'),
            ('users', 'status', 'blank_user_status'),
            ('orders', 'order_number', 'blank_order_number'),
            ('orders', 'status', 'blank_order_status'),
            ('addresses', 'city', 'blank_address_city'),
            ('addresses', 'country', 'blank_address_country'),
            ('payments', 'status', 'blank_payment_status'),
            ('payments', 'payment_method', 'blank_payment_method')
        ) AS contracts(table_name, column_name, rule_id)
    LOOP
        EXECUTE FORMAT('SELECT %I FROM %I WHERE id = 1',
            field_contract.column_name, field_contract.table_name)
            INTO original_value;

        FOREACH blank_value IN ARRAY ARRAY['', '   ', E'\t', E'\n', E'\r', E' \t\n\r ']
        LOOP
            EXECUTE FORMAT('UPDATE %I SET %I = $1 WHERE id = 1',
                field_contract.table_name, field_contract.column_name)
                USING blank_value;

            IF NOT EXISTS (
                SELECT 1 FROM data_quality_rule_report
                WHERE rule_id = field_contract.rule_id
                  AND actual_issue_count = 1
            ) THEN
                RAISE EXCEPTION 'Blank value escaped detection for %.%',
                    field_contract.table_name, field_contract.column_name;
            END IF;
        END LOOP;

        EXECUTE FORMAT('UPDATE %I SET %I = $1 WHERE id = 1',
            field_contract.table_name, field_contract.column_name)
            USING E' \tx\n ';

        IF NOT EXISTS (
            SELECT 1 FROM data_quality_rule_report
            WHERE rule_id = field_contract.rule_id
              AND actual_issue_count = 0
        ) THEN
            RAISE EXCEPTION 'Non-blank text was classified as blank for %.%',
                field_contract.table_name, field_contract.column_name;
        END IF;

        EXECUTE FORMAT('UPDATE %I SET %I = $1 WHERE id = 1',
            field_contract.table_name, field_contract.column_name)
            USING original_value;
    END LOOP;
END
$$;

ROLLBACK;
