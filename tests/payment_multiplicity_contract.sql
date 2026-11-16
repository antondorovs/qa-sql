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

ROLLBACK;
