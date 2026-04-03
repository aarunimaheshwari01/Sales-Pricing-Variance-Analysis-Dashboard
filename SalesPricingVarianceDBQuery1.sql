CREATE DATABASE SalesPricingVarianceDB;
GO

USE SalesPricingVarianceDB;
GO

CREATE SCHEMA stg;
GO

CREATE SCHEMA rpt;
GO

CREATE TABLE stg.sales_raw (
    Order_ID                         NVARCHAR(50),
    Order_Date                       NVARCHAR(50),
    Year                             NVARCHAR(10),
    Month_Num                        NVARCHAR(10),
    Month                            NVARCHAR(20),
    Region                           NVARCHAR(50),
    Segment                          NVARCHAR(50),
    Channel                          NVARCHAR(50),
    Customer_ID                      NVARCHAR(50),
    Customer_Name                    NVARCHAR(200),
    Sales_Rep_ID                     NVARCHAR(50),
    Sales_Rep_Name                   NVARCHAR(100),
    Product_ID                       NVARCHAR(50),
    Product_Name                     NVARCHAR(200),
    Category                         NVARCHAR(100),
    List_Price                       NVARCHAR(50),
    Discount_Pct                     NVARCHAR(50),
    Unit_Selling_Price               NVARCHAR(50),
    Quantity                         NVARCHAR(50),
    Revenue                          NVARCHAR(50),
    Estimated_Cost                   NVARCHAR(50),
    Commission_Rate                  NVARCHAR(50),
    Commission_Amount                NVARCHAR(50),
    Gross_Profit_After_Commission    NVARCHAR(50),
    Budget_Units                     NVARCHAR(50),
    Budget_Unit_Price                NVARCHAR(50),
    Budget_Revenue                   NVARCHAR(50),
    Order_Status                     NVARCHAR(50)
);
GO

EXEC sp_rename 
    'stg.sales_pricing_variance_sample_data',
    'sales_raw';
GO

SELECT COUNT(*) AS row_count
FROM stg.sales_raw;
GO

SELECT TOP 10 *
FROM stg.sales_raw;
GO

/*Audit Checks to check if text can be converted into proper repoting types*/
SELECT
    SUM(CASE WHEN TRY_CONVERT(date, Order_Date) IS NULL THEN 1 ELSE 0 END) AS bad_order_date,
    SUM(CASE WHEN TRY_CONVERT(int, Year) IS NULL THEN 1 ELSE 0 END) AS bad_year,
    SUM(CASE WHEN TRY_CONVERT(int, Month_Num) IS NULL THEN 1 ELSE 0 END) AS bad_month_num,
    SUM(CASE WHEN TRY_CONVERT(decimal(18,2), List_Price) IS NULL THEN 1 ELSE 0 END) AS bad_list_price,
    SUM(CASE WHEN TRY_CONVERT(decimal(18,4), Discount_Pct) IS NULL THEN 1 ELSE 0 END) AS bad_discount_pct,
    SUM(CASE WHEN TRY_CONVERT(decimal(18,2), Revenue) IS NULL THEN 1 ELSE 0 END) AS bad_revenue
FROM stg.sales_raw;

/*Checking Text Cleanliness*/
SELECT TOP 20
    Region,
    Segment,
    Channel,
    Category,
    Order_Status
FROM stg.sales_raw;

/*Checking Distinct Values*/
SELECT DISTINCT Region FROM stg.sales_raw ORDER BY Region;
SELECT DISTINCT Segment FROM stg.sales_raw ORDER BY Segment;
SELECT DISTINCT Channel FROM stg.sales_raw ORDER BY Channel;
SELECT DISTINCT Order_Status FROM stg.sales_raw ORDER BY Order_Status;
GO

/*Clean View*/
CREATE OR ALTER VIEW rpt.vw_sales_clean AS
SELECT
    LTRIM(RTRIM(Order_ID)) AS Order_ID,
    TRY_CONVERT(date, Order_Date) AS Order_Date,
    TRY_CONVERT(int, Year) AS [Year],
    TRY_CONVERT(int, Month_Num) AS Month_Num,
    LEFT(LTRIM(RTRIM(Month)), 3) AS Month_Name,
    UPPER(LTRIM(RTRIM(Region))) AS Region,
    LTRIM(RTRIM(Segment)) AS Segment,
    LTRIM(RTRIM(Channel)) AS Channel,
    LTRIM(RTRIM(Customer_ID)) AS Customer_ID,
    LTRIM(RTRIM(Customer_Name)) AS Customer_Name,
    LTRIM(RTRIM(Sales_Rep_ID)) AS Sales_Rep_ID,
    LTRIM(RTRIM(Sales_Rep_Name)) AS Sales_Rep_Name,
    LTRIM(RTRIM(Product_ID)) AS Product_ID,
    LTRIM(RTRIM(Product_Name)) AS Product_Name,
    LTRIM(RTRIM(Category)) AS Category,
    TRY_CONVERT(decimal(18,2), List_Price) AS List_Price,
    TRY_CONVERT(decimal(18,4), Discount_Pct) AS Discount_Pct,
    TRY_CONVERT(decimal(18,2), Unit_Selling_Price) AS Unit_Selling_Price,
    TRY_CONVERT(int, Quantity) AS Quantity,
    TRY_CONVERT(decimal(18,2), Revenue) AS Revenue,
    TRY_CONVERT(decimal(18,2), Estimated_Cost) AS Estimated_Cost,
    TRY_CONVERT(decimal(18,4), Commission_Rate) AS Commission_Rate,
    TRY_CONVERT(decimal(18,2), Commission_Amount) AS Commission_Amount,
    TRY_CONVERT(decimal(18,2), Gross_Profit_After_Commission) AS Gross_Profit_After_Commission,
    TRY_CONVERT(int, Budget_Units) AS Budget_Units,
    TRY_CONVERT(decimal(18,2), Budget_Unit_Price) AS Budget_Unit_Price,
    TRY_CONVERT(decimal(18,2), Budget_Revenue) AS Budget_Revenue,
    LTRIM(RTRIM(Order_Status)) AS Order_Status
FROM stg.sales_raw;
GO

SELECT TOP 20 *
FROM rpt.vw_sales_clean;
GO

SELECT COUNT(*) AS row_count
FROM rpt.vw_sales_clean;
GO

SELECT *
FROM rpt.vw_sales_clean
WHERE Order_Date IS NULL
   OR Revenue IS NULL
   OR Quantity IS NULL;
GO

/*KPI View*/
CREATE OR ALTER VIEW rpt.vw_sales_kpi_base AS
SELECT
    Order_ID,
    Order_Date,
    [Year],
    Month_Num,
    Month_Name,
    Region,
    Segment,
    Channel,
    Customer_ID,
    Customer_Name,
    Sales_Rep_ID,
    Sales_Rep_Name,
    Product_ID,
    Product_Name,
    Category,
    Order_Status,
    Quantity,
    List_Price,
    Unit_Selling_Price,
    Revenue,
    Estimated_Cost,
    Commission_Rate,
    Commission_Amount,
    Gross_Profit_After_Commission,
    Budget_Units,
    Budget_Unit_Price,
    Budget_Revenue,
    Revenue - Budget_Revenue AS Revenue_Variance,
    CASE
        WHEN Budget_Revenue = 0 OR Budget_Revenue IS NULL THEN NULL
        ELSE (Revenue - Budget_Revenue) / Budget_Revenue
    END AS Revenue_Variance_Pct,
    Revenue / NULLIF(Quantity, 0) AS Actual_ASP,
    Budget_Revenue / NULLIF(Budget_Units, 0) AS Budget_ASP,
    Revenue - Estimated_Cost AS Gross_Margin_Before_Commission,
    CASE
        WHEN Revenue = 0 OR Revenue IS NULL THEN NULL
        ELSE (Revenue - Estimated_Cost) / Revenue
    END AS Gross_Margin_Pct_Before_Commission,
    CASE
        WHEN Revenue = 0 OR Revenue IS NULL THEN NULL
        ELSE Gross_Profit_After_Commission / Revenue
    END AS Gross_Profit_Pct_After_Commission
FROM rpt.vw_sales_clean;
GO

SELECT TOP 20 *
FROM rpt.vw_sales_kpi_base;
GO

SELECT
    SUM(Revenue) AS total_revenue,
    SUM(Budget_Revenue) AS total_budget_revenue,
    SUM(Revenue_Variance) AS total_variance
FROM rpt.vw_sales_kpi_base;
GO

/*Budget View*/
CREATE OR ALTER VIEW rpt.vw_budget_vs_actual AS
SELECT
    [Year],
    Month_Num,
    Month_Name,
    Region,
    Segment,
    Category,
    Product_ID,
    Product_Name,
    SUM(Quantity) AS Actual_Units,
    SUM(Budget_Units) AS Budget_Units,
    SUM(Revenue) AS Actual_Revenue,
    SUM(Budget_Revenue) AS Budget_Revenue,
    SUM(Revenue) - SUM(Budget_Revenue) AS Revenue_Variance,
    CASE
        WHEN SUM(Budget_Revenue) = 0 THEN NULL
        ELSE (SUM(Revenue) - SUM(Budget_Revenue)) / SUM(Budget_Revenue)
    END AS Revenue_Variance_Pct
FROM rpt.vw_sales_kpi_base
GROUP BY
    [Year], Month_Num, Month_Name,
    Region, Segment, Category,
    Product_ID, Product_Name;
GO

SELECT TOP 20 *
FROM rpt.vw_budget_vs_actual
ORDER BY [Year], Month_Num, Region, Segment;

SELECT
    [Year],
    Month_Num,
    SUM(Actual_Revenue) AS actual_revenue,
    SUM(Budget_Revenue) AS budget_revenue,
    SUM(Revenue_Variance) AS revenue_variance
FROM rpt.vw_budget_vs_actual
GROUP BY [Year], Month_Num
ORDER BY [Year], Month_Num;
GO

/*Pricing View*/
CREATE OR ALTER VIEW rpt.vw_pricing_metrics AS
SELECT
    [Year],
    Month_Num,
    Month_Name,
    Region,
    Segment,
    Channel,
    Category,
    Product_ID,
    Product_Name,
    COUNT(DISTINCT Order_ID) AS Order_Count,
    SUM(Quantity) AS Units_Sold,
    AVG(List_Price) AS Avg_List_Price,
    AVG(Unit_Selling_Price) AS Avg_Unit_Selling_Price,
    AVG(Discount_Pct) AS Avg_Discount_Pct,
    SUM(Revenue) AS Total_Revenue,
    SUM(Commission_Amount) AS Total_Commission,
    SUM(Revenue) / NULLIF(SUM(Quantity), 0) AS Realized_Price,
    1 - (
        SUM(Revenue) / NULLIF(SUM(Quantity), 0)
        / NULLIF(AVG(List_Price), 0)
    ) AS Price_Realization_Gap_Pct
FROM rpt.vw_sales_kpi_base
GROUP BY
    [Year], Month_Num, Month_Name,
    Region, Segment, Channel,
    Category, Product_ID, Product_Name;
GO

USE SalesPricingVarianceDB;
GO

CREATE OR ALTER VIEW rpt.vw_sales_kpi_base AS
SELECT
    Order_ID,
    Order_Date,
    [Year],
    Month_Num,
    Month_Name,
    Region,
    Segment,
    Channel,
    Customer_ID,
    Customer_Name,
    Sales_Rep_ID,
    Sales_Rep_Name,
    Product_ID,
    Product_Name,
    Category,
    Order_Status,
    Quantity,
    List_Price,
    Discount_Pct,
    Unit_Selling_Price,
    Revenue,
    Estimated_Cost,
    Commission_Rate,
    Commission_Amount,
    Gross_Profit_After_Commission,
    Budget_Units,
    Budget_Unit_Price,
    Budget_Revenue,
    Revenue - Budget_Revenue AS Revenue_Variance,
    CASE
        WHEN Budget_Revenue = 0 OR Budget_Revenue IS NULL THEN NULL
        ELSE (Revenue - Budget_Revenue) * 1.0 / Budget_Revenue
    END AS Revenue_Variance_Pct,
    Revenue * 1.0 / NULLIF(Quantity, 0) AS Actual_ASP,
    Budget_Revenue * 1.0 / NULLIF(Budget_Units, 0) AS Budget_ASP,
    Revenue - Estimated_Cost AS Gross_Margin_Before_Commission,
    CASE
        WHEN Revenue = 0 OR Revenue IS NULL THEN NULL
        ELSE (Revenue - Estimated_Cost) * 1.0 / Revenue
    END AS Gross_Margin_Pct_Before_Commission,
    CASE
        WHEN Revenue = 0 OR Revenue IS NULL THEN NULL
        ELSE Gross_Profit_After_Commission * 1.0 / Revenue
    END AS Gross_Profit_Pct_After_Commission
FROM rpt.vw_sales_clean;
GO

USE SalesPricingVarianceDB;
GO

CREATE OR ALTER VIEW rpt.vw_pricing_metrics AS
SELECT
    [Year],
    Month_Num,
    Month_Name,
    Region,
    Segment,
    Channel,
    Category,
    Product_ID,
    Product_Name,
    COUNT(DISTINCT Order_ID) AS Order_Count,
    SUM(Quantity) AS Units_Sold,
    AVG(List_Price) AS Avg_List_Price,
    AVG(Unit_Selling_Price) AS Avg_Unit_Selling_Price,
    AVG(Discount_Pct) AS Avg_Discount_Pct,
    SUM(Revenue) AS Total_Revenue,
    SUM(Commission_Amount) AS Total_Commission,
    SUM(Revenue) * 1.0 / NULLIF(SUM(Quantity), 0) AS Realized_Price,
    1 - (
        (SUM(Revenue) * 1.0 / NULLIF(SUM(Quantity), 0))
        / NULLIF(AVG(List_Price), 0)
    ) AS Price_Realization_Gap_Pct
FROM rpt.vw_sales_kpi_base
GROUP BY
    [Year],
    Month_Num,
    Month_Name,
    Region,
    Segment,
    Channel,
    Category,
    Product_ID,
    Product_Name;
GO

SELECT TOP 10 *
FROM rpt.vw_pricing_metrics;
GO

SELECT COUNT(*) AS rows_sales_clean
FROM rpt.vw_sales_clean;
GO

SELECT COUNT(*) AS rows_kpi_base
FROM rpt.vw_sales_kpi_base;
GO

SELECT COUNT(*) AS rows_pricing_metrics
FROM rpt.vw_pricing_metrics;
GO

SELECT Region, SUM(Revenue) AS total_revenue
FROM rpt.vw_sales_kpi_base
GROUP BY Region
ORDER BY total_revenue DESC;
GO

SELECT Segment, AVG(Avg_Discount_Pct) AS avg_discount
FROM rpt.vw_pricing_metrics
GROUP BY Segment
ORDER BY avg_discount DESC;
GO

SELECT TOP 10 Product_Name, SUM(Revenue_Variance) AS total_variance
FROM rpt.vw_sales_kpi_base
GROUP BY Product_Name
ORDER BY total_variance ASC;
GO

USE SalesPricingVarianceDB;
GO

CREATE OR ALTER VIEW rpt.vw_budget_vs_actual AS
SELECT
    [Year],
    Month_Num,
    Month_Name,
    Region,
    Segment,
    Category,
    Product_ID,
    Product_Name,
    SUM(Quantity) AS Actual_Units,
    SUM(Budget_Units) AS Budget_Units,
    SUM(Revenue) AS Actual_Revenue,
    SUM(Budget_Revenue) AS Budget_Revenue,
    SUM(Revenue) - SUM(Budget_Revenue) AS Revenue_Variance,
    CASE
        WHEN SUM(Budget_Revenue) = 0 THEN NULL
        ELSE (SUM(Revenue) - SUM(Budget_Revenue)) * 1.0 / SUM(Budget_Revenue)
    END AS Revenue_Variance_Pct
FROM rpt.vw_sales_kpi_base
GROUP BY
    [Year], Month_Num, Month_Name,
    Region, Segment, Category,
    Product_ID, Product_Name;
GO



USE SalesPricingVarianceDB;
GO

