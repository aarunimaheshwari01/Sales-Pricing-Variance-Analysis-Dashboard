/*Validations*/

USE SalesPricingVarianceDB;
GO

/*Overview*/
SELECT
SUM(Revenue) AS total_revenue,
SUM(Budget_Revenue) AS total_budget_revenue,
SUM(Revenue_Variance) AS total_variance
FROM rpt.vw_sales_kpi_base;
GO

/*Pricing Analysis*/
SELECT
AVG(Unit_Selling_Price) AS avg_actual_asp,
AVG(Budget_Unit_Price) AS avg_budget_asp,
SUM(Commission_Amount) AS total_commission
FROM rpt.vw_sales_kpi_base;
GO

/*Budget Variance*/
SELECT TOP 10 Product_Name, SUM(Revenue_Variance) AS total_variance
FROM rpt.vw_sales_kpi_base
GROUP BY Product_Name
ORDER BY total_variance ASC;
GO