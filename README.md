# My Contributions

## SQL Queries to extract delivery times of delivered orders,co relation of dispatched to delivered % and avg orders per rider,avg number of orders per rider today and stock cover days.


## Query 1 - delivery times of delivered orders on a rider level (excluding first order)

- The query starts by defining a CTE named basetable. This CTE retrieves data from multiple tables (shipments, "shipmentsItem", "salesOrderItem", ride_order, ride, agent, and "salesOrder") using left outer joins. It selects various columns from these tables and applies some transformations and conditional logic to derive values such as dispatch_date, shipment_id, group_id, shipment_item_status, is_consumer_app, return_reason, return_comment, agent_name, agent_id, shipment_creation_date, so_creation_time, and deliver_time. The result is filtered based on a condition and ordered by s."createdAt" in descending order.

- The next CTE is delivery_times, which selects specific columns from the basetable CTE. It filters out rows where deliver_time is not null and groups the result by several columns.

- The extracting_delivery_times CTE assigns a rank to each row within each agent_id group based on the deliver_time, using the ROW_NUMBER() window function.

- The extracting_delivery_times_of_orders CTE filters the rows from extracting_delivery_times where the rank is greater than 1.This is done to calculate the average delivery times after excluding the initial order.

- The extracting_difference_of_delivery_times CTE calculates the time difference between each deliver_time and the previous one for each agent_id and dispatch_date group, using the LAG() window function.

- The orders_with_delivery_times CTE calculates the total number of orders delivered (total_orders_delivered), the average time difference between delivery times (average), and groups the result by dispatch_date, agent_name.

- The final_table CTE summarizes the data from orders_with_delivery_times, calculating the total number of orders delivered per agent_name, dispatch_date, and the average delivery time (avg_delivery_time).

- The final SELECT statement selects columns from the final_table CTE and performs additional calculations to convert the average delivery time to minutes. It also filters the result where dispatch_date is equal to the previous day and orders the result by avg_delivery_time_per_order_in_min in descending order.





## Query 2 - Co relation of dispatched to delivered % and avg orders per rider

- The query starts by defining a Common Table Expression (CTE) named basetable. This CTE retrieves data from multiple tables (shipment, routes, ride, and agent) using left joins. It calculates aggregate values grouped by the day of creation (date_trunc('day', s.created_at)). The calculated values include:

-  total_delivered: Counts the number of shipments that have a status of either 'delivered' or 'partial_returned'.
-  total_dispatched: Counts the number of shipments that have a status of 'delivered', 'dispatched', 'partial_returned', 'reattempt', or 'returned'.
-  total_riders: Counts the number of distinct rider IDs (agents) from the agent table.
-  The result is grouped by the truncated creation date (date_trunc('day', s.created_at)) and ordered in descending order by the date. The LIMIT 15 clause restricts the result to the top 15 rows.

- The second CTE named final_table selects columns from the basetable CTE. It also casts total_dispatched and total_delivered as float values. This step prepares the data for the final SELECT statement.

- The final SELECT statement uses the final_table CTE. It selects the date column along with two calculated columns:

-  dispatched_to_delivered_perc: Calculates the percentage of shipments that were delivered by dividing total_delivered by total_dispatched and multiplying by 100.
-  avg_order_per_rider: Calculates the average number of orders per rider by dividing total_dispatched by total_riders.

The query provides insights into the dispatched-to-delivered percentage and the average number of orders per rider on a daily basis. 

## Query 3 - Avg number of orders per rider today

- The query starts by defining a Common Table Expression (CTE) named basetable. This CTE retrieves data from multiple tables (shipment, routes, ride, and agent) using left joins. It selects various columns including id, full_name, created_at, status, count_orders, and first_order_attempt. The subquery inside the CTE calculates these values by joining the tables and applying conditional logic and aggregations. The result is then ordered by a.first_name, a.last_name, and status.

- The next CTE is final_table, which is used to summarize the data from basetable. It selects the created_at column as a date, counts the distinct id values to get the number of riders, and sums the count_orders to get the total number of orders. The result is grouped by created_at.

- The final SELECT statement selects columns from the final_table CTE and calculates the average number of orders per rider (total_orders / number_of_riders). The result is grouped by created_at and avg_order_per_rider.

The query aims to retrieve information about the average number of orders per rider for each date. 

## Query 4 - Stock cover days

- The query starts by defining a CTE named data. This CTE retrieves data from a subquery that joins multiple tables and applies various filters and aggregations. The resulting columns include id, item_name, sku, confirmationDate, category, quantity, and rank. The subquery groups the data by id, item_name, sku, confirmationDate, and category, and assigns a row number (rank) within each group based on the confirmationDate. The result is then filtered to include rows with a rank less than or equal to 30 and exclude rows where item_name is like 'Delist%'.

- The next CTEs (sale30days, sale15days, sale7days) calculate the sum of quantities (30_Days_Sale, 15_Days_Sale, 7_Days_Sale) for different time periods (30 days, 15 days, 7 days) based on the data from the data CTE. These CTEs group the data by id, item_name, and sku and also retrieve the minimum and maximum confirmation dates.

- The CTEs gm5 and kg1 retrieve specific products based on certain criteria. These CTEs select products with specific names and exclude certain patterns. The result includes columns such as id, name, and sku.

- The parentskutable CTE performs a left join on the kg1 and gm5 CTEs to retrieve matching id, name, and sku values where the sku in gm5 is not null.

- The cd CTE selects specific products from the "productCategory" table based on certain criteria, such as the product name containing specific measurements. The result includes all columns from the "productCategory" table and the related product table.

- The doodh CTE selects specific products from the "productCategory" table based on the category ID and product name criteria. The result includes all columns from the "productCategory" table and the related product table.

- The producttable CTE retrieves data from the product table and performs various calculations and joins with other CTEs to derive columns such as parentsku, packsize, buying_price, selling_price, and others.

- The mastertable CTE groups data from the producttable CTE by id, name, sku, and performs calculations such as summing sales quantities for different time periods.

- The categorytable CTE joins the mastertable CTE with the "productCategory" and category tables to retrieve the category name and filter based on specific category IDs.

- The salestable CTE joins the categorytable and product tables and calculates the total units sold for different time periods, grouping the data by category, name, sku, parentsku, buying price, and selling price.

- The finaltable CTE groups the data from the salestable CTE by category and parentsku and performs calculations such as summing units sold and averaging buying price.

- The final SELECT statement selects columns from the finaltable CTE and applies additional filters to exclude specific patterns and categories. The result is then grouped by category, name, and parentsku.
