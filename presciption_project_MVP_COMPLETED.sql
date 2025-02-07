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

-- Look into the duplicates in the drug_name from the drug table..

WITH duplicate_count_table AS (
							SELECT drug_name, COUNT(drug_name) AS duplicate_count
							FROM drug
							GROUP BY drug_name
							HAVING COUNT(drug_name) > 1
							ORDER BY duplicate_count DESC)
--
SELECT *
FROM duplicate_count_table -- This is to see the counts of each duplicated drug_name.

___________________________________________________

-- The IN in the WHERE selects all drug_names that match the subquery.
SELECT *
FROM drug
WHERE drug_name IN (
					SELECT drug_name  -- This is a way to explore all the info on the duplicates instead of a count.
    				FROM drug
    				GROUP BY drug_name 
    				HAVING COUNT(drug_name) > 1)
ORDER BY drug_name;


====================================================================================================================

-- For this exericse, you'll be working with a database derived from the Medicare Part D Prescriber Public Use File. More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

====================================================================================================================

-- ATTENTION!!!!
-- There is duplication in the drugs table. Run 'SELECT COUNT(drug_name) FROM drug' then 'SELECT COUNT (DISTINCT drug_name) FROM drug'. Notice the difference? You can investigate further and then be sure to consider the duplication when joining to the drug table.

====================================================================================================================

-- QUESTION 1.a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT 
	DISTINCT npi,
	nppes_provider_first_name as first_name,
	nppes_provider_last_org_name as last_name,
	SUM(total_claim_count) as num_of_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name
ORDER BY num_of_claims desc;

--------------------------------------------------

SELECT SUM(total_claim_count) AS total_number_of_claims, pr.npi, pr.nppes_provider_last_org_name AS last_name, pr.nppes_provider_first_name AS first_name
FROM prescriber as pr LEFT JOIN prescription AS pn ON pr.npi = pn.npi
WHERE total_claim_count IS NOT NULL
AND drug_name IS NOT NULL
GROUP BY pr.npi, last_name, first_name
ORDER BY total_number_of_claims DESC;

-- Bruce Pendley had the highest total number of claims with 99,707 total claims

SELECT DISTINCT npi
FROM prescriber 
EXCEPT 
SELECT DISTINCT npi FROM prescription;-- 4458 prescribers have no related values in prescription

_____________________________________________________________

-- 1.b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT 
	DISTINCT npi,
	nppes_provider_first_name as first_name,
	nppes_provider_last_org_name as last_name,
	specialty_description,
	SUM(total_claim_count) as num_of_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
GROUP BY npi, nppes_provider_first_name, nppes_provider_last_org_name, specialty_description
ORDER BY num_of_claims desc;

====================================================================================================================

-- QUESTION 2.a. Which specialty had the most total number of claims (totaled over all drugs)?

SELECT *
FROM prescriber
INNER JOIN prescription
	USING (npi)
ORDER BY nppes_provider_last_org_name;

SELECT
	specialty_description,
	SUM(total_claim_count) as num_of_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
WHERE total_claim_count IS NOT NULL
GROUP BY specialty_description
ORDER BY num_of_claims desc;

-- Family Practice had the most claims

_____________________________________________________________

-- 2.b. Which specialty had the most total number of claims for opioids?

SELECT
	specialty_description,
	SUM(total_claim_count) AS num_of_opioid_claims
FROM prescriber
INNER JOIN prescription
	USING (npi)
WHERE drug_name IN 
	(SELECT DISTINCT drug_name
	FROM drug
	WHERE opioid_drug_flag = 'Y') --this is the subquery taking distinct drug names from the drug table (not duplicates)
GROUP BY specialty_description
ORDER BY num_of_opioid_claims desc;

(SELECT DISTINCT drug_name
FROM drug
WHERE opioid_drug_flag = 'Y'); -- This is the subquery for the above formula

-- Nurse Practitioner

_____________________________________________________________

-- 2.c. Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?

SELECT specialty_description
FROM prescriber AS p1
LEFT JOIN prescription AS p2 ON p1.npi = p2.npi
GROUP BY specialty_description
HAVING MAX(p2.npi) IS NULL
ORDER BY specialty_description;

SELECT distinct p1.specialty_description
FROM prescriber AS p1
EXCEPT
SELECT distinct p2.specialty_description
FROM prescriber AS p2
INNER JOIN prescription AS pr
USING(npi)
ORDER BY specialty_description;

_____________________________________________________________

-- 2.d. Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?

--This was the first iteration but didn't take into account duplicate drug_names with different opioid Y/N
SELECT 
	specialty_description,
	COALESCE(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END),0) AS opioid_claims,
	SUM(total_claim_count) AS total_claims,
	COALESCE(ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) * 100 / SUM(total_claim_count),2),0) AS opioid_claims_percent
FROM prescriber
INNER JOIN prescription USING (npi)
INNER JOIN drug USING (drug_name)
GROUP BY specialty_description
ORDER BY opioid_claims_percent desc NULLS LAST;

_____________________________________________________________

-- Final iteration choosing Yes as default for duplicate drug_names.

WITH updated_drugs AS (
					SELECT drug_name, MAX(opioid_drug_flag) AS opioid_y -- This is to take Opioid Y on duplicates
   					FROM drug
    				GROUP BY drug_name)
--
SELECT
    specialty_description,
    COALESCE(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END), 0) AS opioid_claims,
    SUM(total_claim_count) AS total_claims,
    COALESCE(ROUND(SUM(CASE WHEN opioid_drug_flag = 'Y' THEN total_claim_count END) * 100.0 / SUM(total_claim_count), 2), 0) AS opioid_claims_percent
FROM prescriber
INNER JOIN prescription USING (npi)
INNER JOIN updated_drugs USING (drug_name) -- Joining in the CTE to take care of duplicates with different Opioid Y/N
GROUP BY specialty_description
ORDER BY opioid_claims_percent DESC NULLS LAST;


====================================================================================================================

-- QUESTION 3.a. Which drug (generic_name) had the highest total drug cost?

SELECT generic_name, MAX(p.total_drug_cost::money) AS total_drug_cost
FROM prescription AS p
INNER JOIN drug AS d USING (drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;

_____________________________________________________________


-- 3.b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.

SELECT generic_name, MAX((p.total_drug_cost::money) / total_day_supply) AS drug_cost_per_day
FROM prescription AS p
INNER JOIN drug AS d USING (drug_name)
GROUP BY generic_name
ORDER BY drug_cost_per_day DESC;


====================================================================================================================
 
-- QUESTION 4.a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT drug_name,
	MAX(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug
GROUP BY drug_name;

SELECT drug_name,
    STRING_AGG(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
            	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END, ', '  --ANOTHER WAY TO DO IT
    ) AS drug_type
FROM drug
GROUP BY drug_name;

_____________________________________________________________


-- 4.b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

WITH drug_type_table AS (
	SELECT drug_name,
	MAX(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug
GROUP BY drug_name
)
--
SELECT *
FROM drug_type_table;



WITH drug_type_table AS (
	SELECT drug_name,
	MAX(CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic' ELSE 'neither' END) AS drug_type
FROM drug
GROUP BY drug_name
)
SELECT 
    dt.drug_type,
    SUM(p1.total_drug_cost)::money AS total_spent
FROM prescription AS p1
INNER JOIN drug_type_table AS dt ON p1.drug_name = dt.drug_name
WHERE dt.drug_type IN ('opioid', 'antibiotic')
GROUP BY dt.drug_type
ORDER BY total_spent DESC;


====================================================================================================================


-- QUESTION 5.a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.

SELECT DISTINCT cbsa, cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN%';

_____________________________________________________________


-- 5.b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT cbsaname, SUM(population) as population
FROM cbsa
INNER JOIN population USING (fipscounty)
GROUP BY cbsaname
ORDER BY population DESC;

-- Morristown, TN has the lowest population and Nashville-Davidson-Murfreesboro-Franklin, TN has the highest population
_____________________________________________________________


-- 5.c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

--This is creating a CTE combining cbsa, population & fips_county tables.

WITH combined1 AS (
				SELECT county, population
				FROM cbsa
				FULL JOIN population USING (fipscounty)
				FULL JOIN fips_county ON fips_county.county = population.fipscounty)

-- This is creating a CTE combining fips_county & population
WITH combined2 AS (
				SELECT county, population
				FROM fips_county
				FULL JOIN population ON fips_county.county = population.fipscounty)
				
-- This is combining the two with an except to exclude counties that are included in CBSA

WITH combined1 AS (
				SELECT county, population
				FROM cbsa
				LEFT JOIN population USING (fipscounty)
				LEFT JOIN fips_county USING (fipscounty))
--
SELECT county, population
FROM (SELECT fc.county, SUM(population) AS population
		FROM fips_county AS fc
		INNER JOIN population AS p USING (fipscounty)
		GROUP BY county
		ORDER BY population desc)
EXCEPT
SELECT county,population
FROM combined1
ORDER BY population desc;


====================================================================================================================

-- QUESTION 6.a. Find all rows in the prescription table where total_claim_count is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY total_claim_count DESC;

_____________________________________________________________


-- 6.b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.



WITH total_claims1 AS (
					SELECT drug_name, total_claim_count
					FROM prescription
					WHERE total_claim_count >= 3000
					ORDER BY total_claim_count DESC
)
SELECT drug_name, total_claim_count, opioid_drug_flag
FROM total_claims1
INNER JOIN drug USING (drug_name)
ORDER BY opioid_drug_flag;

_____________________________________________________________


-- 6.c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

WITH total_claims1 AS (
					SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count
					FROM prescription
					INNER JOIN prescriber USING (npi)
					WHERE total_claim_count >= 3000
					ORDER BY total_claim_count DESC
)
SELECT nppes_provider_first_name, nppes_provider_last_org_name, drug_name, total_claim_count, opioid_drug_flag
FROM total_claims1
INNER JOIN drug USING (drug_name)
ORDER BY opioid_drug_flag;


====================================================================================================================

-- QUESTION 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- 7.a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y';

_____________________________________________________________


-- 7.b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

WITH new_table AS (SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y')
--
SELECT
	new_table.npi,
	new_table.drug_name,
	total_claim_count
FROM new_table
LEFT JOIN prescription USING (npi,drug_name);

-- OR YOU CAN DO IT THIS WAY BELOW (LAST PART)

WITH new_table AS (SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y')
--
SELECT
	new_table.npi,
	new_table.drug_name,
	total_claim_count
FROM new_table
LEFT JOIN prescription ON new_table.npi = prescription.npi AND new_table.drug_name = prescription.drug_name;


_____________________________________________________________


--7.c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.


WITH new_table AS (SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' AND opioid_drug_flag = 'Y')
--
SELECT
	new_table.npi,
	new_table.drug_name,
	COALESCE (total_claim_count, '0') as claim_count
FROM new_table
LEFT JOIN prescription USING (npi,drug_name)
ORDER BY claim_count DESC;
