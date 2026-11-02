-- QA SQL Lab practice solutions

-- 1. Show all active users.
SELECT id, first_name, last_name, email
FROM users
WHERE status = 'ACTIVE';

-- 2. Show users from USA or Canada.
SELECT id, email, country
FROM users
WHERE country IN ('USA', 'Canada');

-- 3. Show orders created after 2026-03-01.
SELECT id, order_number, amount, created_at
FROM orders
WHERE created_at > '2026-03-01'
ORDER BY created_at;

-- 4. Count users by status.
SELECT status, COUNT(*) AS user_count
FROM users
GROUP BY status
ORDER BY status;

-- 5. Calculate total order amount by order status.
SELECT status, SUM(amount) AS total_amount
FROM orders
GROUP BY status
ORDER BY status;

-- 6. Show users with their primary address.
SELECT
    u.id,
    u.email,
    a.city,
    a.country
FROM users u
INNER JOIN addresses a
    ON u.id = a.user_id
WHERE a.is_primary = TRUE
ORDER BY u.id;

-- 7. Show orders with user email and payment status.
SELECT
    o.id AS order_id,
    o.order_number,
    u.email,
    p.status AS payment_status
FROM orders o
LEFT JOIN users u
    ON o.user_id = u.id
LEFT JOIN payments p
    ON o.id = p.order_id
ORDER BY o.id;

-- 8. Find duplicate user emails.
SELECT email, COUNT(*) AS duplicate_count
FROM users
GROUP BY email
HAVING COUNT(*) > 1;

-- 9. Find orders that reference a missing user.
SELECT o.*
FROM orders o
LEFT JOIN users u
    ON o.user_id = u.id
WHERE u.id IS NULL;

-- 10. Find payments that reference a missing order.
SELECT p.*
FROM payments p
LEFT JOIN orders o
    ON p.order_id = o.id
WHERE o.id IS NULL;

-- 11. Find orders with negative amount.
SELECT id, order_number, amount
FROM orders
WHERE amount < 0;

-- 12. Find paid orders that do not have a successful payment.
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

-- 13. Find users who do not have any orders.
SELECT id, email
FROM users u
WHERE NOT EXISTS (
    SELECT 1
    FROM orders o
    WHERE o.user_id = u.id
)
ORDER BY id;

-- 14. Find orders above the average order amount.
SELECT id, order_number, amount
FROM orders
WHERE amount > (
    SELECT AVG(amount)
    FROM orders
)
ORDER BY amount DESC;

-- 15. Classify users into age groups: UNKNOWN, UNDER_18, ADULT, SENIOR.
SELECT
    id,
    email,
    age,
    CASE
        WHEN age IS NULL THEN 'UNKNOWN'
        WHEN age < 18 THEN 'UNDER_18'
        WHEN age BETWEEN 18 AND 64 THEN 'ADULT'
        ELSE 'SENIOR'
    END AS age_group
FROM users
ORDER BY id;

-- 16. Classify orders into QA risk levels based on amount and status.
SELECT
    id,
    order_number,
    status,
    amount,
    CASE
        WHEN amount < 0 THEN 'INVALID_AMOUNT'
        WHEN status = 'PAID' AND amount >= 200 THEN 'HIGH_VALUE_PAID'
        WHEN status = 'NEW' THEN 'AWAITING_PROCESSING'
        WHEN status = 'CANCELLED' THEN 'CANCELLED_ORDER'
        ELSE 'STANDARD'
    END AS qa_risk_level
FROM orders
ORDER BY id;

-- 17. Number each user's orders by creation date.
SELECT
    user_id,
    order_number,
    created_at,
    ROW_NUMBER() OVER (
        PARTITION BY user_id
        ORDER BY created_at
    ) AS order_sequence
FROM orders
ORDER BY user_id, order_sequence;

-- 18. Rank orders by amount within each order status.
SELECT
    status,
    order_number,
    amount,
    RANK() OVER (
        PARTITION BY status
        ORDER BY amount DESC
    ) AS amount_rank
FROM orders
ORDER BY status, amount_rank;

-- 19. Calculate a running total of order amounts by creation date.
SELECT
    order_number,
    created_at,
    amount,
    SUM(amount) OVER (
        ORDER BY created_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM orders
ORDER BY created_at;

-- 20. Write an assertion query that returns active users without primary addresses.
SELECT u.id, u.email
FROM users u
LEFT JOIN addresses a
    ON u.id = a.user_id
   AND a.is_primary = TRUE
WHERE u.status = 'ACTIVE'
  AND a.id IS NULL;

-- 21. Write an assertion query that returns successful payments where amount differs from the order amount.
SELECT
    o.id AS order_id,
    o.order_number,
    o.amount AS order_amount,
    p.amount AS payment_amount
FROM orders o
INNER JOIN payments p
    ON o.id = p.order_id
WHERE p.status = 'SUCCESS'
  AND o.amount <> p.amount;

-- 22. Write a safe transaction that updates one order status, verifies it, and rolls it back.
BEGIN;

UPDATE orders
SET status = 'PAID'
WHERE id = 5;

SELECT id, order_number, status
FROM orders
WHERE id = 5;

ROLLBACK;

-- 23. Use a CTE to calculate order count and total order amount for each user.
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

-- 24. Use multiple CTEs to return only orders with missing or inconsistent payments.
WITH order_details AS (
    SELECT
        o.id AS order_id,
        o.order_number,
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

-- 25. Use a recursive CTE to generate dates from 2026-06-01 through 2026-06-07.
WITH RECURSIVE date_range AS (
    SELECT DATE '2026-06-01' AS report_date

    UNION ALL

    SELECT report_date + 1
    FROM date_range
    WHERE report_date < DATE '2026-06-07'
)
SELECT report_date
FROM date_range
ORDER BY report_date;

-- 26. Query active_user_order_summary for active users without orders.
SELECT *
FROM active_user_order_summary
WHERE order_count = 0
ORDER BY user_id;

-- 27. Query order_payment_validation for all rows where qa_status is not CONSISTENT.
SELECT *
FROM order_payment_validation
WHERE qa_status <> 'CONSISTENT'
ORDER BY order_id;

-- 28. Count validation results by qa_status using order_payment_validation.
SELECT qa_status, COUNT(*) AS result_count
FROM order_payment_validation
GROUP BY qa_status
ORDER BY qa_status;
