/* Exploration of Data concerning COVID-19
	SKILLS USED FOR THIS PROJECT: 
	Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


SELECT *
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY location, date;

SELECT *
FROM PortfolioProject..CovidVaccinations$
ORDER BY location, date;

--Select Data we are going to start using

SELECT location, date, total_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY location, date;


--Look at Total Cases vs Total Deaths: 
--Shows likelihood of dying if you contract Covid by Country

SELECT location, date, total_cases, total_deaths, ROUND((total_deaths/total_cases)*100,1) AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
ORDER BY 1,2;

--Look at TotalCases vs Population: shows percentage of population got Covid in Germany and United States
SELECT Location, date, total_cases,total_deaths, ROUND((total_deaths/total_cases),3)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE location LIKE '%states%' OR location LIKE 'Germany'
AND continent IS NOT NULL
ORDER BY 1,2


--Which country has highest infection rate??

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX(ROUND((total_cases/population),3)*100) AS PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths$
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC;
 
-- Countries with Highest Death Count per Population

SELECT Location, MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths$
--Where location like '%states%'
WHERE continent IS NOT NULL
GROUP BY  Location
ORDER BY TotalDeathCount DESC;

--Showing countries with highest mortality rate
SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount, MAX(ROUND((total_deaths/population),3)*100) AS MortalityRate
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY MortalityRate DESC;

--Mortality rate by continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount, MAX(ROUND((total_deaths/population),3)*100) AS MortalityRate
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY MortalityRate DESC;


--GLOBAL NUMBERS


SELECT  date, SUM(new_cases) AS totalcases, SUM(CAST(new_deaths AS INT)) AS totaldeaths, ROUND(SUM(CAST(new_deaths AS INT))/ SUM(new_cases),3) *100 AS deathpercentage   --, total_deaths, ROUND((total_deaths/total_cases)*100,1) as DeathPercentage
FROM PortfolioProject..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date 
ORDER BY deathpercentage DESC;

--JOIN DATASETS DEATHS + VACCINATIONS
SELECT * 
FROM PortfolioProject..CovidDeaths$ dea
JOIN  PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date;

---Looking at total population vs vaccinations in France

SELECT dea.continent, dea.location, dea.date, dea.population as population, vac.new_vaccinations AS vaccination, ROUND((vac.new_vaccinations/dea.population),3)*100 AS PercentageVac
FROM PortfolioProject..CovidDeaths$ dea
JOIN  PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL AND dea.location LIKE 'france'
ORDER BY  date;

--Rolling Count New vaccinations: Use PARTITION BY WINDOW FUNCTIONS
SELECT dea.continent,
dea.location,
dea.date, 
dea.population, 
vac.new_vaccinations AS newvaccinations,
SUM(CAST (vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths$ dea
JOIN  PortfolioProject..CovidVaccinations$ vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.location LIKE 'Albania'
ORDER BY dea.location, dea.date;

---- Using CTE to perform Calculation on Partition By in previous query

WITH PopulationvsVaccines (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopulationvsVaccines


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT  dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	ON dea.location = vac.location
	AND dea.date = vac.date;

SELECT *, ROUND((RollingPeopleVaccinated/Population),3)*100
FROM #PercentPopulationVaccinated
WHERE Continent IS NOT NULL
ORDER BY Continent, Location;

-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths$ dea
JOIN PortfolioProject..CovidVaccinations$ vac
	On dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
