USE [pharma-analysis]

--Q11: Which reps/teams are top performers, and is performance more tied to the rep or to the accounts/territory they happen to cover?

-- To check which teams perform best.
WITH SalesStats AS (
	SELECT 
		Sales_team,
		Name_of_sales_rep,
		SUM(CAST(p.sales AS BIGINT)) AS Sales
	FROM fact_sales p
		LEFT JOIN dim_sales_rep r ON p.rep_id = r.rep_id
	GROUP BY Sales_team, Name_of_sales_rep
)

-- Team level analysis
SELECT Sales_team,
	SUM(Sales) AS TeamSale,
	RANK() OVER(ORDER BY SUM(Sales) DESC) AS Ranking
FROM SalesStats
GROUP BY Sales_team

/* From these queries we can make following interpretations:
	- Delta is the highest-performing sales team, generating the highest overall sales, while Alfa records the lowest total sales among all teams.
	- The team rankings highlight relative performance, helping management identify top-performing teams for benchmarking and lower-performing teams 
		that may require additional support or strategic improvements.
*/

-- to check which reps perform best.
WITH SalesStats AS (
	SELECT 
		Sales_team,
		Name_of_sales_rep,
		SUM(CAST(p.sales AS BIGINT)) AS Sales
	FROM fact_sales p
		LEFT JOIN dim_sales_rep r ON p.rep_id = r.rep_id
	GROUP BY Sales_team, Name_of_sales_rep
)
SELECT Sales_team,
	Name_of_sales_rep,
	Sales,
	RANK() OVER(PARTITION BY Sales_team ORDER BY Sales DESC) AS TeamRanking,
	RANK() OVER(ORDER BY Sales DESC) AS OverallRanking
FROM SalesStats
ORDER BY Sales_team, TeamRanking

/* From these queries we can make following interpretations:
	- Jimmy Grey is the highest-performing sales representative across the organization (Overall Rank 1), while Team Ranking identifies the top 
		performer within each individual sales team.
	- Delta ranks as the best-performing team overall despite not having the top individual sales representative, indicating that its success comes 
		from consistent contributions across multiple team members rather than reliance on a single high performer.
*/
	
-- --------------------------------------------------------------------------------------------------------------------------------------------------

-- Q12: Do certain managers' teams consistently outperform others?

WITH ManagerStats AS (
    SELECT
        Manager,
        Name_of_sales_rep,
        SUM(CAST(p.sales AS BIGINT)) AS Sales
    FROM fact_sales p
    LEFT JOIN dim_sales_rep r ON p.rep_id = r.rep_id
    GROUP BY Manager, Name_of_sales_rep
),

ManagerLevel AS (
    SELECT
        Manager,
        SUM(Sales) AS TotalSales,
        COUNT(DISTINCT Name_of_sales_rep) AS RepCount,
        SUM(Sales) / COUNT(DISTINCT Name_of_sales_rep) AS AvgSalesPerRep
    FROM ManagerStats
    GROUP BY Manager
)

SELECT
    Manager,
    TotalSales,
    RepCount,
    AvgSalesPerRep,
    RANK() OVER (ORDER BY AvgSalesPerRep DESC) AS PerformanceRanking
FROM ManagerLevel
ORDER BY PerformanceRanking;

/* From this query we can interpret:
   - TotalSales alone would be misleading if managers have different rep counts (same issue as the team-level query earlier)
   - AvgSalesPerRep is the fair comparison metric — it isolates manager effectiveness from headcount
   - PerformanceRanking should be read alongside RepCount: a manager ranked #1 with very few reps
     is a different situation than one ranked #1 with a large team — worth checking both before
     concluding one manager's approach is genuinely "better"
*/
