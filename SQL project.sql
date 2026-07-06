-- Tabelele cheie: Sales.SalesOrderHeader, Sales.SalesOrderDetail, Production.Product

-- 1.1 Verificare NULL-uri în coloane critice
SELECT 
    'SalesOrderHeader' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN OrderDate IS NULL THEN 1 ELSE 0 END) AS NullOrderDate,
    SUM(CASE WHEN TotalDue IS NULL THEN 1 ELSE 0 END) AS NullTotalDue,
    SUM(CASE WHEN SubTotal IS NULL THEN 1 ELSE 0 END) AS NullSubTotal
FROM Sales.SalesOrderHeader;

SELECT 
    'SalesOrderDetail' AS TableName,
    COUNT(*) AS TotalRows,
    SUM(CASE WHEN ProductID IS NULL THEN 1 ELSE 0 END) AS NullProductID,
    SUM(CASE WHEN OrderQty IS NULL THEN 1 ELSE 0 END) AS NullOrderQty,
    SUM(CASE WHEN UnitPrice IS NULL THEN 1 ELSE 0 END) AS NullUnitPrice,
    SUM(CASE WHEN LineTotal IS NULL THEN 1 ELSE 0 END) AS NullLineTotal
FROM Sales.SalesOrderDetail;

-- 1.2 Verificare interval de date
SELECT 
    MIN(OrderDate) AS FirstOrder,
    MAX(OrderDate) AS LastOrder,
    DATEDIFF(DAY, MIN(OrderDate), MAX(OrderDate)) AS TotalDays,
    COUNT(DISTINCT YEAR(OrderDate)) AS YearsOfData
FROM Sales.SalesOrderHeader;

-- 1.3 Verificare valori negative sau zero (anomalii)
SELECT 
    'Negative/Zero Values Check' AS CheckType,
    SUM(CASE WHEN UnitPrice <= 0 THEN 1 ELSE 0 END) AS NegativeOrZeroUnitPrice,
    SUM(CASE WHEN OrderQty <= 0 THEN 1 ELSE 0 END) AS NegativeOrZeroQty,
    SUM(CASE WHEN LineTotal < 0 THEN 1 ELSE 0 END) AS NegativeLineTotal
FROM Sales.SalesOrderDetail;

-- 1.4 Verificare integritate referențială (produse existente)
SELECT 
    COUNT(*) AS OrphanRecords
FROM Sales.SalesOrderDetail sod
LEFT JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

-- 1.5 Verificare categorii de produse
SELECT 
    pc.Name AS CategoryName,
    COUNT(DISTINCT p.ProductID) AS ProductCount,
    COUNT(DISTINCT ps.ProductSubcategoryID) AS SubcategoryCount
FROM Production.Product p
LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY ProductCount DESC;

-- 1.6 Verificare produse fără categorie
SELECT 
    COUNT(*) AS ProductsWithoutCategory
FROM Production.Product p
WHERE p.ProductSubcategoryID IS NULL;

-- Total Revenue (SubTotal = valoare fără taxe și shipping)
SELECT
    YEAR(OrderDate) AS An,
    'Total Revenue' AS Metric,
    SUM(SubTotal) AS TotalRevenue,
    SUM(TaxAmt) AS TotalTax,
    SUM(Freight) AS TotalFreight,
    SUM(TotalDue) AS TotalDueAmount
FROM Sales.SalesOrderHeader
GROUP BY
    YEAR(OrderDate)
ORDER BY
    An;

-- Total Profit (Revenue - Cost)
-- Profit = LineTotal - (StandardCost * OrderQty)
SELECT
    YEAR(soh.OrderDate) AS An,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(p.StandardCost * sod.OrderQty) AS TotalCost,
    SUM(sod.LineTotal) - SUM(p.StandardCost * sod.OrderQty) AS TotalProfit,
    ROUND(
        (SUM(sod.LineTotal) - SUM(p.StandardCost * sod.OrderQty)) /
        NULLIF(SUM(sod.LineTotal), 0) * 100,
        2
    ) AS ProfitMarginPercent
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
JOIN Production.Product p
    ON sod.ProductID = p.ProductID
GROUP BY
    YEAR(soh.OrderDate)
ORDER BY
    An;

-
-- 1.7 Average Discount per Item


SELECT
    YEAR(soh.OrderDate) AS An,
    AVG(sod.UnitPriceDiscount) AS AvgDiscountRate,
    AVG(sod.UnitPriceDiscount * sod.UnitPrice) AS AvgDiscountAmount,
    COUNT(CASE WHEN sod.UnitPriceDiscount > 0 THEN 1 END) AS ItemsWithDiscount,
    COUNT(*) AS TotalItems,
    ROUND(
        COUNT(CASE WHEN sod.UnitPriceDiscount > 0 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS PercentItemsDiscounted
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY
    YEAR(soh.OrderDate)
ORDER BY
    An;


SELECT
    YEAR(soh.OrderDate) AS An,
    SUM(sod.OrderQty) AS TotalQuantitySold,
    COUNT(DISTINCT sod.SalesOrderID) AS TotalOrders,
    COUNT(DISTINCT sod.ProductID) AS UniqueProductsSold,
    AVG(sod.OrderQty) AS AvgQuantityPerLine,
    ROUND(
        SUM(sod.OrderQty) * 1.0 / NULLIF(COUNT(DISTINCT sod.SalesOrderID), 0),
        2
    ) AS AvgItemsPerOrder
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY
    YEAR(soh.OrderDate)
ORDER BY
    An;


SELECT
    YEAR(soh.OrderDate) AS SalesYear,
    COUNT(DISTINCT sod.ProductID) AS UniqueProductsSold
FROM Sales.SalesOrderDetail sod
JOIN Sales.SalesOrderHeader soh
    ON sod.SalesOrderID = soh.SalesOrderID
WHERE YEAR(soh.OrderDate) IN (2012, 2013)
GROUP BY YEAR(soh.OrderDate)
ORDER BY SalesYear;

--1.8 Average Order Value

SELECT
    YEAR(OrderDate) AS SalesYear,
    ROUND(
        SUM(TotalDue) * 1.0 / COUNT(DISTINCT SalesOrderID),
        2
    ) AS AverageOrderValue
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) IN (2012, 2013)
GROUP BY YEAR(OrderDate)
ORDER BY SalesYear;

SELECT
    ROUND(
        SUM(TotalDue) * 1.0 / COUNT(DISTINCT SalesOrderID),
        2
    ) AS AverageOrderValue
FROM Sales.SalesOrderHeader;

-- 1.9 Quarterly Analysis


SELECT
    YEAR(soh.OrderDate) AS An,
    DATEPART(QUARTER, soh.OrderDate) AS Quarter,
    'Q' + CAST(DATEPART(QUARTER, soh.OrderDate) AS VARCHAR) AS QuarterName,
    COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) AS TotalProfit,
    ROUND(
        (SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) /
         NULLIF(SUM(sod.LineTotal), 0)) * 100,
        2
    ) AS ProfitMarginPercent
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
GROUP BY 
    YEAR(soh.OrderDate),
    DATEPART(QUARTER, soh.OrderDate)
ORDER BY 
    An,
    Quarter;

-- 1.10 Month-over-Month Comparison by Year


SELECT 
    YEAR(soh.OrderDate) AS Year,
    MONTH(soh.OrderDate) AS MonthNumber,
    DATENAME(MONTH, soh.OrderDate) AS MonthName,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) AS TotalProfit
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY YEAR(soh.OrderDate), MONTH(soh.OrderDate), DATENAME(MONTH, soh.OrderDate)
ORDER BY Year, MonthNumber;

-- 1.11 Yearly Revenue & Profit Trend

SELECT 
    YEAR(soh.OrderDate) AS Year,
    COUNT(DISTINCT soh.SalesOrderID) AS TotalOrders,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) AS TotalProfit,
    ROUND(
        (SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) / 
        NULLIF(SUM(sod.LineTotal), 0)) * 100, 2
    ) AS ProfitMarginPercent
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY YEAR(soh.OrderDate)
ORDER BY Year;

--1.12 Revenue & Profit by Product Category


SELECT 
    COALESCE(pc.Name, 'Uncategorized') AS CategoryName,
    COUNT(DISTINCT sod.SalesOrderID) AS TotalOrders,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) AS TotalProfit,
    ROUND(
        (SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) / 
        NULLIF(SUM(sod.LineTotal), 0)) * 100, 2
    ) AS ProfitMarginPercent,
    AVG(sod.UnitPrice) AS AvgSellingPrice,
    AVG(p.StandardCost) AS AvgCost,
    AVG(sod.UnitPrice - p.StandardCost) AS AvgMarginPerUnit
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
LEFT JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
GROUP BY pc.Name
ORDER BY TotalProfit DESC;

--1.13 Revenue & Profit by Subcategory


SELECT
    ps.Name AS SubcategoryName,
    SUM(sod.OrderQty) AS TotalQuantity,
    SUM(sod.LineTotal) AS TotalRevenue,
    SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) AS TotalProfit,
    ROUND(
        (SUM(sod.LineTotal - (p.StandardCost * sod.OrderQty)) /
         NULLIF(SUM(sod.LineTotal), 0)) * 100,
        2
    ) AS ProfitMarginPercent
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
JOIN Production.ProductSubcategory ps 
    ON p.ProductSubcategoryID = ps.ProductSubcategoryID
GROUP BY 
    ps.Name
ORDER BY 
    TotalProfit DESC;
