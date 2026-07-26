/* Here we will design our dimention tables, which will have their own surrogate keys. 
This opts star schema system over a flat table.
We will have following dimention tables:
1. dim_product
2. dim_geography
3. dim_customer
4. dim_sales_rep
5. dim_date
6. fact_sales */


-- Creating dim_product and adding distinct values from the pharma-data table, into it:
CREATE TABLE dim_product (
	product_id INT IDENTITY(1,1) PRIMARY KEY,
	Product_name NVARCHAR(50),
	Product_Class NVARCHAR(50)
);

INSERT INTO dim_product (Product_name, Product_Class)
SELECT DISTINCT Product_name, Product_Class
FROM [pharma-data]


-- Creating dim_geography and adding distinct values from the pharma-data table, into it:
CREATE TABLE dim_geography (
	geo_id INT IDENTITY(1,1) PRIMARY KEY,
	City NVARCHAR(50),
	Country NVARCHAR(50),
	Latitude FLOAT,
	Longitude FLOAT
);

INSERT INTO dim_geography (City, Country, Latitude, Longitude)
SELECT DISTINCT City, Country, Latitude, Longitude
FROM [pharma-data]


-- Creating dim_customer and adding distinct values from the pharma-data table, into it:
CREATE TABLE dim_customer (
	customer_id INT IDENTITY(1,1) PRIMARY KEY,
	Customer_Name NVARCHAR(100),
	Distributor NVARCHAR(50),
	Channel NVARCHAR(50),
	Sub_channel NVARCHAR(50)
);

INSERT INTO dim_customer (Customer_Name, Distributor, Channel, Sub_channel)
SELECT DISTINCT Customer_Name, Distributor, Channel, Sub_channel
FROM [pharma-data]


-- Creating dim_sales_rep and adding distinct values from the pharma-data table, into it:
CREATE TABLE dim_sales_rep (
	rep_id INT IDENTITY(1,1) PRIMARY KEY,
	Name_of_Sales_Rep NVARCHAR(50),
	Manager NVARCHAR(50),
	Sales_Team NVARCHAR(50)
);

INSERT INTO dim_sales_rep (Name_of_Sales_Rep, Manager, Sales_Team)
SELECT DISTINCT Name_of_Sales_Rep, Manager, Sales_Team
FROM [pharma-data]


-- Creating dim_date and adding distinct values from the pharma-data table, into it:
-- here we had dates in char, and int format, so we derrived a new year_month column with dates in appropriate format.
CREATE TABLE dim_date (
	date_id INT IDENTITY(1,1) PRIMARY KEY,
	Month NVARCHAR(50),
	Year SMALLINT,
	year_month DATE
);

INSERT INTO dim_date (Month, Year, year_month)
SELECT DISTINCT 
	Month, 
	Year, 
	CAST('01 ' + Month + ' ' + CAST(Year AS VARCHAR) AS DATE) 
FROM [pharma-data]


-- Finally creating a fact_sales table, which refers to all these dimention tables, to make a proper derrived sales table.
CREATE TABLE fact_sales (
    sale_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT FOREIGN KEY REFERENCES dim_product(product_id),
    geo_id INT FOREIGN KEY REFERENCES dim_geography(geo_id),
    customer_id INT FOREIGN KEY REFERENCES dim_customer(customer_id),
    rep_id INT FOREIGN KEY REFERENCES dim_sales_rep(rep_id),
    date_id INT FOREIGN KEY REFERENCES dim_date(date_id),
    Quantity FLOAT,
    Price INT,
    Sales INT
);

INSERT INTO fact_sales (product_id, geo_id, customer_id, rep_id, date_id, Quantity, Price, Sales)
SELECT
    dp.product_id,
    dg.geo_id,
    dc.customer_id,
    dr.rep_id,
    dd.date_id,
    p.Quantity,
    p.Price,
    p.Sales
FROM [pharma-data] p
JOIN dim_product dp
    ON p.Product_Name = dp.Product_Name
    AND p.Product_Class = dp.Product_Class
JOIN dim_geography dg
    ON p.City = dg.City
    AND p.Country = dg.Country
    AND p.Latitude = dg.Latitude
    AND p.Longitude = dg.Longitude
JOIN dim_customer dc
    ON p.Customer_Name = dc.Customer_Name
    AND p.Distributor = dc.Distributor
    AND p.Channel = dc.Channel
    AND p.Sub_channel = dc.Sub_channel
JOIN dim_sales_rep dr
    ON p.Name_of_Sales_Rep = dr.Name_of_Sales_Rep
    AND p.Manager = dr.Manager
    AND p.Sales_Team = dr.Sales_Team
JOIN dim_date dd
    ON dd.year_month = CAST('1 ' + p.Month + ' ' + CAST(p.Year AS VARCHAR) AS DATE);


-- sanity checking the new table, to make sure there are no errors.
SELECT COUNT(*) FROM [pharma-data];
SELECT COUNT(*) FROM fact_sales;

