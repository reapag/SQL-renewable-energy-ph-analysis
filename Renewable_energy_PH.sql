-- DATA PREVIEW

-- Check if all rows were imported successfully by selecting all data.
SELECT 
	*
FROM 
	country;

--=======================================================
-- DATA PREPARATION

-- Standardize column names by converting them to snake_case to enhance readability and avoid issues with case sensitivity or spaces.

ALTER TABLE country RENAME COLUMN "M49 code" TO m49_code;
ALTER TABLE country RENAME COLUMN "Year" TO year;
ALTER TABLE country RENAME COLUMN "Electricity Generation (GWh)" TO electricity_generation_gwh;
ALTER TABLE country RENAME COLUMN "Electricity Installed Capacity (MW)" TO electricity_installed_capacity_mw;
ALTER TABLE country RENAME COLUMN "Heat Generation (TJ)" TO heat_generation_tj;
ALTER TABLE country RENAME COLUMN "Public Flows (2021 USD M)" TO public_flows_2021_usd_m;
ALTER TABLE country RENAME COLUMN "SDG 7a1 Intl. Public Flows (2021 USD M)" TO sdg_7a1_intl_public_flows_2021_usd_m;
ALTER TABLE country RENAME COLUMN "SDG 7b1 RE capacity per capita (W/inhabitant)" TO sdg_7b1_re_capacity_per_capita_w_inhabitant;
ALTER TABLE country RENAME COLUMN "Producer Type" TO producer_type;
ALTER TABLE country RENAME COLUMN "Sub-Technology" TO sub_technology;
ALTER TABLE country RENAME COLUMN "Sub-region" TO sub_region;
ALTER TABLE country RENAME COLUMN "Country" TO country;
ALTER TABLE country RENAME COLUMN "ISO3 code" TO iso3_code;
ALTER TABLE country RENAME COLUMN "RE or Non-RE" TO re_or_non_re;
ALTER TABLE country RENAME COLUMN "Group Technology" TO group_technology;
ALTER TABLE country RENAME COLUMN "Technology" TO technology;
ALTER TABLE country RENAME COLUMN "Region" TO region;

--=======================================================

-- DATA CLEANING

-- Check for NULL values in critical columns for better data consistency
-- This helps ensure data completeness before proceeding to analysis

SELECT 
    *
FROM 
    country
WHERE 
    m49_code IS NULL;

SELECT 
    *
FROM 
    country
WHERE 
    year IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    producer_type IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    sub_technology IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    sub_region IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    country IS NULL;

SELECT 
    *
FROM 
    country
WHERE 
    iso3_code IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    re_or_non_re IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    group_technology IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    technology IS NULL;

SELECT 
    *
FROM 
    country
WHERE 	
    region IS NULL;
	

-- Check distinct values for specific columns to verify if the categories are properly grouped and there are no duplicates

SELECT DISTINCT
    region
FROM 
    country;

SELECT DISTINCT
    sub_region
FROM 
    country;

SELECT DISTINCT
    country
FROM 
    country;

SELECT DISTINCT
    technology
FROM 
    country;

SELECT DISTINCT
    sub_technology
FROM 
    country;

SELECT DISTINCT
    producer_type
FROM 
    country;

--=======================================================
-- BACKUP and CLEANUP

-- Create a backup table before deleting rows or any other permanent changes

CREATE TABLE country_backup AS
SELECT *
FROM country

-- Identify rows with 'Unspecified countries' in the 'region' column for deletion as this is not relevant

SELECT
    *
FROM 
    country
WHERE 
	region = 'Unspecified countries';

-- Delete rows where the region is 'Unspecified countries' to maintain relevant data

DELETE FROM 
    country
WHERE 
	region = 'Unspecified countries';

-- Replace '(blank)' entries in 'sub_region' with NULL for data consistency

UPDATE
	country 
SET 
	sub_region = NULL
WHERE 
	sub_region = '(blank)';


--=======================================================
-- DATA EXPLORATION

-- A. Renewable energy capacity in the Philippines
-- This query calculates total renewable energy capacity, annual capacity additions, and year-on-year growth


WITH re_capacity_ph AS -- Calculate the total installed renewable energy capacity for each year in the Philippines

(
	SELECT
		year,
		SUM(electricity_installed_capacity_mw) AS total_capacity
	FROM 
		country
	WHERE
		country LIKE '%Philippines%'
		AND re_or_non_re = 'Total Renewable'
	GROUP BY
		year
	ORDER BY
		year
),
capacity_growth AS -- Calculate the annual capacity additions and year-on-year growth
(
	SELECT
		year,
		total_capacity,
		LAG(total_capacity) OVER (ORDER BY year) AS previous_capacity,
		(total_capacity - (LAG(total_capacity) OVER (ORDER BY year))) AS annual_additional_capacity,
		ROUND((total_capacity - (LAG(total_capacity) OVER (ORDER BY year))) / (LAG(total_capacity) OVER (ORDER BY year))*100, 2) AS YoY_growth
	FROM
		re_capacity_ph
	GROUP BY
		year, total_capacity
)
-- Final output: Total capacity, annual additions, and YoY growth for renewable energy in the Philippines

SELECT
	year,
	total_capacity AS total_capacity_mw,
	annual_additional_capacity As annual_additional_capacity_mw,
	YoY_growth AS YoY_growth_percentage
FROM
	capacity_growth	


-- B. Renewable energy breakdown in the Philippines
-- This query calculates the capacity and share of each renewable energy technology type over the years

SELECT
	year,
	group_technology, -- Renewable energy technology group (e.g., wind, solar, hydro)
	SUM(electricity_installed_capacity_mw) AS capacity_mw,   -- Total capacity for each technology type
	SUM(SUM(electricity_installed_capacity_mw)) OVER (PARTITION BY year) as total_re_capacity_mw, -- Total renewable energy capacity for the year
	ROUND((SUM(electricity_installed_capacity_mw) / SUM(SUM(electricity_installed_capacity_mw)) OVER (PARTITION BY year)) * 100, 2) AS percentage_share  -- Percentage share of each technology type
FROM
	country
WHERE
	country LIKE '%Philippines%'
	AND re_or_non_re = 'Total Renewable'
GROUP BY
	year,
	group_technology
ORDER BY
	year;
	

-- C. Renewable energy generation vs. capacity in the Philippines
-- This query calculates the energy yield, comparing energy generation to installed capacity for renewable energy

SELECT
	year,
	SUM(CASE WHEN re_or_non_re = 'Total Renewable' THEN electricity_generation_GWh * 1000 ELSE 0 END) AS re_generation_mw,
	SUM(CASE WHEN re_or_non_re = 'Total Renewable' THEN electricity_installed_capacity_mw ELSE 0 END) AS re_installed_capacity_mw,
	ROUND((SUM(CASE WHEN re_or_non_re = 'Total Renewable' THEN electricity_generation_GWh * 1000 ELSE 0 END)/NULLIF(SUM(CASE WHEN re_or_non_re = 'Total Renewable' THEN electricity_installed_capacity_mw ELSE 0 END), 0)),0) AS energy_yield_mw
FROM 
	country
WHERE
	country LIKE '%Philippines%'
GROUP BY
	year

-- D. Share of Renewabless in total energy mix in the Philippines
-- This query calculates the share of renewable energy in total electricity generation


SELECT
	year,
	SUM(electricity_generation_GWh) AS total_generation,
	SUM(CASE WHEN re_or_non_re = 'Total Renewable' THEN electricity_generation_GWh ELSE 0 END) as total_re_generation,
	ROUND((SUM(CASE WHEN re_or_non_re = 'Total Renewable' THEN electricity_generation_GWh ELSE 0 END)/SUM(electricity_generation_GWh))*100,2) as percentage_re_in_total_generation
FROM 
	country
WHERE
	country LIKE '%Philippines%'
GROUP BY
	year
ORDER BY
	year;


-- Annual growth in the share of renewables in the energy mix

WITH total_generation_ph AS 
(
	SELECT
		year,
		SUM(electricity_generation_GWh) AS total_generation,
		SUM(CASE WHEN re_or_non_re = 'Total Renewable' THEN electricity_generation_GWh ELSE 0 END) as re_generation
	FROM 
		country
	WHERE
		country LIKE '%Philippines%'
	GROUP BY
		year
),
re_share AS
(
	SELECT
		year,
		total_generation,
		re_generation,
		ROUND((re_generation/total_generation)*100,2) AS re_share,
		LAG(ROUND((re_generation/total_generation)*100,2)) OVER (ORDER BY year) AS re_share_last_year
	FROM
		total_generation_ph
),
yoy_change AS
(
	SELECT
		year,
		re_share,
		re_share_last_year,
		ROUND((re_share-re_share_last_year)/re_share_last_year,2) AS yoy_change
	FROM
		re_share
)

-- Final output: Yearly share of renewable energy and year-on-year changes
SELECT
	year,
	re_share,
	re_share_last_year,
	yoy_change
FROM
	yoy_change
ORDER BY
	year;

