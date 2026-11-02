-- Shipped orders retain their successful payment when fulfillment advances.
BEGIN;

DO $$
DECLARE
    scenario RECORD;
BEGIN
    FOR scenario IN
        SELECT * FROM (VALUES
            ('SHIPPED', 'SUCCESS', 'CONSISTENT'),
            ('SHIPPED', 'PENDING', 'PAYMENT_NOT_SUCCESSFUL'),
            ('SHIPPED', 'FAILED', 'PAYMENT_NOT_SUCCESSFUL'),
            ('SHIPPED', 'REFUNDED', 'PAYMENT_NOT_SUCCESSFUL'),
            ('PAID', 'SUCCESS', 'CONSISTENT'),
            ('PAID', 'PENDING', 'PAYMENT_NOT_SUCCESSFUL'),
            ('NEW', 'SUCCESS', 'ORDER_NOT_MARKED_PAID'),
            ('CANCELLED', 'SUCCESS', 'ORDER_NOT_MARKED_PAID')
        ) AS cases(order_status, payment_status, expected_status)
    LOOP
        UPDATE orders SET status = scenario.order_status WHERE id = 2;
        UPDATE payments SET status = scenario.payment_status WHERE id = 2;

        IF NOT EXISTS (
            SELECT 1 FROM order_payment_validation
            WHERE order_id = 2 AND payment_id = 2
              AND qa_status = scenario.expected_status
        ) THEN
            RAISE EXCEPTION 'Unexpected validation for order %, payment %; expected %',
                scenario.order_status, scenario.payment_status, scenario.expected_status;
        END IF;
    END LOOP;
END
$$;

UPDATE orders SET status = 'SHIPPED' WHERE id = 2;
UPDATE payments SET status = 'SUCCESS', amount = 1.00 WHERE id = 2;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM order_payment_validation
        WHERE order_id = 2 AND qa_status = 'AMOUNT_MISMATCH'
    ) THEN
        RAISE EXCEPTION 'Shipped order amount mismatch was hidden';
    END IF;
END
$$;

DELETE FROM payments WHERE id = 2;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM order_payment_validation
        WHERE order_id = 2 AND qa_status = 'MISSING_PAYMENT'
    ) THEN
        RAISE EXCEPTION 'Shipped order missing payment was hidden';
    END IF;
END
$$;

ROLLBACK;
