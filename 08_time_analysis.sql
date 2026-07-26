USE [pharma-analysis]

--Q13: Is  the 2019-2020 decline complany wide or is it isolated to specific segments.
SELECT Year,
	Country,
	SUM(CAST(p.sales AS BIGINT)) AS TotalSales
FROM fact_sales p
	LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
	LEFT JOIN dim_date d ON p.date_id = d.date_id
Group by Year, Country
ORDER BY Country, Year
/* This is a new revelation, For country poland, the records are available for only the year of 2018, while for Germany we have records for 2017-20.
	This would explain the superiority of Germany in many other analysis too.
*/
 -- Since this new revelation, we rephrase the question 13:
 --Q13: What does Germany's year-over-year revenue and volume trend look like across 2017-2020, and what does the shape of that trend suggest about the business's trajectory?
WITH SalesData AS (
	SELECT Year,
		Country,
		SUM(CAST(p.sales AS BIGINT)) AS TotalSales,
		SUM(Quantity) AS Volume
	FROM fact_sales p
		LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
		LEFT JOIN dim_date d ON p.date_id = d.date_id
	WHERE Country = 'Germany'
	Group by Year, Country
)

SELECT Year,
	TotalSales,
	Volume,
	CAST(
		100.0 *
		(TotalSales - LAG(TotalSales) OVER(ORDER BY Year))
		/
		LAG(TotalSales) OVER(ORDER BY Year)
	AS DECIMAL(6,2)) AS YoYASalesGrowth,
	CAST(
		100.0 *
		(Volume - LAG(Volume) OVER(ORDER BY Year))
		/
		LAG(Volume) OVER(ORDER BY Year)
	AS DECIMAL(6,2)) AS YoYVolumeGrowth
FROM SalesData
/* From this data we can see the overall business was growing between 2017-19 in Germany, in context to both Volume and Sales.
	But saw a sudden decline by 9% in 2019-20. Even though the growth rate has been falling throughout the years, but sudden decline in 2019-20 is concerning
*/

--Q14: Is there seasonality — do certain months consistently perform better or worse, regardless of year?

SELECT
    MONTH(d.year_month) AS MonthNumber,
    DATENAME(MONTH, d.year_month) AS MonthName,
    SUM(CAST(p.sales AS BIGINT)) AS TotalSales,
    SUM(p.Quantity) AS TotalVolume,
    COUNT(DISTINCT d.Year) AS YearsIncluded,
    ROUND(SUM(CAST(p.sales AS BIGINT)) / NULLIF(COUNT(DISTINCT d.Year), 0), 2) AS AvgSalesPerYear
FROM fact_sales p
    LEFT JOIN dim_geography gp ON p.geo_id = gp.geo_id
    LEFT JOIN dim_date d ON p.date_id = d.date_id
WHERE gp.country = 'Germany'
GROUP BY MONTH(d.year_month), DATENAME(MONTH, d.year_month)
ORDER BY MonthNumber
/* From this query we can interpret:
- January is a clear seasonal low, with Sales at 632M — noticeably lower than every other month, the next-lowest (April) still being ~20% higher.
- August is the peak month at 1,119M, followed by March and November, though these three don't form an obvious pattern (not a simple quarter-end/holiday cluster).
- Given the January dip, this could be worth flagging as a planning input — e.g. sales/inventory planning could account for an expected post-holiday slowdown rather than treating a slow January as a red flag each year.
*/
