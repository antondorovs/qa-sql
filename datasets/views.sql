-- Reusable PostgreSQL views for QA SQL Lab

CREATE OR REPLACE VIEW column_schema_contract_report AS
WITH expected_columns (
    table_name,
    column_name,
    ordinal_position,
    data_type,
    character_maximum_length,
    numeric_precision,
    numeric_scale,
    is_nullable
) AS (
    VALUES
        ('users', 'id', 1, 'integer', NULL, 32, 0, 'NO'),
        ('users', 'first_name', 2, 'character varying', 50, NULL, NULL, 'NO'),
        ('users', 'last_name', 3, 'character varying', 50, NULL, NULL, 'NO'),
        ('users', 'email', 4, 'character varying', 120, NULL, NULL, 'NO'),
        ('users', 'status', 5, 'character varying', 20, NULL, NULL, 'NO'),
        ('users', 'country', 6, 'character varying', 60, NULL, NULL, 'NO'),
        ('users', 'age', 7, 'integer', NULL, 32, 0, 'YES'),
        (
            'users',
            'created_at',
            8,
            'timestamp without time zone',
            NULL,
            NULL,
            NULL,
            'NO'
        ),
        (
            'users',
            'deleted_at',
            9,
            'timestamp without time zone',
            NULL,
            NULL,
            NULL,
            'YES'
        ),
        ('addresses', 'id', 1, 'integer', NULL, 32, 0, 'NO'),
        ('addresses', 'user_id', 2, 'integer', NULL, 32, 0, 'YES'),
        ('addresses', 'city', 3, 'character varying', 80, NULL, NULL, 'NO'),
        ('addresses', 'country', 4, 'character varying', 60, NULL, NULL, 'NO'),
        ('addresses', 'postal_code', 5, 'character varying', 20, NULL, NULL, 'YES'),
        ('addresses', 'is_primary', 6, 'boolean', NULL, NULL, NULL, 'NO'),
        (
            'addresses',
            'created_at',
            7,
            'timestamp without time zone',
            NULL,
            NULL,
            NULL,
            'NO'
        ),
        ('orders', 'id', 1, 'integer', NULL, 32, 0, 'NO'),
        ('orders', 'user_id', 2, 'integer', NULL, 32, 0, 'YES'),
        ('orders', 'order_number', 3, 'character varying', 30, NULL, NULL, 'NO'),
        ('orders', 'status', 4, 'character varying', 20, NULL, NULL, 'NO'),
        ('orders', 'amount', 5, 'numeric', NULL, 10, 2, 'NO'),
        (
            'orders',
            'created_at',
            6,
            'timestamp without time zone',
            NULL,
            NULL,
            NULL,
            'NO'
        ),
        ('payments', 'id', 1, 'integer', NULL, 32, 0, 'NO'),
        ('payments', 'order_id', 2, 'integer', NULL, 32, 0, 'YES'),
        (
            'payments',
            'payment_method',
            3,
            'character varying',
            30,
            NULL,
            NULL,
            'NO'
        ),
        ('payments', 'status', 4, 'character varying', 20, NULL, NULL, 'NO'),
        ('payments', 'amount', 5, 'numeric', NULL, 10, 2, 'NO'),
        (
            'payments',
            'paid_at',
            6,
            'timestamp without time zone',
            NULL,
            NULL,
            NULL,
            'YES'
        )
),
actual_columns AS (
    SELECT
        table_name::TEXT,
        column_name::TEXT,
        ordinal_position::INTEGER,
        data_type::TEXT,
        character_maximum_length::INTEGER,
        numeric_precision::INTEGER,
        numeric_scale::INTEGER,
        is_nullable::TEXT
    FROM information_schema.columns
    WHERE table_schema = CURRENT_SCHEMA()
      AND table_name IN ('users', 'addresses', 'orders', 'payments')
)
SELECT
    COALESCE(e.table_name, a.table_name) AS table_name,
    COALESCE(e.column_name, a.column_name) AS column_name,
    e.ordinal_position AS expected_ordinal_position,
    a.ordinal_position AS actual_ordinal_position,
    e.data_type AS expected_data_type,
    a.data_type AS actual_data_type,
    e.character_maximum_length AS expected_character_maximum_length,
    a.character_maximum_length AS actual_character_maximum_length,
    e.numeric_precision AS expected_numeric_precision,
    a.numeric_precision AS actual_numeric_precision,
    e.numeric_scale AS expected_numeric_scale,
    a.numeric_scale AS actual_numeric_scale,
    e.is_nullable AS expected_is_nullable,
    a.is_nullable AS actual_is_nullable,
    CASE
        WHEN e.column_name IS NULL THEN 'UNEXPECTED_COLUMN'
        WHEN a.column_name IS NULL THEN 'MISSING_COLUMN'
        WHEN e.ordinal_position IS DISTINCT FROM a.ordinal_position
            THEN 'POSITION_MISMATCH'
        WHEN e.data_type IS DISTINCT FROM a.data_type
            OR e.character_maximum_length
                IS DISTINCT FROM a.character_maximum_length
            OR e.numeric_precision IS DISTINCT FROM a.numeric_precision
            OR e.numeric_scale IS DISTINCT FROM a.numeric_scale
            THEN 'TYPE_MISMATCH'
        WHEN e.is_nullable IS DISTINCT FROM a.is_nullable
            THEN 'NULLABILITY_MISMATCH'
        ELSE 'MATCH'
    END AS contract_status
FROM expected_columns e
FULL OUTER JOIN actual_columns a
    ON e.table_name = a.table_name
   AND e.column_name = a.column_name;

CREATE OR REPLACE VIEW primary_key_contract_report AS
WITH expected_primary_keys (table_name, column_name, ordinal_position) AS (
    VALUES
        ('users', 'id', 1),
        ('addresses', 'id', 1),
        ('orders', 'id', 1),
        ('payments', 'id', 1)
),
actual_primary_keys AS (
    SELECT
        tc.table_name::TEXT,
        kcu.column_name::TEXT,
        kcu.ordinal_position::INTEGER
    FROM information_schema.table_constraints tc
    INNER JOIN information_schema.key_column_usage kcu
        ON tc.constraint_catalog = kcu.constraint_catalog
       AND tc.constraint_schema = kcu.constraint_schema
       AND tc.constraint_name = kcu.constraint_name
    WHERE tc.table_schema = CURRENT_SCHEMA()
      AND tc.constraint_type = 'PRIMARY KEY'
      AND tc.table_name IN ('users', 'addresses', 'orders', 'payments')
)
SELECT
    COALESCE(e.table_name, a.table_name) AS table_name,
    e.column_name AS expected_column_name,
    a.column_name AS actual_column_name,
    e.ordinal_position AS expected_ordinal_position,
    a.ordinal_position AS actual_ordinal_position,
    CASE
        WHEN e.table_name IS NULL THEN 'UNEXPECTED_PRIMARY_KEY'
        WHEN a.table_name IS NULL THEN 'MISSING_PRIMARY_KEY'
        WHEN e.column_name IS DISTINCT FROM a.column_name
            OR e.ordinal_position IS DISTINCT FROM a.ordinal_position
            THEN 'PRIMARY_KEY_MISMATCH'
        ELSE 'MATCH'
    END AS contract_status
FROM expected_primary_keys e
FULL OUTER JOIN actual_primary_keys a
    ON e.table_name = a.table_name
   AND e.column_name = a.column_name;

CREATE OR REPLACE VIEW index_contract_report AS
WITH expected_indexes (
    index_name,
    table_name,
    indexed_columns,
    is_unique
) AS (
    VALUES
        ('users_email_idx', 'users', ARRAY['email']::TEXT[], FALSE),
        (
            'addresses_user_id_idx',
            'addresses',
            ARRAY['user_id']::TEXT[],
            FALSE
        ),
        ('orders_user_id_idx', 'orders', ARRAY['user_id']::TEXT[], FALSE),
        (
            'payments_order_id_idx',
            'payments',
            ARRAY['order_id']::TEXT[],
            FALSE
        )
),
actual_indexes AS (
    SELECT
        index_class.relname::TEXT AS index_name,
        table_class.relname::TEXT AS table_name,
        ARRAY_AGG(
            attribute.attname::TEXT
            ORDER BY index_column.ordinality
        ) AS indexed_columns,
        index_metadata.indisunique AS is_unique
    FROM pg_index index_metadata
    INNER JOIN pg_class table_class
        ON table_class.oid = index_metadata.indrelid
    INNER JOIN pg_namespace table_namespace
        ON table_namespace.oid = table_class.relnamespace
    INNER JOIN pg_class index_class
        ON index_class.oid = index_metadata.indexrelid
    CROSS JOIN LATERAL UNNEST(index_metadata.indkey)
        WITH ORDINALITY AS index_column(attribute_number, ordinality)
    INNER JOIN pg_attribute attribute
        ON attribute.attrelid = table_class.oid
       AND attribute.attnum = index_column.attribute_number
    WHERE table_namespace.nspname = CURRENT_SCHEMA()
      AND table_class.relname IN ('users', 'addresses', 'orders', 'payments')
      AND index_metadata.indisprimary = FALSE
    GROUP BY
        index_class.relname,
        table_class.relname,
        index_metadata.indisunique
)
SELECT
    COALESCE(e.index_name, a.index_name) AS index_name,
    e.table_name AS expected_table_name,
    a.table_name AS actual_table_name,
    e.indexed_columns AS expected_indexed_columns,
    a.indexed_columns AS actual_indexed_columns,
    e.is_unique AS expected_is_unique,
    a.is_unique AS actual_is_unique,
    CASE
        WHEN e.index_name IS NULL THEN 'UNEXPECTED_INDEX'
        WHEN a.index_name IS NULL THEN 'MISSING_INDEX'
        WHEN e.table_name IS DISTINCT FROM a.table_name
            OR e.indexed_columns IS DISTINCT FROM a.indexed_columns
            OR e.is_unique IS DISTINCT FROM a.is_unique
            THEN 'INDEX_DEFINITION_MISMATCH'
        ELSE 'MATCH'
    END AS contract_status
FROM expected_indexes e
FULL OUTER JOIN actual_indexes a
    ON e.index_name = a.index_name;

CREATE OR REPLACE VIEW active_user_order_summary AS
SELECT
    u.id AS user_id,
    u.email,
    u.country,
    COUNT(o.id) AS order_count,
    COALESCE(SUM(o.amount), 0.00) AS total_order_amount,
    MAX(o.created_at) AS latest_order_at
FROM users u
LEFT JOIN orders o
    ON u.id = o.user_id
WHERE u.status = 'ACTIVE'
  AND u.deleted_at IS NULL
GROUP BY u.id, u.email, u.country;

CREATE OR REPLACE VIEW primary_address_coverage_summary AS
SELECT
    u.country,
    COUNT(*) AS user_count,
    COUNT(*) FILTER (WHERE u.status = 'ACTIVE') AS active_user_count,
    COUNT(a.id) AS primary_address_count,
    COUNT(*) FILTER (WHERE a.id IS NULL) AS users_without_primary_address_count,
    ROUND(100.0 * COUNT(a.id) / NULLIF(COUNT(*), 0), 2)
        AS primary_address_coverage_percent
FROM users u
LEFT JOIN addresses a
    ON u.id = a.user_id
   AND a.is_primary = TRUE
WHERE u.deleted_at IS NULL
GROUP BY u.country;

CREATE OR REPLACE VIEW country_user_order_summary AS
WITH user_order_metrics AS (
    SELECT
        u.id AS user_id,
        u.country,
        u.status,
        COUNT(o.id) AS order_count,
        COALESCE(SUM(o.amount), 0.00) AS total_order_amount
    FROM users u
    LEFT JOIN orders o
        ON u.id = o.user_id
    WHERE u.deleted_at IS NULL
    GROUP BY u.id, u.country, u.status
)
SELECT
    country,
    COUNT(*) AS user_count,
    COUNT(*) FILTER (WHERE status = 'ACTIVE') AS active_user_count,
    SUM(order_count) AS order_count,
    COALESCE(SUM(total_order_amount), 0.00) AS total_order_amount,
    COUNT(*) FILTER (WHERE order_count = 0) AS users_without_orders_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_count > 0) / NULLIF(COUNT(*), 0),
        2
    ) AS order_coverage_percent
FROM user_order_metrics
GROUP BY country;

CREATE OR REPLACE VIEW order_status_payment_summary AS
WITH payment_flags AS (
    SELECT
        order_id,
        TRUE AS has_payment,
        BOOL_OR(status = 'SUCCESS') AS has_successful_payment
    FROM payments
    GROUP BY order_id
)
SELECT
    o.status AS order_status,
    COUNT(*) AS order_count,
    COALESCE(SUM(o.amount), 0.00) AS total_order_amount,
    COUNT(*) FILTER (WHERE p.has_payment) AS orders_with_payment_count,
    COUNT(*) FILTER (
        WHERE p.has_successful_payment
    ) AS orders_with_successful_payment_count,
    COUNT(*) FILTER (
        WHERE p.has_payment IS NULL
    ) AS orders_without_payment_count
FROM orders o
LEFT JOIN payment_flags p
    ON o.id = p.order_id
GROUP BY o.status;

CREATE OR REPLACE VIEW order_payment_validation AS
SELECT
    COALESCE(o.id, p.order_id) AS order_id,
    o.order_number,
    o.user_id,
    u.email AS user_email,
    o.status AS order_status,
    o.amount AS order_amount,
    p.id AS payment_id,
    p.status AS payment_status,
    p.amount AS payment_amount,
    CASE
        WHEN o.id IS NULL THEN 'MISSING_ORDER'
        WHEN u.id IS NULL THEN 'MISSING_USER'
        WHEN p.id IS NULL THEN 'MISSING_PAYMENT'
        WHEN o.amount <> p.amount THEN 'AMOUNT_MISMATCH'
        WHEN o.status = 'PAID' AND p.status <> 'SUCCESS' THEN 'PAYMENT_NOT_SUCCESSFUL'
        WHEN o.status <> 'PAID' AND p.status = 'SUCCESS' THEN 'ORDER_NOT_MARKED_PAID'
        ELSE 'CONSISTENT'
    END AS qa_status
FROM orders o
LEFT JOIN users u
    ON o.user_id = u.id
FULL OUTER JOIN payments p
    ON o.id = p.order_id;

CREATE OR REPLACE VIEW payment_method_summary AS
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    COUNT(*) FILTER (WHERE status = 'SUCCESS') AS success_count,
    COUNT(*) FILTER (WHERE status = 'FAILED') AS failed_count,
    COUNT(*) FILTER (WHERE status = 'PENDING') AS pending_count,
    COUNT(*) FILTER (WHERE status = 'REFUNDED') AS refunded_count,
    COALESCE(SUM(amount), 0.00) AS total_payment_amount,
    COALESCE(AVG(amount), 0.00) AS average_payment_amount,
    COALESCE(
        SUM(amount) FILTER (WHERE status = 'SUCCESS'),
        0.00
    ) AS successful_payment_amount,
    COALESCE(
        SUM(amount) FILTER (WHERE status = 'REFUNDED'),
        0.00
    ) AS refunded_payment_amount,
    COALESCE(
        SUM(amount) FILTER (WHERE status IN ('PENDING', 'FAILED')),
        0.00
    ) AS unsettled_payment_amount,
    COUNT(*) FILTER (WHERE paid_at IS NOT NULL) AS timestamped_payment_count,
    COUNT(*) FILTER (WHERE paid_at IS NULL) AS missing_paid_at_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE paid_at IS NOT NULL) / NULLIF(COUNT(*), 0),
        2
    ) AS timestamp_coverage_percent
FROM payments
GROUP BY payment_method;

CREATE OR REPLACE VIEW payment_status_summary AS
SELECT
    status AS payment_status,
    COUNT(*) AS payment_count,
    COALESCE(SUM(amount), 0.00) AS total_payment_amount,
    COALESCE(AVG(amount), 0.00) AS average_payment_amount,
    COUNT(*) FILTER (WHERE paid_at IS NOT NULL) AS timestamped_payment_count,
    COUNT(*) FILTER (WHERE paid_at IS NULL) AS missing_paid_at_count,
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE paid_at IS NOT NULL) / NULLIF(COUNT(*), 0),
        2
    ) AS timestamp_coverage_percent
FROM payments
GROUP BY status;

CREATE OR REPLACE VIEW data_quality_rule_report AS
WITH rule_results (
    rule_id,
    rule_description,
    severity,
    expected_issue_count,
    actual_issue_count
) AS (
    SELECT
        'duplicate_user_email',
        'User email addresses should be unique',
        'HIGH',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM (
                SELECT email
                FROM users
                GROUP BY email
                HAVING COUNT(*) > 1
            ) duplicate_emails
        )

    UNION ALL

    SELECT
        'invalid_user_email_format',
        'User email addresses should use a valid format',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'
        )

    UNION ALL

    SELECT
        'blank_user_name',
        'User first and last names should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE BTRIM(first_name) = ''
               OR BTRIM(last_name) = ''
        )

    UNION ALL

    SELECT
        'blank_user_country',
        'User country values should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE BTRIM(country) = ''
        )

    UNION ALL

    SELECT
        'duplicate_order_number',
        'Order numbers should be unique',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM (
                SELECT order_number
                FROM orders
                GROUP BY order_number
                HAVING COUNT(*) > 1
            ) duplicate_order_numbers
        )

    UNION ALL

    SELECT
        'blank_order_number',
        'Order numbers should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders
            WHERE BTRIM(order_number) = ''
        )

    UNION ALL

    SELECT
        'orphan_address',
        'Addresses should reference existing users',
        'HIGH',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM addresses a
            LEFT JOIN users u
                ON a.user_id = u.id
            WHERE u.id IS NULL
        )

    UNION ALL

    SELECT
        'blank_address_city',
        'Address city values should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM addresses
            WHERE BTRIM(city) = ''
        )

    UNION ALL

    SELECT
        'blank_address_country',
        'Address country values should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM addresses
            WHERE BTRIM(country) = ''
        )

    UNION ALL

    SELECT
        'orphan_order',
        'Orders should reference existing users',
        'CRITICAL',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            LEFT JOIN users u
                ON o.user_id = u.id
            WHERE u.id IS NULL
        )

    UNION ALL

    SELECT
        'orphan_payment',
        'Payments should reference existing orders',
        'CRITICAL',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            LEFT JOIN orders o
                ON p.order_id = o.id
            WHERE o.id IS NULL
        )

    UNION ALL

    SELECT
        'non_positive_order_amount',
        'Order amounts should be greater than zero',
        'CRITICAL',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders
            WHERE amount <= 0
        )

    UNION ALL

    SELECT
        'non_positive_payment_amount',
        'Payment amounts should be greater than zero',
        'CRITICAL',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE amount <= 0
        )

    UNION ALL

    SELECT
        'missing_user_age',
        'User age should be available for validation',
        'LOW',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE age IS NULL
        )

    UNION ALL

    SELECT
        'non_positive_user_age',
        'User age should be greater than zero when available',
        'MEDIUM',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE age <= 0
        )

    UNION ALL

    SELECT
        'missing_address_postal_code',
        'Address postal code should be available for validation',
        'LOW',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM addresses
            WHERE postal_code IS NULL
        )

    UNION ALL

    SELECT
        'payment_amount_mismatch',
        'Successful payment amount should match order amount',
        'CRITICAL',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            INNER JOIN payments p
                ON o.id = p.order_id
            WHERE p.status = 'SUCCESS'
              AND o.amount <> p.amount
        )

    UNION ALL

    SELECT
        'successful_payment_without_timestamp',
        'Successful payments should include a payment timestamp',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE status = 'SUCCESS'
              AND paid_at IS NULL
        )

    UNION ALL

    SELECT
        'successful_payment_for_non_payable_order',
        'Successful payments should belong to paid or shipped orders',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            INNER JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'SUCCESS'
              AND o.status NOT IN ('PAID', 'SHIPPED')
        )

    UNION ALL

    SELECT
        'refunded_payment_without_timestamp',
        'Refunded payments should include a payment timestamp',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE status = 'REFUNDED'
              AND paid_at IS NULL
        )

    UNION ALL

    SELECT
        'refunded_payment_for_non_cancelled_order',
        'Refunded payments should belong to cancelled orders',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            INNER JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'REFUNDED'
              AND o.status <> 'CANCELLED'
        )

    UNION ALL

    SELECT
        'failed_payment_with_timestamp',
        'Failed payments should not include a payment timestamp',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE status = 'FAILED'
              AND paid_at IS NOT NULL
        )

    UNION ALL

    SELECT
        'failed_payment_for_non_new_order',
        'Failed payments should belong to new orders',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            INNER JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'FAILED'
              AND o.status <> 'NEW'
        )

    UNION ALL

    SELECT
        'pending_payment_with_timestamp',
        'Pending payments should not include a payment timestamp',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE status = 'PENDING'
              AND paid_at IS NOT NULL
        )

    UNION ALL

    SELECT
        'pending_payment_for_non_new_order',
        'Pending payments should belong to new orders',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            INNER JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'PENDING'
              AND o.status <> 'NEW'
        )

    UNION ALL

    SELECT
        'active_user_without_primary_address',
        'Active users should have a primary address',
        'MEDIUM',
        2::BIGINT,
        (
            SELECT COUNT(*)
            FROM users u
            LEFT JOIN addresses a
                ON u.id = a.user_id
               AND a.is_primary = TRUE
            WHERE u.status = 'ACTIVE'
              AND u.deleted_at IS NULL
              AND a.id IS NULL
        )

    UNION ALL

    SELECT
        'active_user_without_orders',
        'Active users should have at least one order record',
        'MEDIUM',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM active_user_order_summary
            WHERE order_count = 0
        )

    UNION ALL

    SELECT
        'country_without_orders',
        'Countries with non-deleted users should have order coverage',
        'MEDIUM',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM country_user_order_summary
            WHERE order_count = 0
        )

    UNION ALL

    SELECT
        'country_with_user_order_gap',
        'Countries should not have non-deleted users without order history',
        'MEDIUM',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM country_user_order_summary
            WHERE users_without_orders_count > 0
        )

    UNION ALL

    SELECT
        'country_without_primary_addresses',
        'Countries with non-deleted users should have primary address coverage',
        'MEDIUM',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM primary_address_coverage_summary
            WHERE primary_address_count = 0
        )

    UNION ALL

    SELECT
        'active_country_primary_address_gap',
        'Countries with active users should have complete primary address coverage',
        'MEDIUM',
        2::BIGINT,
        (
            SELECT COUNT(*)
            FROM primary_address_coverage_summary
            WHERE active_user_count > primary_address_count
        )

    UNION ALL

    SELECT
        'active_user_under_minimum_age',
        'Active users should be at least 18 years old',
        'MEDIUM',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE status = 'ACTIVE'
              AND deleted_at IS NULL
              AND age < 18
        )

    UNION ALL

    SELECT
        'duplicate_primary_address',
        'Users should not have multiple primary addresses',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM (
                SELECT user_id
                FROM addresses
                WHERE is_primary = TRUE
                  AND user_id IS NOT NULL
                GROUP BY user_id
                HAVING COUNT(*) > 1
            ) duplicate_primary_addresses
        )

    UNION ALL

    SELECT
        'multiple_payments_for_order',
        'Orders should not have multiple payment records',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM (
                SELECT order_id
                FROM payments
                WHERE order_id IS NOT NULL
                GROUP BY order_id
                HAVING COUNT(*) > 1
            ) orders_with_multiple_payments
        )

    UNION ALL

    SELECT
        'address_country_mismatch',
        'Address country should match user country',
        'MEDIUM',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM addresses a
            INNER JOIN users u
                ON a.user_id = u.id
            WHERE a.country <> u.country
        )

    UNION ALL

    SELECT
        'paid_order_without_successful_payment',
        'Paid orders should have a successful payment',
        'CRITICAL',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            LEFT JOIN payments p
                ON o.id = p.order_id
               AND p.status = 'SUCCESS'
            WHERE o.status = 'PAID'
              AND p.id IS NULL
        )

    UNION ALL

    SELECT
        'shipped_order_without_successful_payment',
        'Shipped orders should have a successful payment',
        'CRITICAL',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            LEFT JOIN payments p
                ON o.id = p.order_id
               AND p.status = 'SUCCESS'
            WHERE o.status = 'SHIPPED'
              AND p.id IS NULL
        )

    UNION ALL

    SELECT
        'cancelled_order_with_successful_payment',
        'Cancelled orders should not have successful payments',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            INNER JOIN payments p
                ON o.id = p.order_id
            WHERE o.status = 'CANCELLED'
              AND p.status = 'SUCCESS'
        )

    UNION ALL

    SELECT
        'cancelled_order_without_refunded_payment',
        'Cancelled orders should have a refunded payment',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            LEFT JOIN payments p
                ON o.id = p.order_id
               AND p.status = 'REFUNDED'
            WHERE o.status = 'CANCELLED'
              AND p.id IS NULL
        )

    UNION ALL

    SELECT
        'new_order_with_successful_payment',
        'New orders should not already have successful payments',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            INNER JOIN payments p
                ON o.id = p.order_id
            WHERE o.status = 'NEW'
              AND p.status = 'SUCCESS'
        )

    UNION ALL

    SELECT
        'deleted_user_without_timestamp',
        'Deleted users should include a deletion timestamp',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE status = 'DELETED'
              AND deleted_at IS NULL
        )

    UNION ALL

    SELECT
        'non_deleted_user_with_timestamp',
        'Non-deleted users should not include a deletion timestamp',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE status <> 'DELETED'
              AND deleted_at IS NOT NULL
        )

    UNION ALL

    SELECT
        'deleted_user_with_orders',
        'Deleted users should not keep related orders',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users u
            INNER JOIN orders o
                ON u.id = o.user_id
            WHERE u.status = 'DELETED'
        )

    UNION ALL

    SELECT
        'deleted_user_with_addresses',
        'Deleted users should not keep related addresses',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users u
            INNER JOIN addresses a
                ON u.id = a.user_id
            WHERE u.status = 'DELETED'
        )

    UNION ALL

    SELECT
        'user_deleted_before_created',
        'User deletion timestamps should not precede creation timestamps',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE deleted_at < created_at
        )

    UNION ALL

    SELECT
        'address_created_before_user',
        'Addresses should not be created before their users',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM addresses a
            INNER JOIN users u
                ON a.user_id = u.id
            WHERE a.created_at < u.created_at
        )

    UNION ALL

    SELECT
        'order_created_before_user',
        'Orders should not be created before their users',
        'CRITICAL',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders o
            INNER JOIN users u
                ON o.user_id = u.id
            WHERE o.created_at < u.created_at
        )

    UNION ALL

    SELECT
        'payment_created_before_order',
        'Payment timestamps should not precede order creation timestamps',
        'CRITICAL',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            INNER JOIN orders o
                ON p.order_id = o.id
            WHERE p.paid_at < o.created_at
        )

    UNION ALL

    SELECT
        'successful_payment_without_order',
        'Successful payments should reference an existing order',
        'CRITICAL',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            LEFT JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'SUCCESS'
              AND o.id IS NULL
        )

    UNION ALL

    SELECT
        'refunded_payment_without_order',
        'Refunded payments should reference an existing order',
        'CRITICAL',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            LEFT JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'REFUNDED'
              AND o.id IS NULL
        )

    UNION ALL

    SELECT
        'failed_payment_without_order',
        'Failed payments should reference an existing order',
        'CRITICAL',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            LEFT JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'FAILED'
              AND o.id IS NULL
        )

    UNION ALL

    SELECT
        'pending_payment_without_order',
        'Pending payments should reference an existing order',
        'CRITICAL',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments p
            LEFT JOIN orders o
                ON p.order_id = o.id
            WHERE p.status = 'PENDING'
              AND o.id IS NULL
        )

    UNION ALL

    SELECT
        'invalid_user_status',
        'User status should use an approved domain value',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE status NOT IN ('ACTIVE', 'INACTIVE', 'DELETED')
        )

    UNION ALL

    SELECT
        'blank_user_status',
        'User statuses should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM users
            WHERE BTRIM(status) = ''
        )

    UNION ALL

    SELECT
        'invalid_order_status',
        'Order status should use an approved domain value',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders
            WHERE status NOT IN ('NEW', 'PAID', 'SHIPPED', 'CANCELLED')
        )

    UNION ALL

    SELECT
        'blank_order_status',
        'Order statuses should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM orders
            WHERE BTRIM(status) = ''
        )

    UNION ALL

    SELECT
        'invalid_payment_status',
        'Payment status should use an approved domain value',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE status NOT IN ('SUCCESS', 'PENDING', 'REFUNDED', 'FAILED')
        )

    UNION ALL

    SELECT
        'blank_payment_status',
        'Payment statuses should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE BTRIM(status) = ''
        )

    UNION ALL

    SELECT
        'blank_payment_method',
        'Payment methods should not be blank',
        'HIGH',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE BTRIM(payment_method) = ''
        )

    UNION ALL

    SELECT
        'invalid_payment_method',
        'Payment method should use an approved domain value',
        'MEDIUM',
        0::BIGINT,
        (
            SELECT COUNT(*)
            FROM payments
            WHERE payment_method NOT IN ('CARD', 'PAYPAL', 'BANK_TRANSFER')
        )

    UNION ALL

    SELECT
        'payment_method_without_success',
        'Payment methods should have at least one successful payment',
        'MEDIUM',
        1::BIGINT,
        (
            SELECT COUNT(*)
            FROM payment_method_summary
            WHERE success_count = 0
        )
)
SELECT
    rule_id,
    rule_description,
    severity,
    expected_issue_count,
    actual_issue_count,
    actual_issue_count - expected_issue_count AS issue_count_delta,
    CASE
        WHEN actual_issue_count = expected_issue_count THEN 'MATCH'
        WHEN actual_issue_count > expected_issue_count THEN 'REGRESSION'
        ELSE 'IMPROVEMENT'
    END AS baseline_status
FROM rule_results;

CREATE OR REPLACE VIEW data_quality_rule_summary AS
SELECT
    severity,
    COUNT(*) AS rule_count,
    SUM(expected_issue_count) AS expected_issue_count,
    SUM(actual_issue_count) AS actual_issue_count,
    SUM(issue_count_delta) AS issue_count_delta,
    COUNT(*) FILTER (
        WHERE baseline_status <> 'MATCH'
    ) AS deviation_count
FROM data_quality_rule_report
GROUP BY severity;
