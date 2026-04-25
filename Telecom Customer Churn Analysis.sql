-- Telecom Customer Churn Analysis 

-- Section 1: Making sure the data is ready for analysis

-- Section 2: Exploratory Data Analysis EDA
-- 1. overall churn rate
-- 2. Churn by contract type
-- 3. Churn vs Monthly Charges
-- 4. Churn vs Tenure
-- 5. Churn by Internet Service
-- 6. Payment method effect

-- Section 3: Customer Risk Segmentation
-- 1. Create Risk Segmentation Table
-- 2. Validating segmentation
-- 3. Creating churn_risk_model table 

-- --------------------------------------------------------------

-- Section 1: Making sure the data is ready for analysis

SELECT * 
FROM customer_churn;


SELECT *
FROM customer_churn
LIMIT 10;


-- checking total count
SELECT COUNT(*)
FROM customer_churn;
-- total count is 7032


-- checking for duplicates
SELECT customerID, COUNT(*)
FROM customer_churn
GROUP BY customerID
HAVING COUNT(*) > 1;
-- no duplicates were found


-- checking for missing totalcharges values
SELECT *
FROM customer_churn
WHERE TotalCharges IS NULL
  OR TotalCharges = ' ';



SELECT *
FROM customer_churn
WHERE TotalCharges IS NULL;

  -- no missing values were found




-- Validating numeric ranges
SELECT 
	MIN(tenure),
    MAX(tenure),
    MIN(MonthlyCharges),
    MAX(MonthlyCharges),
    MIN(TotalCharges),
    MAX(TotalCharges)
FROM customer_churn;
-- no negative or unrealistic values




-- --------------------------------------------------------------

-- Section 2: Exploratory Data Analysis EDA

-- What is churn rate?
-- Who churns the most?
-- What patterns exist?


-- 1. overall churn rate

SELECT 
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM customer_churn;

-- churn rate percentage is 26.58%





-- 2. Churn by contract type

SELECT 
    Contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM customer_churn
GROUP BY Contract
ORDER BY churn_rate_percent DESC;

-- Month-to-month = highest churn





-- 3. Churn vs Monthly Charges

SELECT 
	Churn,
    ROUND(AVG(MonthlyCharges), 2) AS avg_MonthlyCharges
FROM customer_churn
GROUP BY Churn;

-- Expensive customers leave more





-- 4. Churn vs Tenure

SELECT 
	CASE
		WHEN tenure <= 12 THEN '0-1 years'
        WHEN tenure <= 24 THEN '1-2 years'
        WHEN tenure <= 48 THEN '2-4 years'
        ELSE '4+ years'
	END AS tenure_group,
    
    COUNT(*) AS total_customers,
   
   ROUND(100 * SUM(CASE WHEN Churn = 'yes' THEN 1 ELSE 0 END)
	/ COUNT(*), 2) AS churn_rate_percent
    
FROM customer_churn
GROUP BY tenure_group
ORDER BY churn_rate_percent DESC;

-- New customers churn the most





-- 5. Churn by Internet Service

SELECT 
    InternetService,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM customer_churn
GROUP BY InternetService
ORDER BY churn_rate_percent DESC;

-- Fiber optic users churn more





-- 6. Payment method effect

SELECT 
    PaymentMethod,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM customer_churn
GROUP BY PaymentMethod
ORDER BY churn_rate_percent DESC;

-- Electronic check users churn more

-- --------------------------------------------------------------

-- Section 3: Customer Risk Segmentation

-- We classify customers into:
-- High Risk
-- Medium Risk
-- Low Risk

-- Logic we will use (based on EDA insights)
-- From telecom behavior patterns, we assume:

-- High Risk customers:
-- Month-to-month contract
-- high monthly charges
-- low tenure

-- Medium Risk:
-- Mixed signals (one risk factor only)

-- Low Risk:
-- Long-term contracts OR loyal customers




-- Create Risk Segmentation Table

SELECT 
    customerID,
    tenure,
    MonthlyCharges,
    Contract,
    InternetService,
    Churn,

    CASE
        WHEN Contract = 'Month-to-month'
             AND MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customer_churn)
             AND tenure <= 12
        THEN 'High Risk'

        WHEN Contract = 'Month-to-month'
             OR tenure <= 12
             OR MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customer_churn)
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS churn_risk_segment

FROM customer_churn;





-- Validating segmentation

SELECT 
    churn_risk_segment,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS churn_rate_percent
FROM (
    SELECT 
        *,
        CASE
            WHEN Contract = 'Month-to-month'
                 AND MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customer_churn)
                 AND tenure <= 12
            THEN 'High Risk'

            WHEN Contract = 'Month-to-month'
                 OR tenure <= 12
                 OR MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customer_churn)
            THEN 'Medium Risk'

            ELSE 'Low Risk'
        END AS churn_risk_segment
    FROM customer_churn
) t
GROUP BY churn_risk_segment
ORDER BY churn_rate_percent DESC;

-- High Risk: 67.52% churned of total high risk customers
-- Medium Risk: 25.06% churned of total medium risk customers
-- Low Risk: 2.68% churned of total low risk customers
-- our rule-based churn model is working correctly



-- Creating churn_risk_model table 

CREATE TABLE churn_risk_model AS
SELECT 
    *,
    CASE
        WHEN Contract = 'Month-to-month'
             AND MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customer_churn)
             AND tenure <= 12
        THEN 'High Risk'

        WHEN Contract = 'Month-to-month'
             OR tenure <= 12
             OR MonthlyCharges > (SELECT AVG(MonthlyCharges) FROM customer_churn)
        THEN 'Medium Risk'

        ELSE 'Low Risk'
    END AS churn_risk_segment
FROM customer_churn;







