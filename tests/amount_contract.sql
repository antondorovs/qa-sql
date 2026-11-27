-- Check invalid amounts and the smallest and largest valid stored values.
BEGIN;

DO $$
DECLARE
    scenario RECORD;
    mismatched_rule TEXT;
BEGIN
    FOR scenario IN
        SELECT * FROM (VALUES
            ('NaN'::numeric, 2, 1, 'REGRESSION'),
            (0.00::numeric, 2, 1, 'REGRESSION'),
            (-0.01::numeric, 2, 1, 'REGRESSION'),
            (0.01::numeric, 1, 0, 'MATCH'),
            (99999999.99::numeric, 1, 0, 'MATCH')
        ) AS cases(amount, order_issues, payment_issues, expected_status)
    LOOP
        UPDATE orders SET amount = scenario.amount WHERE id = 1;
        UPDATE payments SET amount = scenario.amount WHERE id = 1;

        SELECT expected.rule_id INTO mismatched_rule
        FROM (VALUES
            ('non_positive_order_amount', scenario.order_issues),
            ('non_positive_payment_amount', scenario.payment_issues)
        ) AS expected(rule_id, issue_count)
        LEFT JOIN data_quality_rule_report report USING (rule_id)
        WHERE report.actual_issue_count IS DISTINCT FROM expected.issue_count
           OR report.baseline_status IS DISTINCT FROM scenario.expected_status
        LIMIT 1;

        IF FOUND THEN
            RAISE EXCEPTION 'Unexpected count or baseline for % with amount %',
                mismatched_rule, scenario.amount;
        END IF;
    END LOOP;
END
$$;

ROLLBACK;
