USE Starbucks_DB

SELECT * FROM Starbucks_Comprehensive_Data

-- Calculating the total revenue
SELECT SUM(UnitPrice * Quantity) AS Total_Revenue
FROM Starbucks_Comprehensive_Data

-- Calculating the AOV(Average Order Vlue)
SELECT SUM(TotalLineItemPrice)/COUNT(Distinct TransactionID) AS Average_Order_Value
FROM Starbucks_Comprehensive_Data

-- Calculating total number of item Sold
SELECT SUM(Quantity) AS Total_Item_Sold
FROM Starbucks_Comprehensive_Data

-- Calculating total number of Orders made
SELECT COUNT(DISTINCT TransactionID) AS Total_Orders_Count
FROM Starbucks_Comprehensive_Data

-- Average Items per Order (AIPO)
USE Starbucks_DB
SELECT SUM(Quantity)/COUNT(DISTINCT TransactionID)
FROM Starbucks_Comprehensive_Data

-- Daily trends for total orders
USE Starbucks_DB
GO

SELECT 
	CAST(TransactionDate AS DATE) AS Order_Date,
	COUNT(DISTINCT TransactionID) AS Total_Orders
FROM Starbucks_Comprehensive_Data

GROUP BY CAST(TransactionDate AS DATE)
ORDER BY Order_Date;

-- Percentage of Total Items Sold
SELECT
    ProductID,
    SUM(Quantity) AS Item_Quantity_Sold,
    SUM(SUM(Quantity)) OVER () AS Total_Quantity_Sold_All_Items,

    CAST(
        (SUM(Quantity) * 100.0) / SUM(SUM(Quantity)) OVER () AS DECIMAL(10, 2)
        ) AS Percentage_of_Total_Items_Sold
FROM
    Starbucks_Comprehensive_Data
GROUP BY
    ProductID
ORDER BY
    Percentage_of_Total_Items_Sold DESC;


-- Find the Busiest Hour Slot and its customer ratio

USE Starbucks_DB
GO

WITH HourlyCounts AS (
    SELECT
        DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) AS Hour_24h, -- *FIX: Use your correct time column*
        COUNT(DISTINCT TransactionID) AS Customer_Count
    FROM
        Starbucks_Comprehensive_Data
    GROUP BY
        DATEPART(HOUR, CAST(TransactionDate AS DATETIME))
)
SELECT TOP 1
    CASE
        WHEN Hour_24h = 0 THEN '12 AM'
        WHEN Hour_24h < 12 THEN FORMAT(Hour_24h, '00') + ' AM'
        WHEN Hour_24h = 12 THEN '12 PM'
        ELSE FORMAT(Hour_24h - 12, '00') + ' PM'
    END AS Busiest_Time_Slot,
    CAST(
        (Customer_Count * 100.0) / SUM(Customer_Count) OVER ()
        AS DECIMAL(5, 2)
    ) AS Percentage_of_Total_Visits
FROM
    HourlyCounts
ORDER BY
    Customer_Count DESC;

-- Mximum number od customers as per store region/location
USE Starbucks_DB;
GO

SELECT TOP 1 
    StoreRegion, 
    StoreLocation, 
    
    COUNT(DISTINCT TransactionID) AS Total_Customers
FROM 
    Starbucks_Comprehensive_Data
GROUP BY 
    StoreRegion, 
    StoreLocation

ORDER BY 
    Total_Customers DESC;

-- Percentage of Loyal/Regular customers
USE Starbucks_DB;
GO

SELECT
    LoyaltyStatus,
    COUNT(DISTINCT CustomerID) AS Customer_Count,
    CAST(
        (COUNT(DISTINCT CustomerID) * 100.0) / 
        SUM(COUNT(DISTINCT CustomerID)) OVER ()
        AS DECIMAL(5, 2)
    ) AS Percentage_of_Total_Customers
FROM
    Starbucks_Comprehensive_Data
GROUP BY
    LoyaltyStatus
ORDER BY
    Percentage_of_Total_Customers DESC;

-- Percentage of the Product mostly ordered by the customers
USE Starbucks_DB;
GO

SELECT
    ProductCategory,
    ProductSubCategory,
    COUNT(DISTINCT TransactionID) AS Orders_Count,
    CAST(
        (COUNT(DISTINCT TransactionID) * 100.0) / 
        SUM(COUNT(DISTINCT TransactionID)) OVER ()
        AS DECIMAL(5, 2)
    ) AS Percentage_of_Total_Orders
FROM
    Starbucks_Comprehensive_Data
GROUP BY
    ProductCategory, 
    ProductSubCategory
ORDER BY
    Percentage_of_Total_Orders DESC;


-- Percentage of Orders using Rewards
USE Starbucks_DB;
GO

WITH RewardSummary AS (
    SELECT
        COUNT(DISTINCT TransactionID) AS Total_Orders,
        
        COUNT(DISTINCT 
            CASE 
                WHEN [IsRewardRedeemed] = 1 OR [IsRewardRedeemed] = 'TRUE' 
                THEN TransactionID 
                ELSE NULL 
            END
        ) AS Rewarded_Orders
    FROM
        Starbucks_Comprehensive_Data
)
SELECT
    Total_Orders,
    Rewarded_Orders,
    CAST(
        (Rewarded_Orders * 100.0) / Total_Orders
        AS DECIMAL(5, 2)
    ) AS Percentage_Orders_with_Reward
FROM
    RewardSummary;


-- Final SELECT to calculate percentages for Order Type and Payment Method separately

USE Starbucks_DB;
GO

WITH TotalOrders AS (
    SELECT
        COUNT(DISTINCT TransactionID) AS Grand_Total_Orders
    FROM
        Starbucks_Comprehensive_Data)

SELECT
    'Order Type Analysis' AS Analysis_Type,
    OrderType AS Category,
    COUNT(DISTINCT T1.TransactionID) AS Order_Count,
    CAST(
        (COUNT(DISTINCT T1.TransactionID) * 100.0) / 
        (SELECT Grand_Total_Orders FROM TotalOrders) 
        AS DECIMAL(5, 2)
    ) AS Percentage_of_Total
FROM 
    Starbucks_Comprehensive_Data T1
GROUP BY
    OrderType

UNION ALL

SELECT
    'Payment Method Analysis' AS Analysis_Type,
    PaymentMethod AS Category,
    COUNT(DISTINCT T2.TransactionID) AS Order_Count,
    CAST(
        (COUNT(DISTINCT T2.TransactionID) * 100.0) / 
        (SELECT Grand_Total_Orders FROM TotalOrders) 
        AS DECIMAL(5, 2)
    ) AS Percentage_of_Total
FROM 
    Starbucks_Comprehensive_Data T2
GROUP BY
    PaymentMethod
ORDER BY
    Analysis_Type, Percentage_of_Total DESC;


USE Starbucks_DB;
GO

SELECT
    -- 1. Day of Week: Converts the date part into a readable day name (e.g., 'Monday')
    DATENAME(WEEKDAY, TransactionDate) AS Day_of_Week,

    -- 2. Day Part: Categorizes the hour into defined time slots
    CASE
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 5 AND 10 THEN '1_Morning (05:00-10:59)'   -- Breakfast/Morning Rush
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 11 AND 13 THEN '2_Lunch (11:00-13:59)'     -- Lunch Peak
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 14 AND 17 THEN '3_Afternoon (14:00-17:59)' -- Afternoon Break/Snacks
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 18 AND 21 THEN '4_Evening (18:00-21:59)'   -- Dinner/Late Evening
        ELSE '5_Late Night/Other' -- All other hours
    END AS Day_Part,
    
    -- 3. Count: Number of unique orders for that day/time combination
    COUNT(DISTINCT TransactionID) AS Orders_Count
FROM
    Starbucks_Comprehensive_Data
GROUP BY
    DATENAME(WEEKDAY, TransactionDate),
    -- Group by the CASE statement result (the Day Part)
    CASE
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 5 AND 10 THEN '1_Morning (05:00-10:59)'
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 11 AND 13 THEN '2_Lunch (11:00-13:59)'
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 14 AND 17 THEN '3_Afternoon (14:00-17:59)'
        WHEN DATEPART(HOUR, CAST(TransactionDate AS DATETIME)) BETWEEN 18 AND 21 THEN '4_Evening (18:00-21:59)'
        ELSE '5_Late Night/Other'
    END
ORDER BY
    Orders_Count DESC;


