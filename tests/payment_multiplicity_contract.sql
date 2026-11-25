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
