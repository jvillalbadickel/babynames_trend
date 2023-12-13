-- Create DB
DROP TABLE baby_names;

CREATE TABLE baby_names (
  year INT,
  first_name VARCHAR(64),
  sex VARCHAR(64),
  num INT
);

-- Copy CSV
\copy baby_names FROM 'datasets/usa_baby_names.csv' DELIMITER ',' CSV HEADER;


-- Select first names and the total babies with that first_name
-- Group by first_name and filter for those names that appear in all 101 years
-- Order by the total number of babies with that first_name, descending
SELECT 
    first_name, 
    SUM(num)
FROM 
    baby_names
GROUP BY 
    first_name
HAVING 
    COUNT(num) = 101
ORDER BY 
    SUM(num) DESC;


-- Classify first names as 'Classic', 'Semi-classic', 'Semi-trendy', or 'Trendy'
-- Alias this column as popularity_type
-- Select first_name, the sum of babies who have ever had that name, and popularity_type
-- Order the results alphabetically by first_name
SELECT 
    first_name,
    SUM(num),
    CASE 
        WHEN COUNT(year) >= 80 THEN 'Classic'
        WHEN COUNT(year) >= 50 THEN 'Semi-classic'
        WHEN COUNT(year) >= 20 THEN 'Semi-trendy'
        ELSE 'Trendy'
     END AS popularity_type
FROM baby_names
GROUP BY first_name
ORDER BY first_name


-- RANK names by the sum of babies who have ever had that name (descending), aliasing as name_rank
-- Select name_rank, first_name, and the sum of babies who have ever had that name
-- Filter the data for results where sex equals 'F'
-- Limit to ten results
SELECT
    RANK() OVER(ORDER BY SUM(num) DESC) AS name_rank,
    first_name,
    SUM(num)
FROM 
    baby_names
WHERE 
    sex = 'F'
GROUP BY 
    first_name
ORDER BY 
    name_rank
LIMIT 
    10;


-- Select only the first_name column
-- Filter for results where sex is 'F', year is greater than 2015, and first_name ends in 'a'
-- Group by first_name and order by the total number of babies given that first_name

SELECT 
    first_name
FROM 
    baby_names
WHERE
    sex = 'F' AND 
    year > 2015 AND
    first_name LIKE '%a'
GROUP BY
    first_name
ORDER BY
    SUM(num) DESC


-- Select year, first_name, num of Olivias in that year, and cumulative_olivias
-- Sum the cumulative babies who have been named Olivia over the years
-- Ensure only data for the name Olivia is returned.
-- Order by year from the earliest year to most recent
SELECT 
    year,
    first_name,
    num,
    SUM(num) OVER (ORDER BY year) AS cumulative_olivias
FROM 
    baby_names
WHERE 
    first_name = 'Olivia'
ORDER BY 
    year;


-- Select year and maximum number of babies given any one male name in that year, aliased as max_num
-- Filter the data to include only results where sex equals 'M'
SELECT 
    year, 
    MAX(num) AS max_num
FROM
    baby_names
WHERE
    sex = 'M'
GROUP BY
    year


-- Select year, first_name given to the largest number of male babies, and num of babies given that name
-- Join baby_names to the code in the last task as a subquery
-- Order results by year descending
SELECT 
    a.year,
    a.first_name,
    a.num
FROM 
    baby_names AS a
JOIN 
    (SELECT 
         year, 
         MAX(num) AS max_num
     FROM 
         baby_names 
     WHERE 
         sex = 'M' 
     GROUP BY 
         year
    ) AS b 
    ON a.year = b.year AND a.num = b.max_num
WHERE 
    a.sex = 'M'
ORDER BY 
    a.year DESC;


-- Select first_name and a count of years it was the top name in the last task; alias as count_top_name
-- Use the code from the previous task as a common table expression
-- Group by first_name and order by count_top_name descending
WITH top_names AS (
    SELECT 
        a.year,
        a.first_name,
        a.num
    FROM 
        baby_names AS a
    JOIN 
        (SELECT 
             year, 
             MAX(num) AS max_num
         FROM 
             baby_names 
         WHERE 
             sex = 'M' 
         GROUP BY 
             year
        ) AS b 
        ON a.year = b.year AND a.num = b.max_num
    WHERE 
        a.sex = 'M'
    ORDER BY 
        a.year DESC
)

SELECT
    first_name,
    COUNT(year) AS count_top_name
FROM 
    top_names
GROUP BY
    first_name
ORDER BY
    count_top_name DESC;


-- Determine the most popular first name for each decade
WITH DecadeData AS (
    SELECT 
        (year / 10) * 10 AS decade, 
        first_name, 
        SUM(num) AS total
    FROM baby_names
    GROUP BY decade, first_name
)
SELECT 
    decade, 
    first_name,
    RANK() OVER(PARTITION BY decade ORDER BY total DESC) as rank
FROM DecadeData
WHERE rank = 1;


-- Find the year when each name was most popular
SELECT 
    first_name,
    year,
    num,
    RANK() OVER(PARTITION BY first_name ORDER BY num DESC) as popularity_rank
FROM baby_names
WHERE popularity_rank = 1;


-- Count the number of unique names given each year
SELECT 
    year, 
    COUNT(DISTINCT first_name) as unique_names_count
FROM baby_names
GROUP BY year;


-- Identify names that have risen in popularity each decade
WITH DecadeRank AS (
    SELECT 
        first_name,
        (year / 10) * 10 AS decade,
        RANK() OVER(PARTITION BY (year / 10) * 10 ORDER BY SUM(num) DESC) as rank
    FROM baby_names
    GROUP BY decade, first_name
)
SELECT 
    first_name
FROM DecadeRank
WHERE rank = 1 AND decade = 2020;


-- Track the change in popularity of a specific name over time
SELECT 
    year,
    first_name,
    num,
    LAG(num, 1) OVER (ORDER BY year) as previous_year_num
FROM baby_names
WHERE first_name = 'Olivia';


-- Determine the average number of babies given each name per year
SELECT 
    first_name, 
    AVG(num) as average_per_year
FROM baby_names
GROUP BY first_name;


-- Find the total number of names that only appeared once in the dataset
WITH NameCounts AS (
    SELECT 
        first_name, 
        COUNT(*) as count
    FROM baby_names
    GROUP BY first_name
)
SELECT 
    COUNT(*) as single_appearance_names
FROM NameCounts
WHERE count = 1;


-- Identify the year with the greatest diversity in baby names
SELECT 
    year, 
    COUNT(DISTINCT first_name) as unique_names
FROM baby_names
GROUP BY year
ORDER BY unique_names DESC
LIMIT 1;


-- Analyze the gender distribution for the most popular names
WITH GenderDistribution AS (
    SELECT 
        first_name, 
        sex, 
        SUM(num) as total
    FROM baby_names
    GROUP BY first_name, sex
)
SELECT 
    first_name,
    MAX(CASE WHEN sex = 'M' THEN total ELSE 0 END) as male_total,
    MAX(CASE WHEN sex = 'F' THEN total ELSE 0 END) as female_total
FROM GenderDistribution
GROUP BY first_name;


-- Identify names that have shifted in gender preference over time
WITH GenderShift AS (
    SELECT 
        first_name, 
        sex, 
        (year / 10) * 10 AS decade, 
        SUM(num) as total
    FROM baby_names
    GROUP BY first_name, sex, decade
)
SELECT 
    first_name,
    MAX(CASE WHEN sex = 'M' THEN total ELSE 0 END) as male_total,
    MAX(CASE WHEN sex = 'F' THEN total ELSE 0 END) as female_total
FROM GenderShift
GROUP BY first_name
HAVING MAX(male_total) > 0 AND MAX(female_total) > 0;






