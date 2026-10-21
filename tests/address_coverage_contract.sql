-- Address coverage must count users once even when their addresses are invalid.
BEGIN;

INSERT INTO addresses (
    id, user_id, city, country, postal_code, is_primary, created_at
) VALUES
    (101, 4, 'Budapest', 'Hungary', '1051', TRUE, '2026-06-04 10:00:00'),
    (102, 8, 'Budapest', 'Hungary', '1051', FALSE, '2026-06-04 10:00:00'),
    (103, 5, 'Boston', 'USA', '02108', TRUE, '2026-04-01 10:00:00');

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM primary_address_coverage_summary
        WHERE country = 'Hungary'
          AND user_count = 2
          AND active_user_count = 2
          AND primary_address_count = 2
          AND users_without_primary_address_count = 1
          AND primary_address_coverage_percent = 50.00
    ) THEN
        RAISE EXCEPTION 'Duplicate primary addresses inflated user coverage';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM primary_address_coverage_summary
        WHERE country = 'USA'
          AND user_count = 2
          AND active_user_count = 2
          AND primary_address_count = 2
          AND users_without_primary_address_count = 0
          AND primary_address_coverage_percent = 100.00
    ) THEN
        RAISE EXCEPTION 'Deleted users or orphan addresses affected coverage';
    END IF;
END
$$;

DELETE FROM addresses WHERE user_id IN (4, 8);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM primary_address_coverage_summary
        WHERE country = 'Hungary'
          AND user_count = 2
          AND active_user_count = 2
          AND primary_address_count = 0
          AND users_without_primary_address_count = 2
          AND primary_address_coverage_percent = 0.00
    ) THEN
        RAISE EXCEPTION 'Users without addresses disappeared from coverage';
    END IF;
END
$$;

ROLLBACK;
