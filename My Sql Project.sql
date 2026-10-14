SELECT * FROM ab_nyc_2019;

-- STEP 1:DATA CLEANING AND QUALITY CHECKS --
-- Purpose: Inspect the Dataset for missing values, duplicate records,and data anomalies (outliers) before performing deep-dive analysis, 
-- Find Missing Values--
SELECT 
    SUM(CASE WHEN name IS NULL OR name = '' THEN 1 ELSE 0 END) AS missing_names,
    SUM(CASE WHEN host_name IS NULL OR host_name = '' THEN 1 ELSE 0 END) AS missing_host_names,
    SUM(CASE WHEN last_review IS NULL OR last_review = '' THEN 1 ELSE 0 END) AS missing_last_reviews,
    SUM(CASE WHEN reviews_per_month IS NULL THEN 1 ELSE 0 END) AS missing_reviews_per_month
FROM ab_nyc_2019;

--  Find Duplicate Row--
SELECT id, COUNT(*)
FROM ab_nyc_2019
group by ID
HAVING count(*) > 1;

-- Find Data Anomalies/Outliers --
SELECT *
FROM ab_nyc_2019
WHERE price <=0 OR minimum_nights<=0;

-- Clean/Filter View --
SELECT* FROM ab_nyc_2019 WHERE price > 0;


-- STEP 2: EXPLORATORY DATA ANALYSIS (EDA)
-- Purpose: Discover basic patterns, distributions, summary statistics, 
-- and overall structure of the NYC Airbnb dataset. --


-- 1. Total Listings and Price Statistics by Borough Group
-- This query aggregates listings by neighborhood group to compare total 
-- inventory, average prices, and price ranges across different boroughs.
SELECT 
    neighbourhood_group,
    COUNT(id) AS total_listings,
    ROUND(AVG(price), 2) AS avg_price,
    MIN(price) AS min_price,
    MAX(price) AS max_price
FROM ab_nyc_2019
GROUP BY neighbourhood_group
ORDER BY total_listings DESC;


-- 2. Room Type Distribution and Market Share
-- This query breaks down listings by room type to see what accommodation 
-- style is most common across New York City.
SELECT 
    room_type,
    COUNT(id) AS total_count,
    ROUND(COUNT(id) * 100.0 / (SELECT COUNT(*) FROM ab_nyc_2019), 2) AS percentage_share
FROM ab_nyc_2019
GROUP BY room_type
ORDER BY total_count DESC;


-- 3. Overall Price Summary Statistics
-- This query provides a high-level overview of the entire dataset's 
-- pricing structure (overall average, minimum, and maximum).
SELECT 
    COUNT(id) AS total_properties,
    ROUND(AVG(price), 2) AS overall_avg_price,
    MIN(price) AS lowest_price,
    MAX(price) AS highest_price
FROM ab_nyc_2019;


-- STEP 3: ANSWER CORE BUSINESS QUESTIONS
-- Purpose: Write targeted analytical queries to solve real-world 
-- business problems and uncover deeper trends in the NYC Airbnb market. --

-- 1. Question A: Which specific neighborhoods are the most expensive?
-- This query calculates the average price per neighborhood, filtering out 
-- neighborhoods with fewer than 10 listings to ensure the averages are reliable.
SELECT 
    neighbourhood_group,
    neighbourhood,
    ROUND(AVG(price), 2) AS avg_price,
    COUNT(id) AS listing_count
FROM ab_nyc_2019
GROUP BY neighbourhood_group, neighbourhood
HAVING COUNT(id) > 10  
ORDER BY avg_price DESC
LIMIT 10;


-- 2. Question B: Who are the top hosts by inventory and estimated revenue?
-- This query identifies hosts with the highest number of listings and 
-- estimates their potential revenue based on price and minimum nights.
SELECT 
    host_id,
    host_name,
    COUNT(id) AS total_listings,
    SUM(price * minimum_nights) AS estimated_revenue
FROM ab_nyc_2019
GROUP BY host_id, host_name
ORDER BY total_listings DESC
LIMIT 10;


-- 3. Question C: Which price categories get the most reviews?
-- This query uses conditional logic (CASE WHEN) to group listings into 
-- pricing tiers and checks which tier attracts the highest average review counts.
SELECT 
    CASE 
        WHEN price < 100 THEN 'Budget (< $100)'
        WHEN price BETWEEN 100 AND 250 THEN 'Moderate ($100 - $250)'
        WHEN price BETWEEN 251 AND 500 THEN 'Expensive ($251 - $500)'
        ELSE 'Luxury (> $500)'
    END AS price_category,
    COUNT(id) AS total_listings,
    ROUND(AVG(number_of_reviews), 2) AS avg_reviews
FROM ab_nyc_2019
GROUP BY price_category
ORDER BY avg_reviews DESC;



-- STEP 4: ADVANCED SQL & WINDOW FUNCTIONS
-- Purpose: Demonstrate advanced querying capabilities, such as ranking 
-- partitions, running totals, and comparative metrics across groups.--

-- 1. Find the Top 3 Most Expensive Listings in Every Borough Group
-- This query uses a CTE (Common Table Expression) combined with the 
-- ROW_NUMBER() window function partitioned by borough to rank listings by price.
WITH RankedListings AS (
    SELECT 
        neighbourhood_group,
        neighbourhood,
        name,
        price,
        room_type,
        ROW_NUMBER() OVER(PARTITION BY neighbourhood_group ORDER BY price DESC) AS price_rank
    FROM ab_nyc_2019
)
SELECT 
    neighbourhood_group,
    neighbourhood,
    name,
    price,
    room_type
FROM RankedListings
WHERE price_rank <= 3;


-- 2. Compare Individual Listing Price to the Borough Average
-- This query uses an analytical window function to calculate the average 
-- price of each borough alongside every individual listing, allowing you 
-- to see how much cheaper or more expensive a specific property is compared to its peers.
SELECT 
    name,
    neighbourhood_group,
    neighbourhood,
    price,
    ROUND(AVG(price) OVER(PARTITION BY neighbourhood_group), 2) AS borough_avg_price,
    price - ROUND(AVG(price) OVER(PARTITION BY neighbourhood_group), 2) AS price_difference_from_borough_avg
FROM ab_nyc_2019
ORDER BY neighbourhood_group, price DESC;