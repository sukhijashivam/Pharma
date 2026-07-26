USE [pharma-analysis]

--Q3: Which countries generate the most revenue?
SELECT 
    gp.country,
    SUM(CAST(p.Sales AS BIGINT)) AS Revenue,
    COUNT(DISTINCT cp.customer_name) AS Customer_Count,
    AVG(CAST(p.Sales AS BIGINT)) AS AverageSales,
    ROUND(SUM(CAST(p.Sales AS BIGINT)) / NULLIF(COUNT(DISTINCT cp.customer_name), 0), 2) AS AvgRevenuePerCustomer
FROM fact_sales p
    LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
    LEFT JOIN dim_customer cp ON p.customer_id = cp.customer_id
GROUP BY gp.country
ORDER BY Revenue DESC
-- There is a huge Revenue gap between these two countries, lets see why is that.
/* CAVEAT (discovered during Time Trends theme): this comparison spans unequal time coverage —
   Germany has data for 2017-2020 (4 years), Poland has data for 2018 only. Confirmed this is a
   genuine property of the source dataset, not a pipeline bug (checked against raw [pharma-data]).
   The magnitude of this gap is therefore NOT directly comparable as-is. See the fair, 2018-only
   comparison below (Q6) before drawing conclusions from this query alone. */

-- ------------------------------------------------------------------------------------------------------------------------------------

--Q4: Why the revenue gap?

-- Could there be a difference between the product mix for the two countries, which could be the reason behind revenue difference?
SELECT 
    Country, 
    product_class,
    SUM(CAST(p.Sales AS BIGINT)) AS TotalSales,
    ROUND(
        100.0 * SUM(CAST(p.Sales AS BIGINT))
        /SUM(SUM(CAST(p.sales AS BIGINT))) OVER(PARTITION BY Country)
        ,2) AS percentage_contribution

FROM fact_sales p
    LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
    LEFT JOIN dim_product pp ON p.product_id = pp.product_id
GROUP BY Country, product_class
ORDER BY Country, percentage_contribution DESC
/* From this query, we interpret:
    - for both the countries the percentage product mix does not have much deviation, ie, the whole of the pool is fairly distributed, with variation range of 5-8%
    - for Germany, Analgesics constitute for the most(20%) of sales, while Antimalarials for the least(12%)
    - for Poland, Antiseptics constitute for the most(19.7%) of sales, while Antimalarials for the least(13.6%) */

-- Could there be a difference between the Channel of sales for the two countries, which could be the reason behind revenue difference?
SELECT 
    Country, 
    channel,
    SUM(CAST(p.Sales AS BIGINT)) AS TotalSales,
    ROUND(
        100.0 * SUM(CAST(p.Sales AS BIGINT))
        /SUM(SUM(CAST(p.sales AS BIGINT))) OVER(PARTITION BY Country)
        ,2) AS percentage_contribution

FROM fact_sales p
    LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
    LEFT JOIN dim_customer cp ON p.customer_id = cp.customer_id
GROUP BY Country, channel
ORDER BY Country, percentage_contribution DESC
/* From this query, we interpret:
    - For both the Countries, the cannel/mode of sale is almost evenly distributed amongst Pharmacy and Hospitals*/

-- Could the volume or sales per unit be the differenciator for the two countries, which could be the reason behind revenue difference
SELECT 
    gp.country,
    SUM(CAST(p.Sales AS BIGINT)) AS TotalSales,
    SUM(Quantity) AS Volume,
    ROUND(
        SUM(CAST(p.sales AS BIGINT))/ SUM(p.quantity),
        2) AS SalesPerUnit
FROM fact_sales p
    LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
GROUP BY gp.country 
/* We can make following interpretations from this data:
    - Here we can see, even though sales per unit is comparable for both the countries, the volume of sales for Germany is 16 folds more 
        than that of Poland, which is probably the prime differenciator and the reason behind the Revenue difference between the countires.
    - Given I don't have population/market-size data in this dataset,We can't conclude whether the gap represents an opportunity in Poland
        or just reflects market size is something I can't determine from this data alone.
    - CAVEAT: this "16 folds" figure is also affected by the unequal time-coverage issue above — Germany's volume
        here is summed across 4 years, Poland's across 1. See Q6 for the fair, single-year comparison. */

-- --------------------------------------------------------------------------------------------------------------------------------------------

--Q5:Within each country, which customers are generating meaningfully below-average revenue relative to their peers?

WITH CustomRevenue AS (
    SELECT
        gp.country,
        cp.customer_name,
        SUM(CAST(p.sales AS BIGINT)) AS customerRevenue
    FROM fact_sales p
    LEFT JOIN dim_geography gp
        ON p.geo_id = gp.geo_id
    LEFT JOIN dim_customer cp
        ON p.customer_id = cp.customer_id
    GROUP BY gp.country, cp.customer_name
),
PerformMetric AS (
    SELECT
        country,
        customer_name,
        customerRevenue,
        AVG(customerRevenue) OVER (PARTITION BY country) AS AvgRevenue,
        STDEV(customerRevenue) OVER (PARTITION BY country) AS StdDevRevenue,
        (CAST(customerRevenue AS FLOAT) - AVG(customerRevenue) OVER (PARTITION BY country))
            / NULLIF(STDEV(customerRevenue) OVER (PARTITION BY country), 0) AS ZScore
    FROM CustomRevenue
),
Tiered AS (
    SELECT
        *,
        CASE
            WHEN ZScore < -2   THEN 'Highly Underperforming'
            WHEN ZScore < -1   THEN 'Underperforming'
            WHEN ZScore < 1    THEN 'Average Performing'
            WHEN ZScore < 2    THEN 'Overperforming'
            ELSE 'Highly Overperforming'
        END AS Performance
    FROM PerformMetric
)

SELECT *
    --Performance,
    --COUNT(*) AS CustomerCount
FROM Tiered
-- GROUP BY Performance
ORDER BY
    CASE
        WHEN Performance = 'Highly Underperforming' THEN 1
        WHEN Performance = 'Underperforming' THEN 2
        WHEN Performance = 'Average Performing' THEN 3
        WHEN Performance = 'Overperforming' THEN 4
        WHEN Performance = 'Highly Overperforming' THEN 5
    END;

/* Here we made a dedicated column in the query to showcase performance metrics for a particular customer, based on their country average:
    - The performance tiers (z-score bands):
        - z < -2            : Highly Underperforming
        - -2 <= z < -1      : Underperforming
        - -1 <= z < 1       : Average Performing
        - 1 <= z < 2        : Overperforming
        - z >= 2            : Highly Overperforming
    - Given I don't have population/market-size data in this dataset,We can't conclude whether the performance represents an opportunity 
        or just reflects market size is something I can't determine from this data alone.
    - The above query can be used in two different ways :
        We can return the number of customers in each performance segement - commented out
        or, we can return all the customers, with performance column against each one - done above
*/

-- --------------------------------------------------------------------------------------------------------------------------------------------

--Q6: Fair comparison — Germany vs Poland, restricted to their one overlapping year (2018) only

SELECT 
    gp.country,
    SUM(CAST(p.Sales AS BIGINT)) AS Revenue2018,
    SUM(p.Quantity) AS Volume2018,
    COUNT(DISTINCT cp.customer_name) AS Customer_Count_2018,
    ROUND(SUM(CAST(p.Sales AS BIGINT)) / NULLIF(COUNT(DISTINCT cp.customer_name), 0), 2) AS AvgRevenuePerCustomer2018,
    ROUND(SUM(CAST(p.Sales AS BIGINT)) / NULLIF(SUM(p.Quantity), 0), 2) AS SalesPerUnit2018
FROM fact_sales p
    LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
    LEFT JOIN dim_customer cp ON p.customer_id = cp.customer_id
    LEFT JOIN dim_date d ON p.date_id = d.date_id
WHERE d.Year = 2018
GROUP BY gp.country
ORDER BY Revenue2018 DESC

/* From this fair, single-year comparison we can interpret: 
    - Germany is still ahead of Poland in all fronts. Overall customer count of Germany is more that twice that of Poland, which may be the reason behind x4 the volume for Germany
    - Hence overall Germany has performed better than Poland, but since we dont have the population data, we cannot be sure if this result is performance or demographic based)
    - Once we control for the unequal time period, Germany's per-customer revenue advantage drops from the original ~6x (unfiltered) down to just ~1.5x.
*/