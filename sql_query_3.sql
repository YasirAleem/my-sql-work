WITH basetable AS (
    SELECT
        id,
        full_name,
        created_at,
        status,
        count_orders,
        first_order_attempt
    FROM (
        SELECT
            a.id,
            s.created_at,
            a.first_name AS rider_first_name,
            a.last_name AS rider_last_name,
            CONCAT(a.first_name, ' ', a.last_name) AS full_name,
            s.status,
            CASE WHEN s.status NOT IN ('packed') THEN COUNT(s.*) ELSE 0 END AS count_orders,
            CAST(MIN(CASE WHEN s.status NOT IN ('dispatched') THEN s.updated_at END) AS TIMESTAMP) AS first_order_attempt
        FROM
            shipment s
        LEFT OUTER JOIN
            routes r ON s.route_id = r.route_id
        LEFT OUTER JOIN
            ride rd ON r.route_id = rd.route_id
        LEFT OUTER JOIN
            agent a ON rd.agent_id = a.id
        WHERE
            to_char(s.created_at, 'Day') = to_char(date(current_timestamp), 'Day')
            AND s.created_at::timestamp::time <= (current_time)
        GROUP BY
            1, 2, 3, 4, 5, 6
        ORDER BY
            a.first_name, a.last_name, status ASC
    ) AS a
    ORDER BY
        full_name, first_order_attempt
),
final_table AS (
    SELECT
        CAST(basetable.created_at AS DATE),
        COUNT(DISTINCT id) AS number_of_riders,
        SUM(count_orders) AS total_orders
    FROM
        basetable
    GROUP BY
        1
)
SELECT
    final_table.created_at,
    (total_orders / number_of_riders) AS avg_order_per_rider
FROM
    final_table
GROUP BY
    1, 2;
