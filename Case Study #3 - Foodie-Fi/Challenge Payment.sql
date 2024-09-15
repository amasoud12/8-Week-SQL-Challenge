--The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:
CREATE TABLE foodie_fi.payments (
customer_id INTEGER,
payment_date DATE, 
amount DECIMAL(10,2)
)

--monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
INSERT INTO foodie_fi.payments (customer_id, payment_date, amount)
SELECT s.customer_id, 
generate_series( s.start_date, '2020-12-31', INTERVAL '1 month') AS payment_date, 
p.price AS amount
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON s.plan_id = p.plan_id
WHERE p.plan_name LIKE '%monthly%' AND s.start_date <= '2020-12-31'

--upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
INSERT INTO foodie_fi.payments (customer_id, payment_date, amount)
SELECT s.customer_id, 
s2.start_date AS payment_date, 
p2.price - p1.price AS amount
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.subscriptions AS s2 ON s.customer_id = s2.customer_id AND s2.start_date > s.start_date
JOIN foodie_fi.plans p1 ON s.plan_id = p1.plan_id AND p1.plan_name = 'basic monthly'
JOIN foodie_fi.plans p2 ON s2.plan_id = p2.plan_id AND p2.plan_name = 'pro monthly'
WHERE EXTRACT(YEAR FROM s2.start_date) = '2020'

--upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
INSERT INTO foodie_fi.payments (customer_id, payment_date, amount)
SELECT 
  s.customer_id, 
  s.start_date + INTERVAL '1 month' AS payment_date, 
  p2.price AS amount
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.subscriptions AS s2 
  ON s.customer_id = s2.customer_id 
  AND s2.start_date > s.start_date
JOIN foodie_fi.plans AS p1 
  ON s.plan_id = p1.plan_id 
  AND p1.plan_name = 'pro monthly'
JOIN foodie_fi.plans AS p2 
  ON s2.plan_id = p2.plan_id 
  AND p2.plan_name = 'pro annual'
WHERE EXTRACT(YEAR FROM s2.start_date) = 2020
  AND s2.start_date = (
    SELECT MIN(s2_inner.start_date)
    FROM foodie_fi.subscriptions AS s2_inner
    JOIN foodie_fi.plans AS p2_inner 
      ON s2_inner.plan_id = p2_inner.plan_id 
      AND p2_inner.plan_name = 'pro annual'
    WHERE s2_inner.customer_id = s.customer_id 
      AND s2_inner.start_date > s.start_date)

--once a customer churns they will no longer make payments
DELETE FROM foodie_fi.payments
WHERE EXISTS( 
SELECT 1 
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON s.plan_id = p.plan_id
WHERE p.plan_name = 'churn' AND s.start_date <=payments.payment_date)