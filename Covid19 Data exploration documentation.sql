/* 
===========================================================
 COVID-19 DATA EXPLORATION PROJECT
-----------------------------------------------------------
 Purpose:
 This SQL analysis explores global COVID-19 data by examining 
 infection trends, mortality rates, population impact, and 
 vaccination progress. The goal is to uncover insights into 
 how the pandemic affected different regions over time and 
 prepare datasets for visualization and reporting.

 Key Tasks Covered:
 • Highest infection rates by location  
 • Countries with highest death counts  
 • Daily global death percentage  
 • Rolling vaccination progress using window functions  
 • CTEs + temporary tables for clean analysis
===========================================================
*/

-- Viewing the raw dataset
SELECT *
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Total Cases vs Total Deaths (Likelihood of Dying When Infected)
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / NULLIF(total_cases, 0)) * 100 AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Total Cases vs Population (Percentage Infected)
SELECT 
    location,
    date,
    population,
    total_cases,
    (total_cases / NULLIF(population, 0)) * 100 AS percent_population_infected
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
ORDER BY location, date;


-- Countries With Highest Infection Rate Compared to Population
SELECT 
    location,
    population,
    MAX(total_cases) AS highest_infection_count,
    MAX((total_cases / NULLIF(population, 0))) * 100 AS percent_population_infected
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC;


-- Countries With Highest Total Death Count
SELECT 
    location,
    MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


-- Continents With the Highest Death Count
SELECT 
    continent,
    MAX(CAST(total_deaths AS INT)) AS total_death_count
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-- Global Numbers Per Day
SELECT 
    date,
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    (SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100 AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


-- Total Global Numbers
SELECT 
    SUM(new_cases) AS total_cases,
    SUM(new_deaths) AS total_deaths,
    (SUM(new_deaths) / NULLIF(SUM(new_cases), 0)) * 100 AS death_percentage
FROM PortfolioProject..CovidDeath
WHERE continent IS NOT NULL;


-- Vaccination Progress (CTE for Rolling Count)
WITH pop_vs_vac AS (
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(COALESCE(vac.new_vaccinations, 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject..CovidDeath AS dea
    JOIN PortfolioProject..CovidVaccine AS vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *,
       (rolling_people_vaccinated / NULLIF(population, 0)) * 100 AS percent_population_vaccinated
FROM pop_vs_vac
ORDER BY location, date;


-- Temp Table Version (for visualization tools)
DROP TABLE IF EXISTS #percent_population_vaccinated;

CREATE TABLE #percent_population_vaccinated (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATE,
    population NUMERIC,
    new_vaccinations NUMERIC,
    rolling_people_vaccinated NUMERIC
);

INSERT INTO #percent_population_vaccinated
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
        SUM(COALESCE(vac.new_vaccinations, 0)) 
            OVER (PARTITION BY dea.location ORDER BY dea.date) 
FROM PortfolioProject..CovidDeath AS dea
JOIN PortfolioProject..CovidVaccine AS vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *,
       (rolling_people_vaccinated / NULLIF(population, 0)) * 100 AS percent_population_vaccinated
FROM #percent_population_vaccinated;
