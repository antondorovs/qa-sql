-- Equal timestamps are valid, but even a one-microsecond reversal is an issue.
BEGIN;

DO $$
DECLARE
    time_shift INTERVAL;
    expected_count BIGINT;
    mismatched_rule TEXT;
BEGIN
    FOREACH time_shift IN ARRAY ARRAY[INTERVAL '0', INTERVAL '-1 microsecond']
    LOOP
        UPDATE users
        SET deleted_at = created_at + time_shift
        WHERE id = 5;

        UPDATE addresses a
        SET created_at = u.created_at + time_shift
        FROM users u
        WHERE a.id = 1 AND u.id = a.user_id;

        UPDATE orders o
        SET created_at = u.created_at + time_shift
        FROM users u
        WHERE o.id = 1 AND u.id = o.user_id;

        UPDATE payments p
        SET paid_at = o.created_at + time_shift
        FROM orders o
        WHERE p.id = 1 AND o.id = p.order_id;

        expected_count := CASE WHEN time_shift = INTERVAL '0' THEN 0 ELSE 1 END;

        SELECT expected.rule_id
        INTO mismatched_rule
        FROM (VALUES
            ('user_deleted_before_created'),
            ('address_created_before_user'),
            ('order_created_before_user'),
            ('payment_created_before_order')
        ) AS expected(rule_id)
        LEFT JOIN data_quality_rule_report report USING (rule_id)
        WHERE report.actual_issue_count IS DISTINCT FROM expected_count
        LIMIT 1;

        IF FOUND THEN
            RAISE EXCEPTION 'Expected % issues for % with timestamp shift %',
                expected_count, mismatched_rule, time_shift;
        END IF;
    END LOOP;
END
$$;

ROLLBACK;
