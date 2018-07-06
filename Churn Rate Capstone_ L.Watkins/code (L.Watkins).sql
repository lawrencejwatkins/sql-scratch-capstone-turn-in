 --#1 take a look at the first 100 rows of data in 		the subscription table. identify the different 			segments
 SELECT * FROM subscriptions
 LIMIT 100;
 
 SELECT DISTINCT segment as 'Unique Segments' 
 FROM subscriptions;
 	-- two segments identified 30 & 87
 
 --#2 determine the range of months of data 					provided 
 SELECT * 
 FROM subscriptions
 WHERE subscription_end is NOT NULL;
 	-- seems that the churn rates will only include Jan., Feb., and Mar. of 2017
 
-- #3 let's start with a temporary table of months
  WITH months AS (
    SELECT '2017-01-01' as first_day, 
  			'2017-01-31' as last_day 
    UNION 
    SELECT '2017-02-01' as first_day, 
  			'2017-02-28' as last_day 
    UNION 
    SELECT '2017-03-01' as first_day, 
  			'2017-03-31' as last_day)
    SELECT * 
    FROM months;

-- #4 create a temp table 'cross_join' from 'subscriptions' & 'months'

  WITH months AS (
    SELECT '2017-01-01' as first_day, 
  			'2017-01-31' as last_day 
    UNION 
    SELECT '2017-02-01' as first_day, 
  			'2017-02-28' as last_day 
    UNION 
    SELECT '2017-03-01' as first_day, 
    		'2017-03-31' as last_day),
  cross_join AS (
		SELECT *
		FROM subscriptions 
    		CROSS JOIN months)
    SELECT * 
    FROM cross_join
    LIMIT 10;

-- #5 create a temp table, 'status' from 'cross_join'
 	WITH months AS (
    SELECT '2017-01-01' as first_day, 
  			'2017-01-31' as last_day
    UNION 
    SELECT '2017-02-01' as first_day, 
  			'2017-02-28' as last_day 
    UNION 
    SELECT '2017-03-01' as first_day, 
  			'2017-03-31' as last_day),
	cross_join AS (
		SELECT *
		FROM subscriptions 
				CROSS JOIN months),
	status AS (
    SELECT id, first_day AS month,
			CASE
				WHEN (subscription_start < first_day)
						AND (segment = 87)
  			THEN 1 ELSE 0
			END as is_active_87,
			CASE
				WHEN (subscription_start < first_day)
						AND (segment = 30)
  			THEN 1 ELSE 0
			END as is_active_30
		FROM cross_join)
  SELECT * 
  FROM status
	LIMIT 10;

-- #6 add 'is_canceled_87' and 'is_canceled_30'
 	WITH months AS (
    SELECT '2017-01-01' as first_day, 
  		'2017-01-31' as last_day 
		UNION 
		SELECT '2017-02-01' as first_day, 
  		'2017-02-28' as last_day 
		UNION 
		SELECT '2017-03-01' as first_day, 
  		'2017-03-31' as last_day),
  cross_join AS (
		SELECT *
		FROM subscriptions 
			CROSS JOIN months),
  status AS(
    SELECT id, 
    	first_day AS month,
			CASE
				WHEN (subscription_start < first_day)
					AND (segment = 87)
  			THEN 1 ELSE 0
			END as is_active_87,
    	CASE
				WHEN (subscription_start < first_day)
					AND (segment = 30)
  			THEN 1 ELSE 0
			END as is_active_30,
			CASE
				WHEN (subscription_end BETWEEN first_day 	
              AND last_day)
					AND (segment = 87)
  			THEN 1 ELSE 0
			END as is_canceled_87,
			CASE
				WHEN (subscription_end BETWEEN first_day 	
              AND last_day)
					AND (segment = 30)
  			THEN 1 ELSE 0
			END as is_canceled_30
		FROM cross_join)
	SELECT * 
	FROM status
	LIMIT 10;


-- #7 create temp table 'status_aggregate'to sum 			the active and canceled subscriptions for each 			segment each month 
 	WITH months AS (
    SELECT '2017-01-01' as first_day, 
  		'2017-01-31' as last_day 
		UNION 
		SELECT '2017-02-01' as first_day, 
  		'2017-02-28' as last_day 
		UNION 
		SELECT '2017-03-01' as first_day, 
  		'2017-03-31' as last_day),
	cross_join AS (
		SELECT *
		FROM subscriptions 
			CROSS JOIN months),
	status AS(
    SELECT id, 
    		first_day AS month,
				CASE
					WHEN (subscription_start < first_day)
						AND (segment = 87)
  				THEN 1 ELSE 0
				END as is_active_87,
				CASE
					WHEN (subscription_start < first_day)
						AND (segment = 30)
  				THEN 1 ELSE 0
				END as is_active_30,
				CASE
					WHEN (subscription_end BETWEEN first_day 
                AND last_day)
						AND (segment = 87)
  				THEN 1 ELSE 0
				END as is_canceled_87,
				CASE
					WHEN (subscription_end BETWEEN first_day 
                AND last_day)
						AND (segment = 30)
  				THEN 1 ELSE 0
				END as is_canceled_30
		FROM cross_join),
	status_aggregate AS (
    SELECT month,
			SUM (is_active_87) as sum_active_87,
			SUM (is_active_30) as sum_active_30,
			SUM (is_canceled_87) as sum_canceled_87,
 			SUM (is_canceled_30) as sum_calceled_30
		FROM status
		GROUP BY month)
	SELECT * 
	FROM status_aggregate
	LIMIT 10;


-- #8 churn rate calculation 
WITH months AS (
  SELECT '2017-01-01' as first_day, 
  	'2017-01-31' as last_day 
  UNION 
  SELECT '2017-02-01' as first_day, 
  	'2017-02-28' as last_day 
  UNION 
  SELECT '2017-03-01' as first_day, 
  	'2017-03-31' as last_day),
cross_join AS (
  SELECT *
	FROM subscriptions 
		CROSS JOIN months),
status AS(
  SELECT id, 
  	first_day AS month,
		CASE
			WHEN (subscription_start < first_day)
				AND (segment = 87)
  		THEN 1 ELSE 0
		END as is_active_87,
		CASE
			WHEN (subscription_start < first_day)
				AND (segment = 30)
  		THEN 1 ELSE 0
		END as is_active_30,
		CASE
  		WHEN (subscription_end BETWEEN first_day 
            AND last_day)
				AND (segment = 87)
  		THEN 1 ELSE 0
		END as is_canceled_87,
		CASE
			WHEN (subscription_end BETWEEN first_day 
            AND last_day)
				AND (segment = 30)
  		THEN 1 ELSE 0
		END as is_canceled_30
	FROM cross_join),
status_aggregate AS (
  SELECT month,
		SUM (is_active_87) as sum_active_87,
		SUM (is_active_30) as sum_active_30,
		SUM (is_canceled_87) as sum_canceled_87,
 		SUM (is_canceled_30) as sum_canceled_30
	FROM status
	GROUP BY month)
SELECT month,  
	ROUND (1.0 * (status_aggregate.sum_canceled_87)/
         (status_aggregate.sum_active_87),4) 
         as churn_rate_87,
  ROUND (1.0 * (status_aggregate.sum_canceled_30)/
         (status_aggregate.sum_active_30),4) 
         as churn_rate_30
FROM status_aggregate 
GROUP BY month;  