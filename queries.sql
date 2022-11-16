SELECT * 
FROM covid_deaths
ORDER BY 3,4  

--SELECT * 
--FROM covid_vaccinations
--ORDER BY 3,4 

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, (total_deaths/total_cases)*100 AS death_percentage
FROM covid_deaths
-- WHERE location LIKE '%States%' -- in US
ORDER BY location, date 

-- Countries with Highest Infection Rate compare to Population
SELECT *
FROM (
	SELECT location, population, MAX(total_cases) as highest_infection_count, MAX((total_deaths/total_cases))*100 AS percent_population_infected
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY percent_population_infected DESC
) AS subquery
WHERE percent_population_infected IS NOT NULL

-- Countries with Highest Death Count Per Population
SELECT *
FROM (
	SELECT location, MAX(total_deaths) AS total_death_count
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY total_death_count DESC
) AS subquery
WHERE total_death_count IS NOT NULL

-- Countries with Highest Death Count Per Population exclusing 
SELECT *
FROM (
	SELECT location, MAX(total_deaths) AS total_death_count
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY location, population
	ORDER BY total_death_count DESC
) AS subquery
WHERE total_death_count IS NOT NULL 

-- Summarizing total_deaths by continent
SELECT *
FROM (
	SELECT continent, MAX(total_deaths) AS total_death_count
	FROM covid_deaths
	WHERE continent IS NOT NULL
	GROUP BY continent
	ORDER BY total_death_count DESC
) AS subquery
WHERE total_death_count IS NOT NULL 
-- but counts are incorrect...

-- Correcting counts above
SELECT *
FROM (
	SELECT location, MAX(total_deaths) AS total_death_count
	FROM covid_deaths
	WHERE continent IS NULL AND location NOT LIKE '%income%' -- filter out socieconomic groupings
	GROUP BY location
	ORDER BY total_death_count DESC
) AS subquery
WHERE total_death_count IS NOT NULL 

--------------------
-- Global numbers --
--------------------

-- New cases by date
SELECT *, (new_deaths/new_cases)*100 AS percent_death_rate
FROM (
	SELECT date, SUM(new_cases) AS new_cases, SUM(new_deaths) AS new_deaths
	FROM covid_deaths
	GROUP BY date
	ORDER BY date
) AS subquery
WHERE new_deaths IS NOT NULL AND new_deaths != 0

-- Total 
SELECT *, (total_deaths/total_cases)*100 AS percent_death_rate
FROM (
	SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths
	FROM covid_deaths
	) AS subquery
WHERE total_deaths IS NOT NULL AND total_deaths != 0

-- Look at Total Population vs Vaccinations with Window Functions
SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,
	SUM(vax.new_vaccinations) OVER (PARTITION BY dth.location 
									ORDER BY dth.location, dth.date) AS rolling_vax_count
FROM covid_deaths AS dth
JOIN covid_vaccinations as vax
	ON dth.location = vax.location
	AND dth.date = vax.date
WHERE dth.continent IS NOT NULL
ORDER BY 2,3

-- USE CTE to add vax rate
WITH POPVAX (continent, location, date, population, new_vaccinations, rolling_vax_count)
AS (
SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,
	SUM(vax.new_vaccinations) OVER (PARTITION BY dth.location 
									ORDER BY dth.location, dth.date) AS rolling_vax_count
FROM covid_deaths AS dth
JOIN covid_vaccinations as vax
	ON dth.location = vax.location
	AND dth.date = vax.date
WHERE dth.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (rolling_vax_count/population) * 100 AS rolling_vax_rate
FROM POPVAX

-- Now, USE Temp table to add vax rate instad
DROP TABLE IF EXISTS percent_pop_vax;
CREATE TEMP TABLE percent_pop_vax AS
(
SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,
	SUM(vax.new_vaccinations) OVER (PARTITION BY dth.location 
									ORDER BY dth.location, dth.date) AS rolling_vax_count
FROM covid_deaths AS dth
JOIN covid_vaccinations as vax
	ON dth.location = vax.location
	AND dth.date = vax.date
WHERE dth.continent IS NOT NULL
)
SELECT *, (rolling_vax_count/population) * 100 AS rolling_vax_rate
FROM percent_pop_vax

-- Creating View for visualizations
CREATE VIEW percent_pop_vax AS 
SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,
	SUM(vax.new_vaccinations) OVER (PARTITION BY dth.location 
									ORDER BY dth.location, dth.date) AS rolling_vax_count
FROM covid_deaths AS dth
JOIN covid_vaccinations as vax
	ON dth.location = vax.location
	AND dth.date = vax.date
WHERE dth.continent IS NOT NULL



