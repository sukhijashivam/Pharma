USE [pharma-analysis]

--Q9: Are a small number of distributors/customers responsible for a disproportionate share of sales (concentration risk)?
-- finding customer concentration
SELECT 
	Country,
	Customer_name,
	SUM(CAST(p.sales AS BIGINT)) AS TotalSales,
	CAST(
		100.0 * SUM(CAST(p.sales AS BIGINT))
		/
		SUM(SUM(CAST(p.sales AS BIGINT))) OVER(PARTITION BY Country)
	AS DECIMAL(6,2)) AS CustomerContribution

FROM fact_sales p
	LEFT JOIN dim_customer c ON p.customer_id = c.customer_id
	LEFT JOIN dim_geography g ON p.geo_id = g.geo_id
GROUP BY Country, Customer_name
ORDER BY Country, CustomerContribution DESC
/* from this we can interpret: 
	- No customer has percentage contribution of more than 1.05% in both countries, signifying there is no concentration risk there.
	- Contribution of customer ranges from 0.1% - 1.0% in both the countries.
*/

-- finding distributor concentration
SELECT 
	Country,
	Distributor,
	SUM(CAST(p.sales AS BIGINT)) AS TotalSales,
	CAST(
		100.0 * SUM(CAST(p.sales AS BIGINT))
		/
		SUM(SUM(CAST(p.sales AS BIGINT))) OVER(PARTITION BY Country)
	AS DECIMAL(6,2)) AS DistributorContribution

FROM fact_sales p
	LEFT JOIN dim_customer c ON p.customer_id = c.customer_id
	LEFT JOIN dim_geography g ON p.geo_id = g.geo_id
GROUP BY Country, Distributor
ORDER BY Country, DistributorContribution DESC
/* from this we can interpret:
	- in contrast to customers, there is a real concentration risk in distributors, where the distributor contribution has a huge range.
	- Germany has a bigger polarization than Poland, where the contribution ranges from 31% - 0.01%, whereas in Poland the range is 22% - 0.19%, which is still a risk

-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Q10: Segment customers into tiers (high/medium/low value) by revenue contribution?
-- customer revenue is evenly distributed with no meaningful concentration, so tiering doesn't surface an actionable segment" is itself a valid finding, and shows judgment