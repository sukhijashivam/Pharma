USE [pharma-analysis]

--Q6: How does Pharmacy vs. Hospital perform in revenue and product mix — do they buy differently?

-- on the basis of revenue
SELECT 
	Channel,
	SUM(CAST(p.sales AS BIGINT)) AS Revenue,
	SUM(Quantity) AS Volume
FROM fact_sales p
	LEFT JOIN dim_customer c ON p.customer_id = c.customer_id
	LEFT JOIN dim_product pp ON p.product_id = pp.product_id
GROUP BY Channel
-- Both Hospitals and Pharmacies have somewhat comparable revenues & Volume, but pharmacy surpasses Hospitals overall.

-- on the basis of product mix:
SELECT
	Channel,
	Product_class,
	CAST(
		100.0 * SUM(CAST(p.sales AS BIGINT))
		/
		SUM(SUM(CAST(p.sales AS BIGINT))) OVER(PARTITION BY Channel)
	AS DECIMAL(6,2)) AS Contribution
FROM fact_sales p
	LEFT JOIN dim_customer c ON p.customer_id = c.customer_id
	LEFT JOIN dim_product pp ON p.product_id = pp.product_id
GROUP BY Channel, Product_class
ORDER BY Channel, Contribution DESC
-- In context to product classes too, channels have comparable contribution, with same contribution of product classes

-- --------------------------------------------------------------------------------------------------------------------

--Q7: Within sub-channels, which is most profitable or highest-volume, and does that vary by product class?
SELECT 
	Sub_channel,
	SUM(CAST(p.sales AS BIGINT)) AS Revenue,
	SUM(Quantity) AS Volume
FROM fact_sales p
	LEFT JOIN dim_customer c ON p.customer_id = c.customer_id
	LEFT JOIN dim_product pp ON p.product_id = pp.product_id
GROUP BY Sub_channel
ORDER BY Revenue, Volume
-- All four sub-channels scale together fairly proportionally, with Retail consistently leading and Private consistently trailing, on both scales.

-- on the basis of product mix:
SELECT
	Sub_channel,
	Product_class,
	CAST(
		100.0 * SUM(CAST(p.sales AS BIGINT))
		/
		SUM(SUM(CAST(p.sales AS BIGINT))) OVER(PARTITION BY Sub_channel)
	AS DECIMAL(6,2)) AS Contribution
FROM fact_sales p
	LEFT JOIN dim_customer c ON p.customer_id = c.customer_id
	LEFT JOIN dim_product pp ON p.product_id = pp.product_id
GROUP BY Sub_channel, Product_class
ORDER BY Sub_channel, Contribution DESC
-- In context to product classes too, sub_channels have comparable contribution, with same contribution of product classes

-- ------------------------------------------------------------------------------------------------------------------------

--Q8: Is channel/sub-channel performance stable over time, or is one channel growing while another declines — even if their totals look similar overall?

WITH YearlySales AS
(
    SELECT
        Year,
		Channel,
        SUM(CAST(p.sales AS BIGINT)) AS Revenue,
        SUM(Quantity) AS Volume
    FROM fact_sales p
    LEFT JOIN dim_date d ON p.date_id = d.date_id
	LEFT JOIN dim_customer c ON p.customer_id = c.customer_id
    GROUP BY Year, Channel
)

SELECT
    Year,
    Revenue,
    Volume,
	Channel,
    ROUND(
        100.0 *
        (Revenue - LAG(Revenue) OVER(PARTITION BY Channel ORDER BY Year))
        /
		LAG(Revenue) OVER(PARTITION BY Channel ORDER BY Year),
        2) AS RevenueYoYGrowth,
	ROUND(
        100.0 *
        (Volume - LAG(Volume) OVER(PARTITION BY Channel ORDER BY Year))
        /
		LAG(Volume) OVER(PARTITION BY Channel ORDER BY Year),
        2) AS VolumeYoYGrowth
FROM YearlySales
ORDER BY Channel, Year
-- From this we can interpret:
	-- Both the channels show similar growth pattern overall, at the same time, their revenues and overall volumes change at the same pace too.
	-- Both Hospitals and Pharmacies show Growth during the 1st analyzed year(2017-18), and saw decline during the next two years(2018-20).
	-- During Year 2019-20, both hospitals and pharmacies saw reduction in decline, but Pharmacy performed far better than hospitals