--How many pizzas were ordered?
SELECT COUNT(order_id) AS pizzas_ordered
FROM pizza_runner.customer_orders

--How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS unique_customer_orders
FROM pizza_runner.customer_orders

--How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(runner_id) AS successful_deliveries
FROM pizza_runner.runner_orders
WHERE cancellation = ''
GROUP BY runner_id

--How many of each type of pizza was delivered?
SELECT p.pizza_name, COUNT(o.pizza_id) AS pizzas_delivered_successfully
FROM pizza_runner.customer_orders AS o
LEFT JOIN pizza_runner.runner_orders AS ro
ON o.order_id = ro.order_id
LEFT JOIN pizza_runner.pizza_names AS p
ON p.pizza_id = o.pizza_id
GROUP BY p.pizza_name

--How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
    customer_id,
    SUM(CASE WHEN pizza_names.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS VegetarianPizzasOrdered,
    SUM(CASE WHEN pizza_names.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS MeatloversPizzasOrdered
FROM customer_orders
JOIN pizza_names ON customer_orders.pizza_id = pizza_names.pizza_id
GROUP BY customer_id
ORDER BY customer_id

--What was the maximum number of pizzas delivered in a single order?
SELECT MAX(pizzas_delivered_per_order) AS pizzas_in_single_order
FROM ( 
SELECT co.order_id, COUNT(*) AS pizzas_delivered_per_order
FROM pizza_runner.runner_orders AS ro
LEFT JOIN pizza_runner.customer_orders AS co ON ro.order_id = co.order_id
GROUP BY co.order_id
) AS new_pizza 

--For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT 
co.customer_id,
SUM(CASE WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 1 ELSE 0 END) AS at_least_one_change,
SUM(CASE WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 1 ELSE 0 END) AS no_change
FROM customer_orders AS co
GROUP BY co.customer_id
ORDER BY co.customer_id
--How many pizzas were delivered that had both exclusions and extras?
SELECT 
SUM(CASE WHEN co.exclusions IS NOT NULL AND co.extras IS NOT NULL THEN 1 ELSE 0 END) AS exclusions_and_extra
FROM customer_orders AS co

--What was the total volume of pizzas ordered for each hour of the day?
SELECT COUNT(pizza_id) AS volume_pizzas, EXTRACT(HOUR FROM order_time) AS HOUR
FROM pizza_runner.customer_orders
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY EXTRACT(HOUR FROM order_time)

--What was the volume of orders for each day of the week?
SELECT COUNT(pizza_id) AS volume_pizzas, EXTRACT(DOW FROM order_time) AS day_of_week
FROM pizza_runner.customer_orders
GROUP BY EXTRACT(DOW FROM order_time)
ORDER BY EXTRACT(DOW FROM order_time)