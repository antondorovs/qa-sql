-- Multiple-payment issues are counted per order, and NULL references form no group.
BEGIN;

INSERT INTO payments (id, order_id, payment_method, status, amount) VALUES
    (101, 1, 'CARD', 'PENDING', 1.00),
    (102, 1, 'CARD', 'PENDING', 1.00),
    (103, 2, 'CARD', 'PENDING', 1.00),
    (104, NULL, 'CARD', 'PENDING', 1.00),
    (105, NULL, 'CARD', 'PENDING', 1.00);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM data_quality_rule_report
        WHERE rule_id = 'multiple_payments_for_order'
          AND actual_issue_count = 2
          AND baseline_status = 'REGRESSION'
    ) THEN
        RAISE EXCEPTION 'Expected one multiple-payment issue per affected order';
    END IF;
END
$$;

-- Resolving each duplicate group must update the report immediately.
DELETE FROM payments WHERE id IN (101, 102);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM data_quality_rule_report
        WHERE rule_id = 'multiple_payments_for_order'
          AND actual_issue_count = 1
          AND baseline_status = 'REGRESSION'
    ) THEN
        RAISE EXCEPTION 'Resolving one payment group did not leave one issue';
    END IF;
END
$$;

DELETE FROM payments WHERE id = 103;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM data_quality_rule_report
        WHERE rule_id = 'multiple_payments_for_order'
          AND actual_issue_count = 0
          AND baseline_status = 'MATCH'
    ) THEN
        RAISE EXCEPTION 'Resolved payment groups did not restore the baseline';
    END IF;
END
$$;

ROLLBACK;

-- Mixed retries must cover each order once, with any success taking precedence.
BEGIN;

INSERT INTO payments (id, order_id, payment_method, status, amount) VALUES
    (201, 1, 'CARD', 'PENDING', 120.50),
    (202, 1, 'CARD', 'FAILED', 120.50),
    (203, 1, 'CARD', 'SUCCESS', 120.50),
    (204, NULL, 'CARD', 'SUCCESS', 1.00),
    (205, 999, 'CARD', 'SUCCESS', 1.00);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM order_status_payment_summary
        WHERE order_status = 'PAID'
          AND order_count = 4 AND total_order_amount = 365.50
          AND orders_with_payment_count = 3
          AND orders_with_successful_payment_count = 3
          AND orders_without_payment_count = 1
          AND payment_coverage_percent = 75.00
          AND successful_payment_coverage_percent = 75.00
    ) THEN
        RAISE EXCEPTION 'Mixed retries inflated order totals or hid successful coverage';
    END IF;
END
$$;

DELETE FROM payments WHERE id IN (1, 203);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM order_status_payment_summary
        WHERE order_status = 'PAID'
          AND order_count = 4 AND total_order_amount = 365.50
          AND orders_with_payment_count = 3
          AND orders_with_successful_payment_count = 2
          AND orders_without_payment_count = 1
          AND payment_coverage_percent = 75.00
          AND successful_payment_coverage_percent = 50.00
    ) THEN
        RAISE EXCEPTION 'Unsuccessful retries must retain payment coverage without success';
    END IF;
END
$$;

ROLLBACK;
