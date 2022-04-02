/*

COVID 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Window Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;


-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Total Cases vs Population
-- Shows what percentage of population infected with COVID

SELECT Location, date, Population, total_cases, (total_cases/Population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS PercentPopulationInfected
, FORMAT(MAX(date), 'MM-dd-yyyy') AS date
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount, FORMAT(MAX(date), 'MM-dd-yyyy') AS date
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Showing death rate per infected in each continent

SELECT location AS continent, MAX(CAST(Total_deaths AS int)) AS TotalDeathCount, MAX(total_cases) AS TotalInfectedCount
, MAX(CAST(Total_deaths AS int))/MAX(total_cases)* 100 AS DeathRatePerInfected, FORMAT(MAX(date), 'MM-dd-yyyy') AS date
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL AND location NOT LIKE '%income' AND location NOT LIKE 'International%' AND location NOT LIKE 'World' AND location NOT LIKE 'European Union'
GROUP BY location
ORDER BY DeathRatePerInfected DESC;

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
, FORMAT(MAX(date), 'MM-dd-yyyy') AS date
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has received at least one COVID Vaccine

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location 
ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location 
ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS PercentVaccinated
FROM PopvsVac;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(225),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location 
ORDER BY dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/Population)* 100 AS PercentVaccinated
FROM #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

-- Showing the top 15 countries with the highest GDP per capita to see if the COVID death rate will be low

SELECT TOP 15 dea.location, dea.population, MAX(dea.total_cases) AS total_COVID_cases, MAX(CAST(total_deaths AS int)) AS total_COVID_deaths
, MAX(CAST(total_deaths AS int))/MAX(dea.total_cases)*100 AS COVID_death_rate_per_infected, MAX(vac.gdp_per_capita) AS GDP_Per_Capita
, FORMAT(MAX(dea.date), 'MM-dd-yyyy') AS date
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
WHERE dea.total_cases IS NOT NULL AND dea.total_deaths IS NOT NULL AND GDP_Per_Capita IS NOT NULL
GROUP BY dea.location, dea.population
ORDER BY GDP_Per_Capita DESC;

-- Showing the top 15 countries with the lowest GDP per capita to see if the COVID death rate will be high

SELECT TOP 15 dea.location, dea.population, MAX(dea.total_cases) AS total_COVID_cases, MAX(CAST(total_deaths AS int)) AS total_COVID_deaths
, MAX(CAST(total_deaths AS int))/MAX(dea.total_cases)*100 AS COVID_death_rate_per_infected, MAX(vac.gdp_per_capita) AS GDP_Per_Capita
, FORMAT(MAX(dea.date), 'MM-dd-yyyy') AS date
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location
WHERE dea.total_cases IS NOT NULL AND dea.total_deaths IS NOT NULL AND GDP_Per_Capita IS NOT NULL
GROUP BY dea.location, dea.population
ORDER BY GDP_Per_Capita;