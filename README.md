# my-sql-work
SQL queries

SELECT * from 
(WITH basetable AS (
SELECT 
    CASE
        WHEN ro.created_at IS NULL THEN DATE(s."createdAt" + INTERVAL '1' DAY)
        ELSE DATE(ro.created_at)
    END AS dispatch_date,
    s.id AS shipment_id,
    CASE
        WHEN soi."groupId" IS NULL THEN 111
        ELSE soi."groupId"
    END AS group_id,
    CASE
        WHEN s_i.status IN ('reattempt') THEN s_i.status
        WHEN si.oos_quantity::INT > 0 THEN 'out_of_stock'
        ELSE si."shipmentItemStatus"::VARCHAR
    END AS shipment_item_status,
    so."platformType" AS is_consumer_app,
    CASE
        WHEN ro.return_type IS NULL THEN s_i.return_type
        ELSE ro.return_type
    END AS return_reason,
    CASE
        WHEN ro.return_comment IS NULL THEN s_i.return_comment
        ELSE ro.return_comment
    END AS return_comment,
    CONCAT(a.first_name, ' ', a.last_name) AS agent_name,
    a.id AS agent_id,
    s."createdAt" AS shipment_creation_date,
    so."createdAt" + (5 * INTERVAL '1 hour') AS so_creation_time,
    CASE
        WHEN (marked_delivered_at) IS NULL THEN (marked_arrived_at)
        ELSE (marked_delivered_at)
    END AS deliver_time
FROM
    shipments s
    LEFT OUTER JOIN "shipmentsItem" si ON s.id = si."shipmentId"
    LEFT OUTER JOIN "salesOrderItem" soi ON si."salesOrderItemId" = soi.id
    LEFT OUTER JOIN ride_order ro ON s.id = ro.shipment_id
    LEFT OUTER JOIN ride r ON ro.ride_id = r.id
    LEFT OUTER JOIN agent a ON r.agent_id = a.id
    LEFT OUTER JOIN shipment_item s_i ON si.id = s_i.shipment_item_id
    LEFT OUTER JOIN "salesOrder" so ON soi."salesOrderId" = so.id
WHERE
    (s."createdAt") < CURRENT_DATE - INTERVAL '0 day'
ORDER BY
    s."createdAt" DESC),

delivery_times AS (
    SELECT
        dispatch_date,
        shipment_id,
        agent_id,
        agent_name,
        deliver_time,
        shipment_creation_date
    FROM
        basetable
    WHERE
        deliver_time IS NOT NULL
    GROUP BY
        1, 2, 3, 4, 5, 6
),
extracting_delivery_times AS (
    SELECT
        dispatch_date,
        agent_id,
        agent_name,
        ROW_NUMBER() OVER (PARTITION BY agent_id ORDER BY deliver_time) AS rank,
        deliver_time
    FROM
        delivery_times
),
extracting_delivery_times_of_orders AS (
    SELECT
        dispatch_date,
        agent_id,
        agent_name,
        deliver_time,
        rank
    FROM
        extracting_delivery_times
    WHERE
        rank > 1
),
extracting_difference_of_delivery_times AS (
    SELECT
        dispatch_date,
        rank,
        agent_name,
        deliver_time,
        deliver_time - LAG(deliver_time) OVER (PARTITION BY agent_id, dispatch_date ORDER BY deliver_time, dispatch_date) AS difference_between_delivery_time
    FROM
        extracting_delivery_times_of_orders
    WHERE
        agent_name NOT IN ('Ahmed Mujtaba', 'Usama Mughal', 'Muhammad Zahid', 'Sadaat Shah', 'Faizan Soomro')
),
orders_with_delivery_times AS (
    SELECT
        COUNT(rank) AS total_orders_delivered,
        dispatch_date,
        agent_name,
        AVG(difference_between_delivery_time) AS average
    FROM
        extracting_difference_of_delivery_times
    GROUP BY
        2, 3
),
final_table AS (
    SELECT
        agent_name,
        SUM(total_orders_delivered) AS total_orders_delivered,
        dispatch_date,
        AVG(average) AS avg_delivery_time
    FROM
        orders_with_delivery_times
    GROUP BY
        1, 3
    ORDER BY
        1 DESC
)
SELECT
    dispatch_date,
    agent_name,
    total_orders_delivered,
    (EXTRACT(DAY FROM avg_delivery_time) * 24 + EXTRACT(HOUR FROM avg_delivery_time)) + EXTRACT(MINUTE FROM avg_delivery_time) AS avg_delivery_time_per_order_in_min
FROM
    final_table
WHERE
    dispatch_date = CURRENT_DATE - INTERVAL '1 day') as a 
ORDER BY
    avg_delivery_time_per_order_in_min DESC;

