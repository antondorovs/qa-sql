-- Retention rules count each related record and exclude non-deleted users.
BEGIN;

UPDATE orders SET user_id = 5 WHERE id IN (1, 2);
UPDATE addresses SET user_id = 5 WHERE id = 1;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM data_quality_rule_report
        WHERE rule_id = 'deleted_user_with_orders'
          AND expected_issue_count = 0
          AND actual_issue_count = 2
          AND baseline_status = 'REGRESSION'
    ) OR NOT EXISTS (
        SELECT 1 FROM data_quality_rule_report
        WHERE rule_id = 'deleted_user_with_addresses'
          AND expected_issue_count = 0
          AND actual_issue_count = 1
          AND baseline_status = 'REGRESSION'
    ) THEN
        RAISE EXCEPTION 'Retention rules must flag every related order and address';
    END IF;

    UPDATE users SET status = 'ACTIVE', deleted_at = NULL WHERE id = 5;

    IF (
        SELECT COUNT(*) FROM data_quality_rule_report
        WHERE rule_id IN ('deleted_user_with_orders', 'deleted_user_with_addresses')
          AND actual_issue_count = 0
          AND baseline_status = 'MATCH'
    ) <> 2 THEN
        RAISE EXCEPTION 'Retention rules must exclude users who are not deleted';
    END IF;
END
$$;

ROLLBACK;
