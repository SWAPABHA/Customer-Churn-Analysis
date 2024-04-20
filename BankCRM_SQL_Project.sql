CREATE DATABASE BankCRM;
use bankcrm;

select count(*) from customerinfo;

--- 1.	What is the distribution of account balances across different regions?
SELECT 
    g.GeographyLocation,
    COUNT(*) AS NumCustomers,
    MIN(b.Balance) AS MinBalance,
    MAX(b.Balance) AS MaxBalance,
    AVG(b.Balance) AS AvgBalance
FROM 
    Bank_Churn b
JOIN 
    CustomerInfo c ON b.CustomerId = c.CustomerId
JOIN 
    Geography g ON c.GeographyID = g.GeographyID
GROUP BY 
    g.GeographyLocation;

--- 2.	Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year. (SQL)
SELECT 
    CustomerId,
    EstimatedSalary
FROM 
    CustomerInfo
WHERE 
    YEAR(STR_TO_DATE(BankDOJ, '%d-%m-%Y')) = 2019 AND
    MONTH(STR_TO_DATE(BankDOJ, '%d-%m-%Y')) >= 10 AND MONTH(STR_TO_DATE(BankDOJ, '%d-%m-%Y')) <= 12
ORDER BY 
    EstimatedSalary DESC
LIMIT 5;

--- 3.	Calculate the average number of products used by customers who have a credit card. (SQL)
SELECT AVG(NumOfProducts) AS AvgNumOfProducts
FROM Bank_Churn
WHERE CreditID = 1;

--- 4.	Determine the churn rate by gender for the most recent year in the dataset.
SELECT
    g.GenderCategory,
    SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS ChurnedCustomers,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) AS ChurnRate
FROM
    Bank_Churn bc
JOIN
    CustomerInfo ci ON bc.CustomerId = ci.CustomerId
JOIN
    Gender g ON ci.GenderID = g.GenderID
JOIN
    ExitCustomer ec ON bc.ExitID = ec.ExitID
WHERE
    YEAR(STR_TO_DATE(ci.BankDOJ, '%d-%m-%Y')) = (SELECT MAX(YEAR(STR_TO_DATE(BankDOJ, '%d-%m-%Y'))) FROM CustomerInfo)
GROUP BY
    g.GenderCategory;

--- 5.	Compare the average credit score of customers who have exited and those who remain. (SQL)
SELECT
    ec.ExitCategory,
    AVG(bc.CreditScore) AS AvgCreditScore
FROM
    Bank_Churn bc
JOIN
    ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY
    ec.ExitCategory;
    
--- 6.	Which gender has a higher average estimated salary, and how does it relate to the number of active accounts? (SQL)
SELECT
    g.GenderCategory,
    AVG(ci.EstimatedSalary) AS AvgSalary,
    COUNT(CASE WHEN bc.ActiveID = 1 THEN 1 END) AS NumActiveAccounts
FROM
    CustomerInfo ci
JOIN
    Gender g ON ci.GenderID = g.GenderID
JOIN
    Bank_Churn bc ON ci.CustomerId = bc.CustomerId
GROUP BY
    g.GenderCategory;

--- 7.	Segment the customers based on their credit score and identify the segment with the highest exit rate. (SQL)
SELECT
    Segment,
    SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS ExitedCustomers,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) AS ExitRate
FROM
    (SELECT
        CASE 
            WHEN CreditScore >= 700 THEN 'High'
            WHEN CreditScore >= 600 THEN 'Medium'
            ELSE 'Low'
        END AS Segment,
        CustomerId,
        ExitID
    FROM
        Bank_Churn) AS SegmentedData
JOIN
    ExitCustomer ec ON SegmentedData.ExitID = ec.ExitID
GROUP BY
    Segment
ORDER BY
    ExitRate DESC
LIMIT 1;

--- 8.	Find out which geographic region has the highest number of active customers with a tenure greater than 5 years. (SQL)
SELECT
    g.GeographyLocation,
    COUNT(*) AS NumActiveCustomers
FROM
    CustomerInfo ci
JOIN
    Geography g ON ci.GeographyID = g.GeographyID
JOIN
    Bank_Churn bc ON ci.CustomerId = bc.CustomerId
WHERE
    bc.ActiveID = 1
    AND bc.Tenure > 5
GROUP BY
    g.GeographyLocation
ORDER BY
    NumActiveCustomers DESC
LIMIT 1;

--- 9.	What is the impact of having a credit card on customer churn, based on the available data?
SELECT
    cc.Category AS CreditCardCategory,
    SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) AS ChurnedCustomers,
    COUNT(*) AS TotalCustomers,
    SUM(CASE WHEN ec.ExitCategory = 'Exit' THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT) AS ChurnRate
FROM
    Bank_Churn bc
JOIN
    CreditCard cc ON bc.CreditID = cc.CreditID
JOIN
    ExitCustomer ec ON bc.ExitID = ec.ExitID
GROUP BY
    cc.Category;

--- 10.	For customers who have exited, what is the most common number of products they have used?
SELECT
    NumOfProducts,
    COUNT(*) AS NumCustomers
FROM
    Bank_Churn
WHERE
    ExitID = 1
GROUP BY
    NumOfProducts
ORDER BY
    NumCustomers DESC
LIMIT 1;

--- 11.	Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly). Prepare the data through SQL and then visualize it.
SELECT
    YEAR(STR_TO_DATE(BankDOJ, '%d-%m-%Y')) AS JoinYear,
    month(str_to_date(BankDOJ,'%d-%m-%Y')) as JoinMonth,
    COUNT(*) AS NumCustomers
FROM
    CustomerInfo
GROUP BY
    YEAR(STR_TO_DATE(BankDOJ, '%d-%m-%Y')),
    month(str_to_date(BankDOJ,'%d-%m-%Y'))
ORDER BY
    JoinYear,JoinMonth;

--- 12.	Analyze the relationship between the number of products and the account balance for customers who have exited.
SELECT
    NumOfProducts,
    Balance
FROM
    Bank_Churn
WHERE
    ExitID = 1;

--- 13.	Identify any potential outliers in terms of balance among customers who have remained with the bank.
SELECT
    CustomerId,
    Balance
FROM
    Bank_Churn
WHERE
    ExitID = 0;

SELECT
    @total_count := COUNT(*) AS total_count,
    @percentile := 0.25 AS percentile,
    (SELECT Balance
     FROM (SELECT Balance, @rownum := @rownum + 1 AS rownum
           FROM Bank_Churn
           JOIN (SELECT @rownum := 0) r
           WHERE ExitID = 0
           ORDER BY Balance) AS ranked
     WHERE rownum = CEILING(@percentile * @total_count)) AS Q1,
    @percentile := 0.75 AS percentile,
    (SELECT Balance
     FROM (SELECT Balance, @rownum := @rownum + 1 AS rownum
           FROM Bank_Churn
           JOIN (SELECT @rownum := 0) r
           WHERE ExitID = 0
           ORDER BY Balance) AS ranked
     WHERE rownum = CEILING(@percentile * @total_count)) AS Q3;

--- 15.	Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. Also, rank the gender according to the average value. (SQL)
SELECT ci.GeographyID, ge.GeographyLocation, gd.GenderCategory,
       AVG(ci.EstimatedSalary) AS AverageIncome,
       RANK() OVER(PARTITION BY ci.GeographyID, gd.GenderCategory 
ORDER BY AVG(ci.EstimatedSalary) DESC) AS GenderRank
FROM customerinfo ci
JOIN geography ge ON ci.GeographyID = ge.GeographyID
JOIN gender gd ON ci.GenderID = gd.GenderID
GROUP BY ci.GeographyID, ge.GeographyLocation, gd.GenderCategory;

--- 16. Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+)

select CASE 
		WHEN ci.Age BETWEEN 18 AND 30 THEN '18-30'
        WHEN ci.Age BETWEEN 31 AND 50 THEN '31-50'
        ELSE '50+'
    END AS Age_Bracket,
    AVG(bc.Tenure) AS Avg_Tenure
FROM bank_churn bc
JOIN customerinfo ci ON bc.CustomerId = ci.CustomerId
WHERE bc.ExitID = 1
GROUP BY Age_Bracket;

--- 19. Rank each bucket of credit score as per the number of customers who have churned the bank.
SELECT CreditScore,
    COUNT(*) AS Churned_Customers,
    RANK() OVER (ORDER BY COUNT(*) DESC) AS Score_Rank
FROM bank_churn
WHERE ExitID = 1
GROUP BY CreditScore;

--- 22. As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is 
--- also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.*/
SELECT CONCAT(ci.CustomerId, '_', ci.Surname) AS CustomerID_Surname
FROM customerinfo ci;

--- 23. Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.          
SELECT b.*,
    (SELECT ExitCategory 
     FROM exitcustomer ec 
     WHERE ec.ExitID = b.ExitID) AS ExitCategory
FROM bank_churn b;

--- 25. Write the query to get the customer IDs, their last name, and whether they are active or not for the customers whose surname ends with “on”.

select * from activecustomer; 

SELECT ci.CustomerId, ci.Surname AS lastname,
    CASE
        WHEN bc.ActiveID = 1 THEN 'Active'
        ELSE 'Inactive'
    END AS ActiveStatus
FROM customerinfo ci
JOIN bank_churn bc ON ci.CustomerId = bc.CustomerId
WHERE ci.Surname LIKE '%on';

--- Subjective
--- 9. Utilize SQL queries to segment customers based on demographics and account details.
SELECT
    CASE
        WHEN age BETWEEN 18 AND 30 THEN '18-30'
        WHEN age BETWEEN 31 AND 40 THEN '31-40'
        	   WHEN age BETWEEN 41 AND 50 THEN '41-50'
       	   ELSE '51+'
   	   END AS age_group, COUNT(*) AS num_customers
	FROM customerinfo
	GROUP BY age_group;
    
--- 14.	In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”? 
ALTER TABLE bank_churn
CHANGE COLUMN HasCrCard Has_creditcard INT;

