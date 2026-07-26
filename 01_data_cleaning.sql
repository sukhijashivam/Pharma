USE [pharma-analysis]

-- taking a look at the data for better understanding, for the furthur cleaning process.
SELECT top 20  *
FROM [pharma-data]



-- REMOVING FLOATING ERRORS FROM QUANTITIES

-- some of the quantities had non integer values(except the ones with values in quarters(0.25,0.5,0.75) which are valid), We observe them first
SELECT *
FROM [pharma-data]
WHERE quantity <> FLOOR(quantity) AND Sales is null

-- there are only 33 such rows, we will consider them as errors and delete these:
DELETE FROM [pharma-data]
WHERE quantity <> FLOOR(quantity) AND Sales is null



-- REMOVING NULLS FROM SALES

-- during importing, I found nulls in sales data, lets have a look at how many such are there.
SELECT count(*)
FROM [pharma-data] as p
WHERE p.sales is null

-- there 2633 null rows, I analyze them to understand if there is any pattern
SELECT channel, sub_channel, count(*)
FROM [pharma-data] as p
WHERE p.sales is null
GROUP BY channel, sub_channel

-- there is no such pattern, what else i can see is quantity and price, lets see if any of these are nulls
SELECT count(*)
FROM [pharma-data] as p
WHERE quantity is null OR price is null

-- there are no rows where quantity or price is null, so we observe these
SELECT quantity, price, sales
FROM [pharma-data]
WHERE sales is null

-- all of these rows have quantity as negative value, signifying returns, which are very important, and we should not remove these
-- instead, we will derive their values from quantity and price, getting negatives, to signal returns
-- I have updated the table directly, instead of using a backup, because I have the raw datafile available in case of error.
UPDATE [pharma-data]
SET Sales = Quantity * Price
WHERE Sales IS NULL



-- REMOVE DUPLICATES

SELECT Distributor, Customer_Name, City, Country, Latitude, Longitude, Channel, Sub_channel, Product_Name, Product_Class, Quantity, Price, Sales, Month, Year, Name_of_Sales_Rep ,Manager ,Sales_Team, COUNT(*)
FROM [pharma-data]
GROUP BY  Distributor, Customer_Name, City, Country, Latitude, Longitude, Channel, Sub_channel, Product_Name, Product_Class, Quantity, Price, Sales, Month, Year, Name_of_Sales_Rep ,Manager ,Sales_Team
HAVING COUNT(*) > 1

-- there are 4 duplicates, we remove them, by making a new table, and just adding distinct rows into that.
SELECT DISTINCT *
INTO pharma_data_new
FROM [pharma-data];

-- checking if the method worked. New table has 4 less rows than the old one.
SELECT COUNT(*) FROM [pharma-data];
SELECT COUNT(*) FROM pharma_data_new;

-- deleting the old table and renaming the new one
DROP TABLE [pharma-data];
EXEC sp_rename 'pharma_data_new', 'pharma-data';



-- CHECKING FOR DIFFERENT CONSISTENCIES

-- looking if there is any kind of inconsistency in major columns - text seems to be consistent
SELECT DISTINCT Channel FROM [pharma-data]
SELECT DISTINCT Sub_channel FROM [pharma-data]
SELECT DISTINCT Country FROM [pharma-data]

--  checking quantitative outliers, if any - seems okay.
SELECT MAX(price), MIN(price), AVG(Price) FROM [pharma-data]
SELECT MAX(Quantity), MIN(Quantity), AVG(Quantity) FROM [pharma-data]

-- month/year consistency - seems okay.
SELECT DISTINCT Month FROM [pharma-data]
SELECT DISTINCT Year FROM [pharma-data]
