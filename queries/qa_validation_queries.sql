-- QA database validation queries
-- Each query returns suspicious rows that should be investigated.

-- Baseline summary for all reusable data quality rules
SELECT
    rule_id,
    severity,
    expected_issue_count,
    actual_issue_count,
    issue_count_delta,
    baseline_status
FROM data_quality_rule_report
ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    rule_id;

-- Severity summary for fast triage dashboards
SELECT
    severity,
    rule_count,
    expected_issue_count,
    actual_issue_count,
    issue_count_delta,
    deviation_count
FROM data_quality_rule_summary
ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END;

-- Payment method summary for checkout coverage review
SELECT
    payment_method,
    payment_count,
    success_count,
    failed_count,
    pending_count,
    refunded_count,
    total_payment_amount,
    average_payment_amount,
    successful_payment_amount,
    refunded_payment_amount,
    unsettled_payment_amount,
    timestamped_payment_count,
    missing_paid_at_count,
    timestamp_coverage_percent
FROM payment_method_summary
ORDER BY payment_method;

-- Payment lifecycle summary by status
SELECT
    payment_status,
    payment_count,
    total_payment_amount,
    average_payment_amount,
    timestamped_payment_count,
    missing_paid_at_count,
    timestamp_coverage_percent
FROM payment_status_summary
ORDER BY payment_status;

-- Payment methods without successful payment coverage
SELECT
    payment_method,
    payment_count,
    success_count,
    pending_count,
    failed_count
FROM payment_method_summary
WHERE success_count = 0;

-- Country summary for user and order coverage review
SELECT
    country,
    user_count,
    active_user_count,
    order_count,
    total_order_amount,
    users_without_orders_count
FROM country_user_order_summary
ORDER BY country;

-- Primary address coverage by country
SELECT
    country,
    user_count,
    active_user_count,
    primary_address_count,
    users_without_primary_address_count,
    primary_address_coverage_percent
FROM primary_address_coverage_summary
ORDER BY country;

-- Payment coverage by order status
SELECT
    order_status,
    order_count,
    total_order_amount,
    orders_with_payment_count,
    orders_with_successful_payment_count,
    orders_without_payment_count
FROM order_status_payment_summary
ORDER BY order_status;

-- Active users without orders
SELECT
    user_id,
    email,
    country,
    order_count,
    latest_order_at
FROM active_user_order_summary
WHERE order_count = 0;

-- Countries without order coverage
SELECT
    country,
    user_count,
    active_user_count,
    order_count
FROM country_user_order_summary
WHERE order_count = 0;

-- Countries with partial user order coverage
SELECT
    country,
    user_count,
    active_user_count,
    order_count,
    users_without_orders_count
FROM country_user_order_summary
WHERE users_without_orders_count > 0;

-- Countries without primary address coverage
SELECT
    country,
    user_count,
    active_user_count,
    primary_address_count
FROM primary_address_coverage_summary
WHERE primary_address_count = 0;

-- Countries with incomplete active-user primary address coverage
SELECT
    country,
    active_user_count,
    primary_address_count,
    users_without_primary_address_count,
    primary_address_coverage_percent
FROM primary_address_coverage_summary
WHERE active_user_count > primary_address_count;

-- Duplicate emails
SELECT email, COUNT(*) AS duplicate_count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- Users with invalid email format
SELECT id, email
FROM users
WHERE email !~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$';

-- Users with blank names
SELECT id, first_name, last_name, email
FROM users
WHERE BTRIM(first_name) = ''
   OR BTRIM(last_name) = '';

-- Users with blank country
SELECT id, email, country
FROM users
WHERE BTRIM(country) = '';

-- Users with blank status
SELECT id, email, status
FROM users
WHERE BTRIM(status) = '';

-- Duplicate order numbers
SELECT order_number, COUNT(*) AS duplicate_count
FROM orders
GROUP BY order_number
HAVING COUNT(*) > 1;

-- Orders with blank order numbers
SELECT id, user_id, order_number, status
FROM orders
WHERE BTRIM(order_number) = '';

-- Orders with blank status
SELECT id, user_id, order_number, status
FROM orders
WHERE BTRIM(status) = '';

-- Orders without existing users
SELECT
    o.id,
    o.order_number,
    o.user_id,
    o.status,
    o.amount
FROM orders o
LEFT JOIN users u
    ON o.user_id = u.id
WHERE u.id IS NULL;

-- Payments without existing orders
SELECT
    p.id,
    p.order_id,
    p.status,
    p.amount
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.id
WHERE o.id IS NULL;

-- Addresses without existing users
SELECT
    a.id,
    a.user_id,
    a.city,
    a.country
FROM addresses a
LEFT JOIN users u
    ON a.user_id = u.id
WHERE u.id IS NULL;

-- Addresses with blank city
SELECT id, user_id, city, country
FROM addresses
WHERE BTRIM(city) = '';

-- Addresses with blank country
SELECT id, user_id, city, country
FROM addresses
WHERE BTRIM(country) = '';

-- Orders with multiple payment records
SELECT
    order_id,
    COUNT(*) AS payment_count
FROM payments
WHERE order_id IS NOT NULL
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Users with multiple primary addresses
SELECT
    user_id,
    COUNT(*) AS primary_address_count
FROM addresses
WHERE is_primary = TRUE
  AND user_id IS NOT NULL
GROUP BY user_id
HAVING COUNT(*) > 1;

-- Addresses with a country that differs from the user country
SELECT
    a.id AS address_id,
    a.user_id,
    u.country AS user_country,
    a.country AS address_country
FROM addresses a
INNER JOIN users u
    ON a.user_id = u.id
WHERE a.country <> u.country;

-- Users created today
SELECT id, email, created_at
FROM users
WHERE created_at::date = CURRENT_DATE;

-- Orders with negative amount
SELECT id, order_number, amount
FROM orders
WHERE amount < 0;

-- Payments with non-positive amount
SELECT id, order_id, status, amount
FROM payments
WHERE amount <= 0;

-- Payments with blank method
SELECT id, order_id, payment_method, status
FROM payments
WHERE BTRIM(payment_method) = '';

-- Payments with blank status
SELECT id, order_id, payment_method, status
FROM payments
WHERE BTRIM(status) = '';

-- Users without age
SELECT id, email, age
FROM users
WHERE age IS NULL;

-- Users with non-positive age
SELECT id, email, age
FROM users
WHERE age <= 0;

-- Active users under the minimum account age
SELECT id, email, status, age
FROM users
WHERE status = 'ACTIVE'
  AND deleted_at IS NULL
  AND age < 18;

-- Addresses without postal codes
SELECT
    id,
    user_id,
    city,
    country,
    postal_code
FROM addresses
WHERE postal_code IS NULL;

-- Successful payments without paid timestamp
SELECT id, order_id, status, paid_at
FROM payments
WHERE status = 'SUCCESS'
  AND paid_at IS NULL;

-- Successful payments for non-payable orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    o.order_number,
    o.status AS order_status
FROM payments p
INNER JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'SUCCESS'
  AND o.status NOT IN ('PAID', 'SHIPPED');

-- Successful payments without existing orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    p.amount AS payment_amount
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'SUCCESS'
  AND o.id IS NULL;

-- Refunded payments without existing orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    p.amount AS payment_amount
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'REFUNDED'
  AND o.id IS NULL;

-- Failed payments without existing orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    p.amount AS payment_amount
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'FAILED'
  AND o.id IS NULL;

-- Pending payments without existing orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    p.amount AS payment_amount
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'PENDING'
  AND o.id IS NULL;

-- Refunded payments without paid timestamp
SELECT id, order_id, status, paid_at
FROM payments
WHERE status = 'REFUNDED'
  AND paid_at IS NULL;

-- Refunded payments for non-cancelled orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    o.order_number,
    o.status AS order_status
FROM payments p
INNER JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'REFUNDED'
  AND o.status <> 'CANCELLED';

-- Failed payments with paid timestamp
SELECT id, order_id, status, paid_at
FROM payments
WHERE status = 'FAILED'
  AND paid_at IS NOT NULL;

-- Failed payments for non-new orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    o.order_number,
    o.status AS order_status
FROM payments p
INNER JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'FAILED'
  AND o.status <> 'NEW';

-- Pending payments with paid timestamp
SELECT id, order_id, status, paid_at
FROM payments
WHERE status = 'PENDING'
  AND paid_at IS NOT NULL;

-- Pending payments for non-new orders
SELECT
    p.id AS payment_id,
    p.order_id,
    p.status AS payment_status,
    o.order_number,
    o.status AS order_status
FROM payments p
INNER JOIN orders o
    ON p.order_id = o.id
WHERE p.status = 'PENDING'
  AND o.status <> 'NEW';

-- Paid orders without successful payment
SELECT
    o.id,
    o.order_number,
    o.status AS order_status,
    p.status AS payment_status
FROM orders o
LEFT JOIN payments p
    ON o.id = p.order_id
   AND p.status = 'SUCCESS'
WHERE o.status = 'PAID'
  AND p.id IS NULL;

-- Shipped orders without successful payment
SELECT
    o.id,
    o.order_number,
    o.status AS order_status,
    p.status AS payment_status
FROM orders o
LEFT JOIN payments p
    ON o.id = p.order_id
   AND p.status = 'SUCCESS'
WHERE o.status = 'SHIPPED'
  AND p.id IS NULL;

-- Cancelled orders with successful payments
SELECT
    o.id AS order_id,
    o.order_number,
    o.status AS order_status,
    p.id AS payment_id,
    p.status AS payment_status,
    p.amount AS payment_amount
FROM orders o
INNER JOIN payments p
    ON o.id = p.order_id
WHERE o.status = 'CANCELLED'
  AND p.status = 'SUCCESS';

-- Cancelled orders without refunded payments
SELECT
    o.id AS order_id,
    o.order_number,
    o.status AS order_status,
    p.id AS payment_id,
    p.status AS payment_status,
    p.amount AS payment_amount
FROM orders o
LEFT JOIN payments p
    ON o.id = p.order_id
   AND p.status = 'REFUNDED'
WHERE o.status = 'CANCELLED'
  AND p.id IS NULL;

-- New orders with successful payments
SELECT
    o.id AS order_id,
    o.order_number,
    o.status AS order_status,
    p.id AS payment_id,
    p.status AS payment_status,
    p.amount AS payment_amount
FROM orders o
INNER JOIN payments p
    ON o.id = p.order_id
WHERE o.status = 'NEW'
  AND p.status = 'SUCCESS';

-- Order and payment amount mismatch
SELECT
    o.id AS order_id,
    o.order_number,
    o.amount AS order_amount,
    p.amount AS payment_amount
FROM orders o
INNER JOIN payments p
    ON o.id = p.order_id
WHERE o.amount <> p.amount;

-- Users deleted before they were created
SELECT id, email, created_at, deleted_at
FROM users
WHERE deleted_at < created_at;

-- Deleted users without a deletion timestamp
SELECT id, email, status, deleted_at
FROM users
WHERE status = 'DELETED'
  AND deleted_at IS NULL;

-- Non-deleted users with a deletion timestamp
SELECT id, email, status, deleted_at
FROM users
WHERE status <> 'DELETED'
  AND deleted_at IS NOT NULL;

-- Deleted users with related orders
SELECT
    u.id AS user_id,
    u.email,
    o.id AS order_id,
    o.order_number,
    o.status AS order_status
FROM users u
INNER JOIN orders o
    ON u.id = o.user_id
WHERE u.status = 'DELETED';

-- Deleted users with related addresses
SELECT
    u.id AS user_id,
    u.email,
    a.id AS address_id,
    a.city,
    a.country
FROM users u
INNER JOIN addresses a
    ON u.id = a.user_id
WHERE u.status = 'DELETED';

-- Addresses created before their users
SELECT
    a.id AS address_id,
    a.user_id,
    u.created_at AS user_created_at,
    a.created_at AS address_created_at
FROM addresses a
INNER JOIN users u
    ON a.user_id = u.id
WHERE a.created_at < u.created_at;

-- Orders created before their users
SELECT
    o.id AS order_id,
    o.order_number,
    o.user_id,
    u.created_at AS user_created_at,
    o.created_at AS order_created_at
FROM orders o
INNER JOIN users u
    ON o.user_id = u.id
WHERE o.created_at < u.created_at;

-- Payments recorded before their orders
SELECT
    p.id AS payment_id,
    p.order_id,
    o.created_at AS order_created_at,
    p.paid_at
FROM payments p
INNER JOIN orders o
    ON p.order_id = o.id
WHERE p.paid_at < o.created_at;

-- Users with unsupported status values
SELECT id, email, status
FROM users
WHERE status NOT IN ('ACTIVE', 'INACTIVE', 'DELETED');

-- Orders with unsupported status values
SELECT id, order_number, status
FROM orders
WHERE status NOT IN ('NEW', 'PAID', 'SHIPPED', 'CANCELLED');

-- Payments with unsupported status values
SELECT id, order_id, status
FROM payments
WHERE status NOT IN ('SUCCESS', 'PENDING', 'REFUNDED', 'FAILED');

-- Payments with unsupported method values
SELECT id, order_id, payment_method
FROM payments
WHERE payment_method NOT IN ('CARD', 'PAYPAL', 'BANK_TRANSFER');
