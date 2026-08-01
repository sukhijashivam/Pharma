USE [pharma-analysis]
	
--Q1: Which product classes drive the most revenue vs volumne
SELECT product_class, 
	SUM(CAST(p.sales AS BIGINT)) AS TotalSales,
	SUM(p.quantity) AS Volume,
	ROUND(SUM(CAST(p.sales AS BIGINT))/ SUM(p.quantity),2) AS SalesPerUnit
FROM fact_sales p LEFT JOIN dim_product dp
	ON p.product_id = dp.product_id
GROUP BY product_Class
ORDER BY TotalSales DESC
/* From this query, we can interpret:
	- Antipiretics constitute for a small portion of overall sales, but is a premium product as each unit sold is worth more than others.
	- Analgesics constitute for the most revenue and Volume, followed by Antiseptics & Mood Stabilizers.
	- This analysis shows that Antipiretics have a great potential and can be focused on, since these have less sales, but more worth/sale.*/

-- ----------------------------------------------------------------------------------------------------------------------------------------------
	
--Q2 Which individual producs are top performers vs. underperformers within their class?
WITH RankedProducts AS (
	SELECT Product_class, Product_name,
		RANK() OVER(
			PARTITION BY Product_class 
			ORDER BY SUM(CAST(p.sales AS BIGINT)) DESC
		) AS BestRank,

		RANK() OVER(
			PARTITION BY Product_class 
			ORDER BY SUM(CAST(p.sales AS BIGINT))
		) AS WorstRank,

		SUM(CAST(p.sales AS BIGINT)) AS TotalSales,

		SUM(p.quantity) AS Volume,

		ROUND(
			SUM(CAST(p.sales AS BIGINT))/ SUM(p.quantity),2
		) AS SalesPerUnit
	FROM fact_sales p LEFT JOIN dim_product dp
		ON p.product_id = dp.product_id
		GROUP BY Product_class, Product_name
	)

	SELECT *
	FROM RankedProducts rp
	WHERE BestRank = 1 OR WorstRank = 1
	ORDER BY Product_class, TotalSales DESC
/* From this query, we have recieved the best and worst performing products, in revenue, in each product class:
	- Iionclotide (Analgesics) is the best performing product overall, while Amphesirox (Antiseptics) is the worst one
	- From this analysis, we can focus on less performing products better on class level. This will help keep in context that 
		different product classes perform differently, and hence product comparison should be done accordingly.

	







