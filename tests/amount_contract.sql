-- A numeric NaN must not pass the positive amount checks.
BEGIN;

UPDATE orders SET amount = 'NaN'::numeric WHERE id = 1;
UPDATE payments SET amount = 'NaN'::numeric WHERE id = 1;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM data_quality_rule_report
        WHERE rule_id = 'non_positive_order_amount'
          AND actual_issue_count = 2
    ) OR NOT EXISTS (
        SELECT 1 FROM data_quality_rule_report
        WHERE rule_id = 'non_positive_payment_amount'
          AND actual_issue_count = 1
    ) THEN
        RAISE EXCEPTION 'Order and payment amount rules must reject NaN';
    END IF;
END
$$;

ROLLBACK;
