/*
Question #1: What are the unique states values available in the customer data? Count the number of customers associated to each state.
Expected columns: state, total_customers 
*/

-- q1 solution:
SELECT DISTINCT cu.state AS state,
	COUNT(DISTINCT cu.customer_id) AS total_customers
FROM customers cu
GROUP BY state 
;

/*
Question #2: It looks like the state data is not 100% clean and your manager already one issue:
(1) We have a value called "US State" which doesn't make sense.
After a careful investigation your manager concluded that the "US State" customers should be assigned to California.
What is the total number of orders that have been completed for every state? Only include orders for which 
customer data is available.
Expected columns: clean_state, total_completed_orders.
*/

-- q2 solution:
SELECT 
	CASE WHEN cu.state = 'US State' THEN 'California'
       ELSE cu.state
    END AS clean_state,
    COUNT(DISTINCT o.order_id) AS total_completed_orders
FROM orders o 
INNER JOIN customers cu ON cu.customer_id = o.user_id
WHERE o.status = 'Complete'
GROUP BY clean_state
;

/*
Question #3: After excluding some orders since the customer information was not available, your manager gets back to and stresses what 
we can never presented a number that is missing any orders even if our customer data is bad.
What is the total number of orders, number of Nike Official orders, and number of Nike Vintage orders that are completed 
by every state?
If customer data is missing, you can assign the records to "Missing Data".
Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders.
*/

-- q3 solution:
SELECT
	CASE WHEN cu.state = 'US State' THEN 'California' 
     	 WHEN cu.state IS NULL THEN 'Missing Data'
		 ELSE cu.state
    END AS clean_state,
  COUNT(DISTINCT o.order_id) AS total_completed_orders,
  COUNT(DISTINCT oi.order_id) AS official_completed_orders,
  COUNT(DISTINCT oiv.order_id) AS vintage_completed_orders
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_items_vintage oiv ON o.order_id = oiv.order_id
LEFT JOIN customers cu ON o.user_id = cu.customer_id
WHERE o.status = 'Complete'
GROUP BY clean_state
;

/*
Question #4: When reviewing sales performance, there is one metric we can never forget; revenue. 
Reuse the query you created in question 3 and add the revenue (aggregate of the sales price) to your table: 
(1) Total revenue for the all orders (not just the completed!)
Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, total_revenue.
*/

-- q4 solution:
WITH complete AS (
SELECT
	CASE WHEN cu.state = 'US State' THEN 'California' 
     	 WHEN cu.state IS NULL THEN 'Missing Data'
		 ELSE cu.state
    END AS clean_state,
  COUNT(DISTINCT o.order_id) AS total_completed_orders,
  COUNT(DISTINCT oi.order_id) AS official_completed_orders,
  COUNT(DISTINCT oiv.order_id) AS vintage_completed_orders
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_items_vintage oiv ON o.order_id = oiv.order_id
LEFT JOIN customers cu ON o.user_id = cu.customer_id
WHERE o.status = 'Complete'
GROUP BY clean_state

),
items_combined AS (
SELECT * FROM order_items oi 
UNION ALL 
SELECT * FROM order_items_vintage oiv
),
total_rev AS (
SELECT 
  CASE WHEN cu.state = 'US State' THEN 'California' 
       WHEN cu.state IS NULL THEN 'Missing Data'
	   ELSE cu.state
  END AS clean_state,
  SUM(it.sale_price) AS total_revenue
FROM items_combined it
LEFT JOIN customers cu ON it.user_id = cu.customer_id
GROUP BY clean_state
)
SELECT
	c.clean_state,
	c.total_completed_orders,
	c.official_completed_orders,
	c.vintage_completed_orders,
	tr.total_revenue
FROM complete c
LEFT JOIN total_rev tr ON c.clean_state = tr.clean_state
;

/*
Question #5: The leadership team is also interested in understanding the number of order items that get returned. 
Reuse the query of question 4 and add an additional metric to the table: 
(1) Number of order items that have been returned (items where the return date is populated)
Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders,
total_revenue,returned_items.
*/

-- q5 solution:
WITH complete AS (
SELECT
	CASE WHEN cu.state = 'US State' THEN 'California' 
     	 WHEN cu.state IS NULL THEN 'Missing Data'
		 ELSE cu.state
   END AS clean_state,
  COUNT(DISTINCT o.order_id) AS total_completed_orders,
  COUNT(DISTINCT oi.order_id) AS official_completed_orders,
  COUNT(DISTINCT oiv.order_id) AS vintage_completed_orders
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_items_vintage oiv ON o.order_id = oiv.order_id
LEFT JOIN customers cu ON o.user_id = cu.customer_id
WHERE o.status = 'Complete'
GROUP BY clean_state

),
items_combined AS (
SELECT * FROM order_items oi 
UNION ALL 
SELECT * FROM order_items_vintage oiv
),
total_rev AS (
SELECT 
  CASE WHEN cu.state = 'US State' THEN 'California' 
     	WHEN cu.state IS NULL THEN 'Missing Data'
		ELSE cu.state
  END AS clean_state,
  SUM(it.sale_price) AS total_revenue
FROM items_combined it
LEFT JOIN customers cu ON it.user_id = cu.customer_id
GROUP BY clean_state
),
items_returned AS (
SELECT 
  CASE WHEN cu.state = 'US State' THEN 'California' 
       WHEN cu.state IS NULL THEN 'Missing Data'
	   ELSE cu.state
  END AS clean_state,
  COUNT(DISTINCT ic.order_item_id) AS returned_items
FROM items_combined ic
LEFT JOIN customers cu ON ic.user_id = cu.customer_id
WHERE ic.returned_at IS NOT NULL
GROUP BY clean_state
)
SELECT
	c.clean_state,
	c.total_completed_orders,
	c.official_completed_orders,
	c.vintage_completed_orders,
	tr.total_revenue,
    ir.returned_items
FROM complete c
LEFT JOIN total_rev tr ON c.clean_state = tr.clean_state
LEFT JOIN items_returned ir ON c.clean_state = ir.clean_state
;

/*
Question #6: When looking at the number of returned items by itself, it is hard to understand what number of returned items is acceptable.
This is mainly caused by the fact that we don't have a benchmark at the moment.
Because of that, it is valuable to add an additional metric that looks at the percentage of returned order items divided
by the total order items, we can call this the return rate.
Reuse the query of question 5 and integrate the return rate into your table.
Expected columns: clean_state, total_completed_orders, official_completed_orders, vintage_completed_orders, 
total_revenue,returned_items,return_rate.
*/

-- q6 solution:
WITH complete AS (
SELECT
	CASE WHEN cu.state = 'US State' THEN 'California' 
         WHEN cu.state IS NULL THEN 'Missing Data'
	     ELSE cu.state
   END AS clean_state,
  COUNT(DISTINCT o.order_id) AS total_completed_orders,
  COUNT(DISTINCT oi.order_id) AS official_completed_orders,
  COUNT(DISTINCT oiv.order_id) AS vintage_completed_orders
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN order_items_vintage oiv ON o.order_id = oiv.order_id
LEFT JOIN customers cu ON o.user_id = cu.customer_id
WHERE o.status = 'Complete'
GROUP BY clean_state

),
items_combined AS (
SELECT * FROM order_items oi 
UNION ALL 
SELECT * FROM order_items_vintage oiv
),
total_rev AS (
SELECT 
  CASE WHEN cu.state = 'US State' THEN 'California' 
       WHEN cu.state IS NULL THEN 'Missing Data'
	   ELSE cu.state
   END AS clean_state,
  SUM(it.sale_price) AS total_revenue
FROM items_combined it
LEFT JOIN customers cu ON it.user_id = cu.customer_id
GROUP BY clean_state
),
items_returned AS (
SELECT 
  CASE WHEN cu.state = 'US State' THEN 'California' 
       WHEN cu.state IS NULL THEN 'Missing Data'
	   ELSE cu.state
   END AS clean_state,
  COUNT(DISTINCT CASE WHEN ic.returned_at IS NOT NULL THEN ic.order_item_id END) AS returned_items,
  COUNT(DISTINCT CASE WHEN ic.returned_at IS NOT NULL THEN ic.order_item_id END)/CAST(COUNT(DISTINCT ic.order_item_id) AS FLOAT) AS return_rate
FROM items_combined ic
LEFT JOIN customers cu ON ic.user_id = cu.customer_id
GROUP BY clean_state
)
SELECT
	c.clean_state,
	c.total_completed_orders,
	c.official_completed_orders,
	c.vintage_completed_orders,
	tr.total_revenue,
    ir.returned_items,
    ir.return_rate
FROM complete c
LEFT JOIN total_rev tr ON c.clean_state = tr.clean_state
LEFT JOIN items_returned ir ON c.clean_state = ir.clean_state
;