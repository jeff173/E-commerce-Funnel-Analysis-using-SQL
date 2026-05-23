-- 1. Data quality check: rows, users, date range, revenue.
SELECT
    COUNT(*) AS total_events,
    COUNT(DISTINCT user_id) AS total_users,
    MIN(event_date) AS first_event_at,
    MAX(event_date) AS last_event_at,
    SUM(CASE WHEN event_type = 'purchase'
         THEN amount ELSE 0 END) AS revenue
FROM user_events;

-- 2. Event volume by funnel step.
SELECT
    event_type,
    COUNT(*) AS event_count,
    COUNT(DISTINCT user_id) AS unique_users
FROM user_events
GROUP BY event_type
ORDER BY
    CASE event_type
        WHEN 'page_view'      THEN 1
        WHEN 'add_to_cart'    THEN 2
        WHEN 'checkout_start' THEN 3
        WHEN 'payment_info'   THEN 4
        WHEN 'purchase'       THEN 5
        ELSE 99
    END;

-- 3. Strict user funnel (all prior steps must be completed in order).
WITH first_events AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'page_view'      THEN event_date END) AS page_view_at,
        MIN(CASE WHEN event_type = 'add_to_cart'    THEN event_date END) AS add_to_cart_at,
        MIN(CASE WHEN event_type = 'checkout_start' THEN event_date END) AS checkout_start_at,
        MIN(CASE WHEN event_type = 'payment_info'   THEN event_date END) AS payment_info_at,
        MIN(CASE WHEN event_type = 'purchase'       THEN event_date END) AS purchase_at
    FROM user_events
    GROUP BY user_id
),
funnel AS (
    SELECT 'page_view' AS step_name, 1 AS step_order, COUNT(*) AS users
    FROM first_events WHERE page_view_at IS NOT NULL

    UNION ALL
    SELECT 'add_to_cart', 2, COUNT(*)
    FROM first_events
    WHERE page_view_at IS NOT NULL
      AND add_to_cart_at > page_view_at

    UNION ALL
    SELECT 'checkout_start', 3, COUNT(*)
    FROM first_events
    WHERE page_view_at IS NOT NULL
      AND add_to_cart_at > page_view_at
      AND checkout_start_at > add_to_cart_at

    UNION ALL
    SELECT 'payment_info', 4, COUNT(*)
    FROM first_events
    WHERE page_view_at IS NOT NULL
      AND add_to_cart_at > page_view_at
      AND checkout_start_at > add_to_cart_at
      AND payment_info_at > checkout_start_at

    UNION ALL
    SELECT 'purchase', 5, COUNT(*)
    FROM first_events
    WHERE page_view_at IS NOT NULL
      AND add_to_cart_at > page_view_at
      AND checkout_start_at > add_to_cart_at
      AND payment_info_at > checkout_start_at
      AND purchase_at > payment_info_at
)
SELECT
    step_name,
    users,
    ROUND(100.0 * users / FIRST_VALUE(users) OVER (ORDER BY step_order), 2) AS conversion_from_start_pct,
    ROUND(100.0 * users / LAG(users) OVER (ORDER BY step_order), 2)        AS conversion_from_previous_step_pct,
    LAG(users) OVER (ORDER BY step_order) - users                            AS users_dropped_from_previous_step
FROM funnel
ORDER BY step_order;

-- 4. Funnel performance by traffic source.
WITH user_first_source AS (
    SELECT user_id, traffic_source
    FROM (
        SELECT
            user_id,
            traffic_source,
            ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY event_date) AS rn
        FROM user_events
    ) ranked
    WHERE rn = 1
),
first_events AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'page_view'      THEN event_date END) AS page_view_at,
        MIN(CASE WHEN event_type = 'add_to_cart'    THEN event_date END) AS add_to_cart_at,
        MIN(CASE WHEN event_type = 'checkout_start' THEN event_date END) AS checkout_start_at,
        MIN(CASE WHEN event_type = 'payment_info'   THEN event_date END) AS payment_info_at,
        MIN(CASE WHEN event_type = 'purchase'       THEN event_date END) AS purchase_at
    FROM user_events
    GROUP BY user_id
)
SELECT
    s.traffic_source,
    COUNT(*) AS page_view_users,
    SUM(CASE WHEN e.add_to_cart_at > e.page_view_at THEN 1 ELSE 0 END) AS cart_users,
    SUM(CASE WHEN e.add_to_cart_at > e.page_view_at
              AND e.checkout_start_at > e.add_to_cart_at THEN 1 ELSE 0 END) AS checkout_users,
    SUM(CASE WHEN e.add_to_cart_at > e.page_view_at
              AND e.checkout_start_at > e.add_to_cart_at
              AND e.payment_info_at > e.checkout_start_at THEN 1 ELSE 0 END) AS payment_users,
    SUM(CASE WHEN e.add_to_cart_at > e.page_view_at
              AND e.checkout_start_at > e.add_to_cart_at
              AND e.payment_info_at > e.checkout_start_at
              AND e.purchase_at > e.payment_info_at THEN 1 ELSE 0 END) AS purchase_users,
    ROUND(
        100.0 * SUM(CASE WHEN e.add_to_cart_at > e.page_view_at
                          AND e.checkout_start_at > e.add_to_cart_at
                          AND e.payment_info_at > e.checkout_start_at
                          AND e.purchase_at > e.payment_info_at THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS purchase_conversion_pct
FROM first_events e
JOIN user_first_source s ON e.user_id = s.user_id
WHERE e.page_view_at IS NOT NULL
GROUP BY s.traffic_source
ORDER BY purchase_conversion_pct DESC;

-- 5. Product-level purchase and revenue analysis.
SELECT
    product_id,
    COUNT(*) AS purchase_events,
    COUNT(DISTINCT user_id) AS purchasing_users,
    ROUND(SUM(amount), 2) AS revenue,
    ROUND(AVG(amount), 2) AS avg_order_value
FROM user_events
WHERE event_type = 'purchase'
GROUP BY product_id
ORDER BY revenue DESC;

-- 6. Time from first page view to purchase.
WITH first_events AS (
    SELECT
        user_id,
        MIN(CASE WHEN event_type = 'page_view' THEN event_date END) AS page_view_at,
        MIN(CASE WHEN event_type = 'purchase'  THEN event_date END) AS purchase_at
    FROM user_events
    GROUP BY user_id
)
SELECT
    COUNT(*) AS purchased_users,
    ROUND(
        AVG(
            EXTRACT(EPOCH FROM (purchase_at - page_view_at)) / 60.0
        ), 2
    ) AS avg_minutes_to_purchase
FROM first_events
WHERE page_view_at IS NOT NULL
  AND purchase_at > page_view_at;





































































































































































































