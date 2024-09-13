-- What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price) AS total_amount
FROM dannys_diner.sales AS s 
LEFT JOIN dannys_diner.menu AS m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id

-- How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS days_visited
FROM dannys_diner.sales 
GROUP BY customer_id
ORDER BY customer_id

-- What was the first item from the menu purchased by each customer?
SELECT s.customer_id, m.product_name AS first_order_product
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m
ON m.product_id = s.product_id
WHERE s.order_date = (SELECT MIN(order_date) FROM sales WHERE customer_id = s.customer_id)
GROUP BY s.customer_id, m.product_name
ORDER BY s.customer_id

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS total_purchases
FROM dannys_diner.sales AS s
LEFT JOIN dannys_diner.menu AS m
ON m.product_id = s.product_id
GROUP BY m.product_name 
ORDER BY total_purchases DESC
LIMIT 1

-- Which item was the most popular for each customer?
SELECT s.customer_id, s.product_id
FROM (SELECT customer_id, 
            product_id,
            COUNT(customer_id) AS product_count 
            FROM sales 
            GROUP BY customer_id, product_id) 
            AS s
WHERE s.product_count = (
    SELECT MAX(product_count)
    FROM (
        SELECT customer_id, 
               product_id, 
               COUNT(*) AS product_count
        FROM sales
        GROUP BY customer_id, product_id
    ) AS sub
    WHERE sub.customer_id = s.customer_id
)
ORDER BY s.customer_id, s.product_id

-- Which item was purchased first by the customer after they became a member?
SELECT m.customer_id, s.product_id AS first_order_product
FROM (
SELECT m.customer_id, MIN(order_date) AS first_order
FROM dannys_diner.members AS m
LEFT JOIN dannys_diner.sales AS s 
ON s.customer_id = m.customer_id
WHERE m.join_date < s.order_date
GROUP BY m.customer_id
) AS m
LEFT JOIN dannys_diner.sales AS s 
ON s.customer_id = m.customer_id AND s.order_date = m.first_order

-- Which item was purchased just before the customer became a member?
SELECT m.customer_id, s.product_id AS last_order_product
FROM (
SELECT m.customer_id, MAX(order_date) AS last_order
FROM dannys_diner.members AS m
LEFT JOIN dannys_diner.sales AS s 
ON s.customer_id = m.customer_id
WHERE m.join_date > s.order_date
GROUP BY m.customer_id
) AS m
LEFT JOIN dannys_diner.sales AS s 
ON s.customer_id = m.customer_id AND m.last_order = s.order_date -- the reason that "AND m.last_order = s.order_date" is added is because you want the last_order date to equal the order date in question 

-- What is the total items and amount spent for each member before they became a member?
SELECT m.customer_id, COUNT(s.product_id) AS total_items, SUM(mu.price) AS total_amount_spent
FROM dannys_diner.members AS m
LEFT JOIN dannys_diner.sales AS s ON s.customer_id = m.customer_id
LEFT JOIN dannys_diner.menu AS mu ON s.product_id = mu.product_id 
WHERE s.order_date < m.join_date
GROUP BY m.customer_id
ORDER BY m.customer_id

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id, 
SUM(CASE WHEN s.product_id = 2 THEN 20 * m.price
ELSE 10 * m.price 
END) AS points
FROM dannys_diner.sales AS s 
LEFT JOIN dannys_diner.menu AS m ON s.product_id = m.product_id 
GROUP BY s.customer_id
ORDER BY s.customer_id

-- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT s.customer_id,
SUM (CASE WHEN s.order_date <= m.join_date + INTERVAL '7 DAY' THEN mu.price * 20 
ELSE mu.price * 10
END) AS points
FROM dannys_diner.members AS m
LEFT JOIN dannys_diner.sales AS s ON m.customer_id = s.customer_id
LEFT JOIN dannys_diner.menu AS mu ON s.product_id = mu.product_id  
WHERE s.order_date <= '2024-01-31' AND s.order_date >= m.join_date
GROUP BY s.customer_id
ORDER BY s.customer_id