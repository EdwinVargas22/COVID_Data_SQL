SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4;

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2;

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract COVID in your country
SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2;


-- Looking at Total Cases vs Population
-- Shows what percentage of population got COVID

SELECT Location, date, Population, total_cases, (total_cases/Population)*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2;

-- Looking at Countries with Highest Infection Rate compared to Population

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/Population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Showing Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing contintents with the hightest death count per popluation

SELECT location AS continent, MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent IS NULL AND location NOT LIKE '%income' AND location NOT LIKE 'International%'
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS int)) AS total_deaths, SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
--WHERE Location LIKE '%states%'
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;


-- Looking at Total Population vs Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location 
ORDER BY dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- USE CTE

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location 
ORDER BY dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac;


-- TEMP TABLE

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
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated;


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS bigint)) OVER (PARTITION BY dea.location 
ORDER BY dea.date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *
FROM PercentPopulationVaccinated;
