DROP DATABASE IF EXISTS ecomm;
CREATE DATABASE ecomm;
USE ECOMM;

select * FROM CUSTOMER_CHURN;

select count(*) FROM CUSTOMER_CHURN;

SELECT CHURN,count(*) FROM CUSTOMER_CHURN group by CHURN;


-- Data Cleaning:
-- Handling Missing Values and Outliers:
-- Impute mean for the following columns, and round off to the nearest integer if required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,DaySinceLastOrder.

select round(AVG(WarehouseToHome)) AS AVG_WarehouseToHome FROM CUSTOMER_CHURN;

select round(AVG(HoursSpentOnApp)) AS AVG_HoursSpentOnApp FROM CUSTOMER_CHURN;

select round( AVG(OrderAmountHikeFromlastYear)) AS AVG_OrderAmountHikeFromlastYear FROM CUSTOMER_CHURN;

select round(AVG(DaySinceLastOrder)) AS AVG_DaySinceLastOrder FROM CUSTOMER_CHURN;

-- Impute mode for the following columns: Tenure, CouponUsed, OrderCount.

select * FROM CUSTOMER_CHURN where TENURE IS NULL;

SET@MODE_TENURE = (SELECT TENURE FROM CUSTOMER_CHURN where TENURE IS NOT NULL  group by  TENURE order by count(*) desc LIMIT 1 );
select @MODE_TENURE;


update CUSTOMER_CHURN
set Tenure = @MODE_TENURE
WHERE TENURE IS NULL;

--  CouponUsed
select * FROM CUSTOMER_CHURN WHERE CouponUsed IS NULL;

SET@MODE_COUPONUSED =(select COUPONUSED from CUSTOMER_CHURN where COUPONUSED IS NOT null group by COUPONUSED order by count(*) desc limit 1);
select@MODE_COUPONUSED;

UPDATE CUSTOMER_CHURN
SET CouponUsed = @MODE_COUPONUSED
WHERE CouponUsed IS NULL;

-- OrderCount
select * FROM CUSTOMER_CHURN where OrderCount IS NULL;

SET@MODE_ORDERCOUNT = (SELECT ORDERCOUNT FROM CUSTOMER_CHURN where ORDERCOUNT IS not null group by ORDERCOUNT order by count(*) desc limit 1);
select@MODE_ORDERCOUNT;

update CUSTOMER_CHURN
SET ORDERCOUNT = @MODE_ORDERCOUNT
where ORDERCOUNT IS NULL;

-- hoursspentonapp
SET@MODE_hoursspentonapp  = (SELECT hoursspentonapp   FROM CUSTOMER_CHURN where hoursspentonapp  IS NOT NULL  group by  hoursspentonapp  order by count(*) desc LIMIT 1 );
select @MODE_hoursspentonapp ;

update CUSTOMER_CHURN
set hoursspentonapp  = @MODE_hoursspentonapp 
WHERE hoursspentonapp  IS NULL;

select * FROM CUSTOMER_CHURN;

-- Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100.

select WarehouseToHome FROM CUSTOMER_CHURN where WarehouseToHome > 100;
delete FROM CUSTOMER_CHURN where WarehouseToHome > 100;

-- Dealing with Inconsistencies:
-- Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure uniformity.

select * from CUSTOMER_CHURN WHERE PreferedOrderCat = 'Mobile';
update customer_churn
set PreferedOrderCat  = if(PreferedOrderCat ='Mobile','Mobile Phone',PreferedOrderCat);

select * from customer_churn where PreferredLoginDevice = 'Phone';
update customer_churn
set PreferredLoginDevice =if(PreferedOrderCat='Phone','Mobile Phone',PreferredLoginDevice);

-- Standardize payment mode values: Replace "COD" with "Cash on Delivery" and "CC" with "Credit Card" in the PreferredPaymentMode column.

select * from CUSTOMER_CHURN where PreferredPaymentMode IN ('CC','COD');
update CUSTOMER_CHURN
SET PreferredPaymentMode = CASE
WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
when PreferredPaymentMode = 'COD' THEN 'Cash On Delivery'
else PreferredPaymentMode
end;


-- Data Transformation:
-- Column Renaming:
-- Rename the column "PreferedOrderCat" to "PreferredOrderCat".
-- Rename the column "HourSpendOnApp" to "HoursSpentOnApp".

alter table customer_churn
rename column PreferedOrderCat to PreferredOrderCat,
rename column HourSpendOnApp to HoursSpentOnApp;

select * FROM CUSTOMER_CHURN;

-- Creating New Columns:
-- Create a new column named ‘ComplaintReceived’ with values "Yes" if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.
-- Create a new column named 'ChurnStatus'. Set its value to “Churned” if the corresponding value in the 'Churn' column is 1, else assign “Active”.

alter table customer_churn
add column ComplaintReceived enum('Yes','No'),
add column ChurnStatus enum ('Churned','Active');

select * from customer_churn;
update customer_churn set Tenure=4 where tenure=5;

update customer_churn
set ComplaintReceived = if( Complain = 1,'Yes','No'),
ChurnStatus = if(Churn=1,'Churned','Active' );

-- Column Dropping:
-- Drop the columns "Churn" and "Complain" from the table.

alter table customer_churn
drop column Churn,
drop column Complain;

select * from customer_churn;


-- Data Exploration and Analysis:
-- Retrieve the count of churned and active customers from the dataset.

select count(*) as active_customer
from customer_churn 
where churnStatus = 'Active';

-- Display the average tenure of customers who churned.

select round(avg(tenure),2)as AVG_tenure from customer_churn where ChurnStatus = 'Churned';

-- Calculate the total cashback amount earned by customers who churned.

select churnstatus,concat(sum(CashbackAmount)) as total_cashback from customer_churn where ChurnStatus = 'Churned';

-- Determine the percentage of churned customers who complained.

select churnstatus as customer_churn, round(count(churnstatus) / (select count(churnstatus)from customer_churn )*100) as percentage_churn,complaintreceived 
from customer_churn
where churnstatus = 'churned' 
group by complaintreceived having complaintreceived = 'yes';

-- Find the gender distribution of customers who complained.

select gender ,count(complaintreceived) as complaint_received from customer_churn where complaintreceived = 'yes' group by gender;

-- Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.

select citytier , count(churnstatus) as churn_cus 
from customer_churn 
where PreferredOrderCat = 'Laptop & Accessory' 
group by citytier 
order by churn_cus desc limit 1;

-- Identify the most preferred payment mode among active customers.

select PreferredPaymentMode as most_preferred_payment, count(PreferredPaymentMode) as payment_mode_count
from customer_churn
 where churnstatus='active' 
 group by most_preferred_payment
 order by payment_mode_count desc limit 1;


-- List the preferred login device(s) among customers who took more than 10 days since their last order.

select PreferredLoginDevice, count(*) as devicecount 
from customer_churn where DaySinceLastOrder > 10 
group by PreferredLoginDevice 
order by devicecount desc limit 1;

-- List the number of active customers who spent more than 3 hours on the app.

select * from CUSTOMER_CHURN where hoursspentonapp is null;
 

select count(*)as active_customers_over_3_hours
from customer_churn 
where churnStatus = 'Active' and HoursSpentOnApp >3 ;

-- Find the average cashback amount received by customers who spent at least 2 hours on the app.

select round(count(CashbackAmount),2) as avg_cashback
from customer_churn
where HoursSpentOnApp > 2 ;

-- Display the maximum hours spent on the app by customers in each preferred order category.

select PreferredOrderCat as PreferredOrderCategory ,concat(max(HoursSpentOnApp),'hours') as max_HoursSpentOnApp from customer_churn 
group by PreferredOrderCat order by PreferredOrderCategory;


-- Find the average order amount hike from last year for customers in each marital status category.

select MaritalStatus,concat('$',round(avg(OrderAmountHikeFromlastYear),2))as avg_OrderAmountHikeFromlastYear 
from customer_churn
where MaritalStatus = 'single' 
group by MaritalStatus 
order by MaritalStatus desc;

-- Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.

select sum(OrderAmountHikeFromlastYear) as total_OrderAmountHikeFromlastYear 
from customer_churn 
where MaritalStatus = 'single' and PreferredOrderCat = 'mobile phone';


-- Find the average number of devices registered among customers who used UPI as their preferred payment mode.

select customerid,round(avg(NumberOfDeviceRegistered)) as avg_devices_PreferredPaymentMode
from customer_churn
 where PreferredPaymentMode = 'UPI'
 group by customerid
 order by avg_devices_PreferredPaymentMode desc limit 1;

-- Determine the city tier with the highest number of customers.

SELECT citytier,COUNT(*) AS number_of_customers
FROM customer_churn
GROUP BY citytier
ORDER BY number_of_customers DESC
LIMIT 1;

-- Find the marital status of customers with the highest number of addresses.

select MaritalStatus,max(NumberOfAddress) as high_NumberOfAddress
from customer_churn
group by MaritalStatus order by high_NumberOfAddress desc limit 1;

-- Identify the gender that utilized the highest number of coupons.

select gender,sum(CouponUsed) as high_number_CouponUsed
from customer_churn
group by gender
order by high_number_CouponUsed;

-- List the average satisfaction score in each of the preferred order categories.

select PreferredOrderCat as Preferred_Order_Category,round(avg(SatisfactionScore),2) as avg_SatisfactionScore 
from customer_churn
group by PreferredOrderCat
order by avg_SatisfactionScore;

-- Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score.

select PreferredPaymentMode,count(OrderCount) as total_OrderCount 
from customer_churn 
where PreferredPaymentMode = 'Credit Card' and SatisfactionScore = ( select max(SatisfactionScore) from customer_churn)
group by PreferredPaymentMode;

-- How many customers are there who spent only one hour on the app and days since their last order was more than 5?

select count(*) as no_of_customer from customer_churn
where HoursSpentOnApp = 1 and DaySinceLastOrder >5;

-- What is the average satisfaction score of customers who have complained?

select round(avg(SatisfactionScore),2) as avg_SatisfactionScore 
from customer_churn
where ComplaintReceived = 'Yes';

-- How many customers are there in each preferred order category?

select PreferredOrderCat as PreferredOrderCategory , count(*) as no_of_cus 
from customer_churn
group by PreferredOrderCat 
order by no_of_cus desc ;

-- What is the average cashback amount received by married customers?

select concat(round(avg(CashbackAmount),2)) as avg_CashbackAmount 
from customer_churn
where MaritalStatus = 'MARRIED' ;

-- What is the average number of devices registered by customers who are not using Mobile Phone as their preferred login device?

select round(AVG(NumberOfDeviceRegistered),2) AS AVG_NO_OF_DEVICES 
FROM CUSTOMER_CHURN 
where PreferredLoginDevice not in ('mobile phone');

-- List the preferred order category among customers who used more than 5 coupons.

select PreferredOrderCat , count(*) as category_count from customer_churn
where CouponUsed > 5 group by PreferredOrderCat order by category_count desc;

-- List the top 3 preferred order categories with the highest average cashback amount.

select PreferredOrderCat,concat('$',round(avg(CashbackAmount),2)) as high_CashbackAmount
from customer_churn 
group by PreferredOrderCat 
order by high_CashbackAmount
desc;

-- Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.

select PreferredPaymentMode ,count(*) as paymentcount from customer_churn
where tenure = 10 and OrderCount > 500 group by PreferredPaymentMode order by paymentcount desc;

-- Categorize customers based on their distance from each distance category

SELECT 
    CASE 
        WHEN WarehouseToHome < 5 THEN 'very close distance'
        WHEN WarehouseToHome <= 10 THEN 'Close_Distance'
        WHEN WarehouseToHome < 15 THEN 'moderate distance'
        ELSE 'far distance'
    END AS distancecategory,
    churnstatus,
    COUNT(*) AS cus_count
FROM 
    customer_churn
GROUP BY 
    distancecategory, churnstatus
ORDER BY 
    distancecategory, churnstatus;

-- List the customer’s order details who are married, live in City Tier-1, and their order counts are more than the average number of orders placed by all customers.

select * from customer_churn where CityTier =1 and ordercount >(select avg(OrderCount) from customer_churn ) and MaritalStatus = 'married';

-- a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data:

drop table if exists customers_return;
create table customers_return (returnid int,customerid int,
returndate date,
returnamount decimal (10,2));

INSERT INTO customers_return (returnid, customerid, returndate, returnamount)
VALUES
    (1001, 50022, '2023-01-01', 2130),
    (1002, 50316, '2023-01-23', 2000),
    (1003, 51099, '2023-02-14', 2290),
    (1004, 52321, '2023-03-08', 2510),
    (1005, 52928, '2023-03-20', 3000),
    (1006, 53749, '2023-04-17', 1740),
    (1007, 54206, '2023-04-21', 3250),
    (1008, 54838, '2023-04-30', 1990);
    

-- Display the return details along with the customer details of those who have churned and have made complaints.

select c.CustomerID,c.tenure,c.PreferredLoginDevice,c.CityTier,c.WarehouseToHome,c.PreferredPaymentMode,c.Gender,c.HoursSpentOnApp,c.NumberOfDeviceRegistered,
c.PreferredOrderCat,c.SatisfactionScore,c.MaritalStatus,c.NumberOfAddress,c.OrderAmountHikeFromlastYear,c.CouponUsed,c.OrderCount,c.DaySinceLastOrder,c.CashbackAmount,
c.ComplaintReceived,c.ChurnStatus  
from customer_churn as r 
inner join customers_return as c 
on c.customerid = r.customerid 
where churnstatus='churned' and complaintrecevied= 'yes';

SELECT 
    C.CustomerID,
    C.Tenure,
    C.PreferredLoginDevice,
    C.CityTier,
    C.WarehouseToHome,
    C.PreferredPaymentMode,
    C.Gender,
    C.HoursSpentOnApp,
    C.NumberOfDeviceRegistered,
    C.PreferredOrderCat,
    C.SatisfactionScore,
    C.MaritalStatus,
    C.NumberOfAddress,
    C.OrderAmountHikeFromlastYear,
    C.CouponUsed,
    C.OrderCount,
    C.DaySinceLastOrder,
    C.CashbackAmount,
    C.ComplaintReceived,
    C.ChurnStatus
FROM 
    customers_return AS c
INNER JOIN 
    customer_churn AS r 
ON 
    c.customerid = r.customerid
WHERE 
    c.ChurnStatus = 'churned' 
    AND c.ComplaintReceived = 'yes';
    
    select * from customer_churn;
