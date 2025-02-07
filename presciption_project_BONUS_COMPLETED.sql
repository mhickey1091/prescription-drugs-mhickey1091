SELECT *
FROM cbsa;

SELECT *
FROM drug;

SELECT *
FROM fips_county;

SELECT *
FROM overdose_deaths;

SELECT *
FROM population;

SELECT *
FROM prescriber;

SELECT *
FROM prescription;

SELECT *
FROM zip_fips;

=================================================================================

-- QUESTION 1. How many npi numbers appear in the prescriber table but not in the prescription table?

SELECT npi
FROM prescriber
EXCEPT
SELECT npi
FROM prescription;

-- 4,458 npi

==================================================================================


-- QUESTION 2.a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.

SELECT specialty_description,
		generic_name, 
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY specialty_description, generic_name
ORDER BY total_claims desc
LIMIT 5

______________________________________________


-- 2.b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.


SELECT specialty_description,
		generic_name, 
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY specialty_description, generic_name
ORDER BY total_claims desc
LIMIT 5

______________________________________________


-- 2.c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.

(SELECT specialty_description,
		generic_name, 
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY specialty_description, generic_name
ORDER BY total_claims desc
LIMIT 5)
UNION
(SELECT specialty_description,
		generic_name, 
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
INNER JOIN drug USING (drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY specialty_description, generic_name
ORDER BY total_claims desc
LIMIT 5);


==================================================================================


-- QUESTION 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.

CREATE TEMP TABLE nashville AS SELECT prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE 'nashville'
GROUP BY prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;


SELECT *
FROM nashville
UNION
SELECT *
FROM memphis
ORDER BY nppes_provider_city;

______________________________________________


-- 3.b. Now, report the same for Memphis.

CREATE TEMP TABLE memphis AS SELECT prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE 'memphis'
GROUP BY prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

______________________________________________


-- 3.c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

(SELECT prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE 'nashville'
GROUP BY prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE 'memphis'
GROUP BY prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE 'chattanooga'
GROUP BY prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
UNION
(SELECT prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription USING (npi)
WHERE nppes_provider_city ILIKE 'knoxville'
GROUP BY prescriber.npi,
		nppes_provider_first_name,
		nppes_provider_last_org_name,
		nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)
ORDER BY nppes_provider_city;

==================================================================================


-- QUESTION 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.

SELECT *
FROM fips_county --- Finding that fips_county table had fipscounty as character varying and wouldn't match up with the fipscounty from overdose_deaths (integer)

SELECT *
FROM overdose_deaths;


SELECT *
FROM fips_county
LEFT JOIN overdose_deaths USING (fipscounty)



SELECT county,
		SUM(overdose_deaths) AS overdose_deaths
FROM overdose_deaths
INNER JOIN fips_county ON overdose_deaths.fipscounty = fips_county.fipscounty::integer -- Joining together and changing the fipscounty to integer
GROUP BY county
HAVING SUM(overdose_deaths) > (SELECT AVG(overdose_deaths)
									FROM overdose_deaths)
ORDER BY overdose_deaths DESC;


==================================================================================


-- QUESTION 5.a. Write a query that finds the total population of Tennessee.

SELECT SUM(population)
FROM fips_county
INNER JOIN population USING (fipscounty);
______________________________________________


-- 5.b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.


WITH tot_pop AS (
				SELECT SUM(population)
				FROM fips_county
				INNER JOIN population USING (fipscounty)
)



SELECT county, 
		SUM(population) AS population,
		ROUND(SUM(population) * 100 / (SELECT SUM(population)
								FROM fips_county
								INNER JOIN population USING (fipscounty)),2) AS per_of_tot_pop
FROM fips_county
INNER JOIN population USING (fipscounty)
GROUP BY county
ORDER BY population DESC;

