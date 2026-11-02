-- Common table expression examples for QA SQL Lab

-- Aggregate order activity before joining it to users
WITH order_totals AS (
    SELECT
        user_id,
        COUNT(*) AS order_count,
        SUM(amount) AS total_order_amount
    FROM orders
    GROUP BY user_id
)
SELECT
    u.id AS user_id,
    u.email,
    COALESCE(ot.order_count, 0) AS order_count,
    COALESCE(ot.total_order_amount, 0.00) AS total_order_amount
FROM users u
LEFT JOIN order_totals ot
    ON u.id = ot.user_id
ORDER BY u.id;

-- Build a multi-step order and payment validation report
WITH order_details AS (
    SELECT
        o.id AS order_id,
        o.order_number,
        o.user_id,
        o.status AS order_status,
        o.amount AS order_amount,
        p.status AS payment_status,
        p.amount AS payment_amount
    FROM orders o
    LEFT JOIN payments p
        ON o.id = p.order_id
),
validation_results AS (
    SELECT
        *,
        CASE
            WHEN payment_status IS NULL THEN 'MISSING_PAYMENT'
            WHEN order_amount <> payment_amount THEN 'AMOUNT_MISMATCH'
            WHEN order_status IN ('PAID', 'SHIPPED') AND payment_status <> 'SUCCESS'
                THEN 'PAYMENT_NOT_SUCCESSFUL'
            ELSE 'CONSISTENT'
        END AS qa_status
    FROM order_details
)
SELECT *
FROM validation_results
WHERE qa_status <> 'CONSISTENT'
ORDER BY order_id;

-- Find users without orders by reusing a CTE result
WITH users_with_orders AS (
    SELECT DISTINCT user_id
    FROM orders
    WHERE user_id IS NOT NULL
)
SELECT u.id, u.email
FROM users u
LEFT JOIN users_with_orders uwo
    ON u.id = uwo.user_id
WHERE uwo.user_id IS NULL
ORDER BY u.id;

-- Generate a date range and count orders created on each day
WITH RECURSIVE date_range AS (
    SELECT DATE '2026-06-01' AS report_date

    UNION ALL

    SELECT report_date + 1
    FROM date_range
    WHERE report_date < DATE '2026-06-07'
),
daily_orders AS (
    SELECT
        created_at::date AS order_date,
        COUNT(*) AS order_count,
        SUM(amount) AS total_amount
    FROM orders
    GROUP BY created_at::date
)
SELECT
    dr.report_date,
    COALESCE(daily_orders.order_count, 0) AS order_count,
    COALESCE(daily_orders.total_amount, 0.00) AS total_amount
FROM date_range dr
LEFT JOIN daily_orders
    ON dr.report_date = daily_orders.order_date
ORDER BY dr.report_date;

-- Compare country totals with the overall average
WITH country_totals AS (
    SELECT
        u.country,
        COUNT(o.id) AS order_count,
        COALESCE(SUM(o.amount), 0.00) AS total_order_amount
    FROM users u
    LEFT JOIN orders o
        ON u.id = o.user_id
    GROUP BY u.country
),
average_country_total AS (
    SELECT AVG(total_order_amount) AS average_total
    FROM country_totals
)
SELECT
    ct.country,
    ct.order_count,
    ct.total_order_amount,
    act.average_total
FROM country_totals ct
CROSS JOIN average_country_total act
WHERE ct.total_order_amount > act.average_total
ORDER BY ct.total_order_amount DESC;
