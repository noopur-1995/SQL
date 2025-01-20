CREATE schema G_motors;
USE G_motors;

SELECT * from dim_date;
SELECT * from electric_vehicle_sales_by_makers;
SELECT * from electric_vehicle_sales_by_state;

ALTER table dim_date
Rename column ï»¿date to date; 

ALTER table electric_vehicle_sales_by_makers
Rename column ï»¿date to date; 

ALTER table electric_vehicle_sales_by_state
Rename column ï»¿date to date; 

#1.	List the top 3 and bottom 3 makers for the fiscal years 2023 and 2024 in terms of the number of 2-wheelers sold. 
SELECT maker,vehicle_category, fiscal_year,sum(electric_vehicles_sold) as total_sales 
from electric_vehicle_sales_by_makers JOIN dim_date ON dim_date.`date`= electric_vehicle_sales_by_makers.`date`
WHERE fiscal_year in(2023,2024) and vehicle_category='2-Wheelers'
GROUP BY vehicle_category, fiscal_year,maker
ORDER BY total_sales ASC limit 3;



SELECT maker, fiscal_year,sum(electric_vehicles_sold) as total_sales 
from electric_vehicle_sales_by_makers JOIN dim_date ON dim_date.`date`= electric_vehicle_sales_by_makers.`date`
WHERE fiscal_year in(2023,2024) and vehicle_category='2-Wheelers'
GROUP BY vehicle_category, fiscal_year,maker
ORDER BY total_sales DESC limit 3;


SET sql_safe_updates=0;



#2.	Find the overall penetration rate in India for 2023 and 2022

SELECT fiscal_year,(sum(electric_vehicles_sold)/sum(total_vehicles_sold))*100 as penetration_rate
from dim_date JOIN  electric_vehicle_sales_by_state ON 
dim_date.`date`= electric_vehicle_sales_by_state.`date`
WHERE fiscal_year in (2023,2022)
GROUP BY fiscal_year;

#3.	Identify the top 5 states with the highest penetration rate in 2-wheeler and 4-wheeler EV sales in FY 2024.
 
SELECT state,vehicle_category,(sum(electric_vehicles_sold)/sum(total_vehicles_sold))*100 
as penetration_rate 
FROM electric_vehicle_sales_by_state JOIN dim_date ON 
electric_vehicle_sales_by_state.`date`= dim_date.`date`
WHERE fiscal_year='2024'
GROUP BY state,vehicle_category
ORDER BY penetration_rate desc limit 5 ;

#4.	List the top 5 states having highest number of EVs sold in 2023
SELECT state,sum(electric_vehicles_sold) as total_EV_sold
from dim_date JOIN electric_vehicle_sales_by_state 
ON electric_vehicle_sales_by_state.`date`= dim_date.`date`
WHERE fiscal_year=2023
GROUP BY state
ORDER BY sum(electric_vehicles_sold)desc limit 5;

#5.	List the states with negative penetration (decline) in EV sales from 2022 to 2024? 
SELECT state,fiscal_year,`quarter`,(sum(electric_vehicles_sold)/sum(total_vehicles_sold))*100 as penetration_rate
from dim_date JOIN electric_vehicle_sales_by_state ON
electric_vehicle_sales_by_state.`date`= dim_date.`date`
GROUP BY state,fiscal_year,`quarter`
ORDER BY state,fiscal_year,`quarter`;

#use of common table expression CTE

WITH StateSales AS (
    -- Calculate the total sales for each state by year
    SELECT
        state,
        fiscal_year,
        SUM(total_vehicles_sold) AS total_sales
    FROM
         dim_date JOIN electric_vehicle_sales_by_state ON
electric_vehicle_sales_by_state.`date`= dim_date.`date`
    WHERE
        fiscal_year IN (2022, 2023, 2024)
    GROUP BY
        state, fiscal_year
),
StateSalesWithLead AS (
    -- Use LEAD() to get the sales data of the next year
    SELECT
        state,
        fiscal_year,
        total_sales,
        LEAD(total_sales) OVER (PARTITION BY state ORDER BY fiscal_year) AS next_year_sales
    FROM
        StateSales
)
-- Select the states with a decline in sales from 2022 to 2024
SELECT
    state,
    total_sales AS sales_2022,
    next_year_sales AS sales_2024,
    ((next_year_sales - total_sales) / total_sales) * 100 AS penetration_decline_percentage
FROM
    StateSalesWithLead
WHERE
    fiscal_year = 2022
    AND next_year_sales < total_sales  -- This ensures a decline in sales
ORDER BY
    penetration_decline_percentage DESC;


#6.	Which are the Top 5 EV makers in India?
SELECT maker, sum(electric_vehicles_sold) as EV_total_sale
from electric_vehicle_sales_by_makers
GROUP BY maker
ORDER BY EV_total_sale desc limit 5;

#7.	How many EV makers sell 4-wheelers in India?
SELECT maker from electric_vehicle_sales_by_makers
WHERE vehicle_category='4-Wheelers'
GROUP BY maker;

#8.	What is ratio of 2-wheeler makers to 4-wheeler makers?
SELECT 
    COUNT(CASE WHEN vehicle_category = '2-Wheelers' THEN 1 END) AS two_wheeler_count,
    COUNT(CASE WHEN vehicle_category = '4-Wheelers' THEN 1 END) AS four_wheeler_count,
    (COUNT(CASE WHEN vehicle_category = '2-Wheelers' THEN 1 END) / 
     COUNT(CASE WHEN vehicle_category = '4-Wheelers' THEN 1 END)) AS two_wheeler_to_four_wheeler_ratio
FROM 
    electric_vehicle_sales_by_makers;
    
#9.	What are the quarterly trends based on sales volume for the top 5 EV makers (4-wheelers) from 2022 to 2024?
 -- SELECT maker,fiscal_year,`quarter`,sum(electric_vehicles_sold) 
 -- FROM electric_vehicle_sales_by_makers JOIN dim_date
 -- ON electric_vehicle_sales_by_makers.`date`=dim_date.`date`
 -- WHERE vehicle_category='4-Wheelers' and fiscal_year BETWEEN 2022 and 2024
 -- GROUP BY maker,fiscal_year,`quarter`
 -- ORDER BY maker,fiscal_year,`quarter` DESC LIMIT 5;
 
 WITH TopEVMakers AS (
    SELECT 
        maker,
        SUM(electric_vehicles_sold) AS total_sales
    FROM 
        electric_vehicle_sales_by_makers JOIN dim_date ON  
electric_vehicle_sales_by_makers.`date`=dim_date.`date`
    WHERE 
        vehicle_category = '4-Wheelers' 
        AND fiscal_year BETWEEN 2022 AND 2024
    GROUP BY 
        maker
    ORDER BY 
        total_sales DESC
    LIMIT 5
),
QuarterlySales AS (
    SELECT
        maker,
        fiscal_year,
        `quarter`,
        SUM(electric_vehicles_sold) AS quarterly_sales
    FROM
        electric_vehicle_sales_by_makers JOIN dim_date ON  
electric_vehicle_sales_by_makers.`date`=dim_date.`date`
    WHERE
        maker IN (SELECT maker FROM TopEVMakers)
        AND vehicle_category = '4-Wheelers'
        AND fiscal_year BETWEEN 2022 AND 2024
    GROUP BY
        maker, fiscal_year, `quarter`
)
SELECT
    ts.maker,
    ts.fiscal_year,
    ts.`quarter`,
    ts.quarterly_sales
FROM
    QuarterlySales ts
ORDER BY
    ts.maker,
    ts.fiscal_year,
    ts.`quarter`;

 
#10. How do the EV sales and penetration rates in Maharashtra compare to Tamil Nadu for 2024? 

SELECT state,sum(electric_vehicles_sold),(sum(electric_vehicles_sold)/sum(total_vehicles_sold))*100 as penetration_rate
FROM electric_vehicle_sales_by_state JOIN dim_date ON 
electric_vehicle_sales_by_state.`date`= dim_date.`date`
WHERE state in('Maharashtra','Tamil Nadu') AND fiscal_year=2024
GROUP BY state;

#11. List down the compounded annual growth rate (CAGR) in 4-wheeler units for the top 5 makers from 2022 to 2024. 
# t1: subquery that shows the total units sold by each maker in 2022
# t3: subquery that shows the total units sold by each maker in 2024

#CAGR = [(Ending Value / Beginning Value) ** 1/n] -1


WITH Top5Makers AS(
SELECT maker,sum(electric_vehicles_sold) as total_EV_sale 
FROM electric_vehicle_sales_by_makers JOIN dim_date ON  
electric_vehicle_sales_by_makers.`date`=dim_date.`date`
WHERE vehicle_category="4-Wheelers" and fiscal_year between 2022 and 2024
GROUP BY maker
ORDER BY total_EV_sale DESC limit 5)

SELECT
    t1.maker,
    POWER(t3.total_EV_sale / t1.total_EV_sale, 1 / 2) - 1 AS CAGR
FROM
    (SELECT maker, SUM(electric_vehicles_sold) AS total_EV_sale
     FROM electric_vehicle_sales_by_makers JOIN dim_date ON  
     electric_vehicle_sales_by_makers.`date`=dim_date.`date`
     WHERE fiscal_year = 2022
     GROUP BY maker) t1
JOIN
    (SELECT maker, SUM(electric_vehicles_sold) AS total_EV_sale
     FROM electric_vehicle_sales_by_makers JOIN dim_date ON  
electric_vehicle_sales_by_makers.`date`=dim_date.`date`
     WHERE fiscal_year = 2024
     GROUP BY maker) t3 ON t1.maker = t3.maker
JOIN Top5Makers t5 ON t1.maker = t5.maker;


#12. List down the top 10 states that had the highest compounded annual growth rate (CAGR) from 2022 to 2024 in total vehicles sold.
 WITH StateSales AS (
    SELECT
        state,
        SUM(CASE WHEN fiscal_year = 2022 THEN total_vehicles_sold ELSE 0 END) AS sales_2022,
        SUM(CASE WHEN fiscal_year = 2024 THEN total_vehicles_sold ELSE 0 END) AS sales_2024
    FROM dim_date JOIN  electric_vehicle_sales_by_state ON 
    dim_date.`date`= electric_vehicle_sales_by_state.`date`
    WHERE fiscal_year IN (2022, 2024)
    GROUP BY state
)
SELECT
    state,
    POWER(sales_2024 / sales_2022, 1 / 2) - 1 AS CAGR
FROM StateSales
ORDER BY CAGR DESC LIMIT 10;

#13. What are the peak and low season months for EV sales based on the data from 2022 to 2024? 

ALTER TABLE dim_date
ADD COLUMN `month` INT;

UPDATE dim_date
SET month = MONTH(STR_TO_DATE(`date`, '%d-%b-%y'));


WITH MonthlySales AS (
    SELECT
        fiscal_year,
        `month`,
        SUM(electric_vehicles_sold) AS total_sales
    FROM dim_date JOIN  electric_vehicle_sales_by_makers ON dim_date.`date`= electric_vehicle_sales_by_makers.`date`
    WHERE fiscal_year BETWEEN 2022 AND 2024
    GROUP BY fiscal_year, `month`
)

SELECT
    fiscal_year,
	`month`,
    total_sales,
    CASE
        WHEN total_sales > AVG(total_sales) OVER () THEN 'Peak'
        WHEN total_sales < AVG(total_sales) OVER () THEN 'Low'
        ELSE 'Average'
    END AS season
FROM MonthlySales
ORDER BY fiscal_year, `month`;


#14. Estimate the revenue growth rate of 4-wheeler and 2-wheelers EVs in India for 2022 vs 2024 and 2023 vs 2024,
# assuming an average unit price. 

ALTER TABLE electric_vehicle_sales_by_state
ADD COLUMN unit_price INT;

UPDATE electric_vehicle_sales_by_state
SET unit_price = CASE
    WHEN vehicle_category = '2-Wheelers' THEN 85000
    WHEN vehicle_category = '4-Wheelers' THEN 1500000
    ELSE unit_price  -- In case there's an unexpected vehicle_type
END;

WITH RevenueByYear AS (
    -- Calculate total revenue for each year and vehicle type
    SELECT
        fiscal_year,
        vehicle_category,
        SUM(electric_vehicles_sold * unit_price) AS total_revenue
    FROM electric_vehicle_sales_by_state JOIN dim_date ON 
electric_vehicle_sales_by_state.`date`= dim_date.`date`
    WHERE vehicle_category IN ('2-Wheelers', '4-Wheelers')
    AND fiscal_year IN (2022, 2023, 2024)
    GROUP BY fiscal_year, vehicle_category
),
RevenueGrowth AS (
    -- Calculate revenue growth between 2022 and 2024, and between 2023 and 2024
    SELECT
        a.vehicle_category,
        -- Calculate growth rate for 2022 vs 2024
        ((b.total_revenue - a.total_revenue) / a.total_revenue) * 100 AS growth_rate_2022_vs_2024,
        -- Calculate growth rate for 2023 vs 2024
        ((c.total_revenue - a.total_revenue) / a.total_revenue) * 100 AS growth_rate_2023_vs_2024
    FROM RevenueByYear a
    LEFT JOIN RevenueByYear b ON a.vehicle_category = b.vehicle_category AND b.fiscal_year = 2024
    LEFT JOIN RevenueByYear c ON a.vehicle_category = c.vehicle_category AND c.fiscal_year = 2023
    WHERE a.fiscal_year = 2022
)
SELECT
    vehicle_category,
    concat(round(growth_rate_2022_vs_2024,2),'%')as growth_rate_2022_vs_2024 ,
    concat(round(growth_rate_2023_vs_2024,2),'%')as growth_rate_2023_vs_2024
FROM RevenueGrowth;

CREATE view `2022_2024` AS 
(SELECT 
	vehicle_category,fiscal_year,
	CASE
		WHEN vehicle_category="2-Wheelers" THEN sum(electric_vehicles_sold*85000)
        ELSE sum(electric_vehicles_sold*1500000)
        END AS revenue
FROM electric_vehicle_sales_by_makers ev 
JOIN dim_date d 
ON d.date=ev.date
WHERE fiscal_year IN (2022,2024)
group by vehicle_category,fiscal_year
order by vehicle_category,fiscal_year);
SELECT * FROM `2022_2024`;

SELECT 
    t1.vehicle_category,
    t1.revenue AS revenue_2022,
    t2.revenue AS revenue_2024,
    concat((((t2.revenue - t1.revenue) / t1.revenue) * 100),'%') AS growth_rate_percentage
FROM 
    `2022_2024` t1
JOIN 
    `2022_2024` t2
ON 
    t1.vehicle_category = t2.vehicle_category
WHERE 
    t1.fiscal_year = 2022
    AND t2.fiscal_year = 2024;

#2023 vs 2024:
CREATE VIEW 2023_2024 AS 
(SELECT vehicle_category,fiscal_year,
	CASE
		WHEN vehicle_category="2-Wheelers" THEN sum(electric_vehicles_sold*85000)
        ELSE sum(electric_vehicles_sold*1500000)
        END AS revenue
FROM electric_vehicle_sales_by_makers ev 
JOIN dim_date d 
ON d.date=ev.date
WHERE fiscal_year IN (2023,2024)
GROUP BY  vehicle_category,fiscal_year
ORDER BY vehicle_category,fiscal_year);
SELECT * FROM 2023_2024;
SELECT 
    t1.vehicle_category,
    t1.revenue AS revenue_2023,
    t2.revenue AS revenue_2024,
    concat((((t2.revenue - t1.revenue) / t1.revenue) * 100),'%') AS growth_rate_percentage
FROM 
    2023_2024 t1
JOIN 
    2023_2024 t2
ON 
    t1.vehicle_category = t2.vehicle_category
WHERE 
    t1.fiscal_year = 2023
    AND t2.fiscal_year = 2024;





 




