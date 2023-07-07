WITH basetable AS (
    SELECT
        date_trunc('day', s.created_at) AS date,
        COUNT(CASE WHEN s.status IN ('delivered', 'partial_returned') THEN 'delivered' END) AS total_delivered,
        COUNT(CASE WHEN s.status IN ('delivered', 'dispatched', 'partial_returned', 'reattempt', 'returned') THEN 'total_dispatched' END) AS total_dispatched,
        COUNT(DISTINCT a.id) AS total_riders
    FROM
        shipment s
    LEFT JOIN
        routes r ON s.route_id = r.route_id
    LEFT JOIN
        ride rd ON r.route_id = rd.route_id
    LEFT JOIN
        agent a ON rd.agent_id = a.id
    WHERE
        s.created_at < current_date
    GROUP BY
        1
    ORDER BY
        1 DESC
    LIMIT 15
),
final_table AS (
    SELECT
        date,
        CAST(total_dispatched AS float),
        CAST(total_delivered AS float),
        total_riders
    FROM
        basetable
)
SELECT
    date,
    (total_delivered / total_dispatched) * 100 AS dispatched_to_delivered_perc,
    (total_dispatched / total_riders) AS avg_order_per_rider
FROM
    final_table;
