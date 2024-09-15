--How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS NumberOfCustomers
FROM foodie_fi.subscriptions

--What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT EXTRACT(MONTH FROM s.start_date) AS StartingMonth, COUNT(*) AS TrialCount
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON p.plan_id = s.plan_id
WHERE p.plan_name LIKE 'trial'
GROUP BY StartingMonth
ORDER BY StartingMonth 

--What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT p.plan_name, COUNT(*) AS EventCount
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON p.plan_id = s.plan_id
WHERE EXTRACT(YEAR FROM start_date) > '2020'
GROUP BY p.plan_name
ORDER BY COUNT(p.plan_name) DESC

--What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(DISTINCT s.customer_id) AS CustomerCount, 
ROUND(COUNT(DISTINCT s.customer_id) * 100.00  / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions), 2) AS CustomerPercentage
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON p.plan_id = s.plan_id
WHERE p.plan_name = 'churn'

--How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT ROUND(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT customer_id) FROM foodie_fi.subscriptions), 2) AS CustomerPercentage
FROM foodie_fi.subscriptions AS s1
JOIN foodie_fi.plans AS p1 ON s1.plan_id = p1.plan_id
WHERE p1.plan_name = 'churn' AND s1.start_date > (
    SELECT s2.start_date
    FROM foodie_fi.subscriptions AS s2
    JOIN foodie_fi.plans AS p2 ON s2.plan_id = p2.plan_id
    WHERE p2.plan_name = 'trial' AND s2.customer_id = s1.customer_id)
AND NOT EXISTS (
    SELECT 1
    FROM foodie_fi.subscriptions AS s3
    JOIN foodie_fi.plans AS p3 ON s3.plan_id = p3.plan_id
    WHERE s3.customer_id = s1.customer_id
        AND s3.start_date < s1.start_date
        AND s3.start_date > (
            SELECT s2.start_date
            FROM foodie_fi.subscriptions AS s2
            JOIN foodie_fi.plans AS p2 ON s2.plan_id = p2.plan_id
            WHERE p2.plan_name = 'trial'
            AND s2.customer_id = s1.customer_id
        ))

--What is the number and percentage of customer plans after their initial free trial?
SELECT COUNT(*) AS NumberOfCustomerPlans,  
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(plan_id) FROM foodie_fi.subscriptions), 2) AS Percentage 
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON s.plan_id = p.plan_id
WHERE s.start_date > 
    (SELECT sub.start_date 
    FROM foodie_fi.subscriptions AS sub 
    JOIN foodie_fi.plans AS pl ON sub.plan_id = pl.plan_id
    WHERE pl.plan_name = 'trial' AND sub.customer_id = s.customer_id)

--What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
SELECT p.plan_name, COUNT(*) AS CustomerCount,  
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM foodie_fi.subscriptions AS s2 WHERE s2.start_date <= '2020-12-31'), 1) AS PercentageBreakDown 
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON s.plan_id = p.plan_id
WHERE s.start_date <= '2020-12-31'
GROUP BY p.plan_name
ORDER BY CustomerCount DESC;

--How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(DISTINCT s.customer_id) AS CustomerCount
FROM foodie_fi.subscriptions AS s
JOIN foodie_fi.plans AS p ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM s.start_date) = '2020' AND p.plan_name = 'pro annual'

--How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT ROUND(AVG(s2.start_date - 
    (SELECT s1.start_date
    FROM foodie_fi.subscriptions AS s1
    JOIN foodie_fi.plans AS p1 ON s1.plan_id = p1.plan_id
    WHERE p1.plan_name = 'trial' AND s1.customer_id = s2.customer_id)), 2) AS AVGDaysToUpgrade
FROM foodie_fi.subscriptions AS s2
JOIN foodie_fi.plans AS p2 ON s2.plan_id = p2.plan_id
WHERE p2.plan_name = 'pro annual'

--Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
SELECT 
CASE 
    WHEN DaysToUpgrade BETWEEN 0 AND 30 THEN '0-30 days'
    WHEN DaysToUpgrade BETWEEN 31 AND 60 THEN '31-60 days'
    WHEN DaysToUpgrade BETWEEN 61 AND 90 THEN '61-90 days'
    WHEN DaysToUpgrade BETWEEN 91 AND 120 THEN '91-120 days'
    WHEN DaysToUpgrade BETWEEN 121 AND 150 THEN '121-150 days'
    WHEN DaysToUpgrade BETWEEN 151 AND 180 THEN '151-180 days'
    ELSE '>181 days'
END AS period, COUNT(*) AS NumberOfCustomers, ROUND(AVG(DaysToUpgrade), 2) AS AverageDays
FROM 
    (SELECT ROUND((s2.start_date - 
        (SELECT s1.start_date
        FROM foodie_fi.subscriptions AS s1
        JOIN foodie_fi.plans AS p1 ON s1.plan_id = p1.plan_id
        WHERE p1.plan_name = 'trial' AND s1.customer_id = s2.customer_id)), 2) AS DaysToUpgrade
    FROM foodie_fi.subscriptions AS s2
    JOIN foodie_fi.plans AS p2 ON s2.plan_id = p2.plan_id
    WHERE p2.plan_name = 'pro annual') DaysToUpgrade
GROUP BY period

--How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT COUNT(DISTINCT s2.customer_id) AS DowngradedCustomers
FROM foodie_fi.subscriptions AS s2
JOIN foodie_fi.plans AS p2 ON s2.plan_id = p2.plan_id
JOIN foodie_fi.subscriptions AS s1 ON s2.customer_id = s1.customer_id
JOIN foodie_fi.plans AS p1 ON s1.plan_id = p1.plan_id
WHERE p2.plan_name = 'basic monthly' 
    AND p1.plan_name = 'pro annual'
    AND EXTRACT(YEAR FROM s2.start_date) = 2020
    AND EXTRACT(YEAR FROM s1.start_date)= 2020
    AND s2.start_date > s1.start_date
