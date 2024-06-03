-- Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT 
	npi,
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY nppes_provider_last_org_name, nppes_provider_first_name, npi
ORDER BY SUM(total_claim_count) DESC;

-- Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, specialty_description, and the total number of claims.

SELECT 
	nppes_provider_last_org_name,
	nppes_provider_first_name,
    specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
ORDER BY SUM(total_claim_count) DESC;

--  Which specialty had the most total number of claims (totaled over all drugs)?

SELECT 
    specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC;

-- Which specialty had the most total number of claims for opioids?

SELECT 
    specialty_description, 
	SUM(total_claim_count) AS total_claims
FROM prescriber
INNER JOIN prescription
USING(npi)
INNER JOIN drug
USING (drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY SUM(total_claim_count) DESC;

-- Challenge Question: Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?   

SELECT DISTINCT
	specialty_description 
FROM prescriber
LEFT JOIN prescription
USING(npi)
WHERE total_day_supply IS NULL;

--  Difficult Bonus: Do not attempt until you have solved all other problems! For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?


-- a. Which drug (generic_name) had the highest total drug cost?
SELECT
	generic_name, 
	SUM(total_drug_cost)::money As cost_total
FROM drug
INNER JOIN prescription 
USING(drug_name) 
Group By generic_name
ORDER BY SUM(total_drug_cost) DESC;

-- b. Which drug (generic_name) has the hightest total cost per day? Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works. 

SELECT
	generic_name, 
	ROUND(SUM(total_drug_cost) / SUM(total_day_supply), 2)::money As cost_total_per_day
FROM drug
INNER JOIN prescription 
USING(drug_name) 
Group By generic_name
ORDER BY SUM(total_drug_cost) / SUM(total_day_supply) DESC;


-- a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. Hint: You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
SELECT 
	drug_name,
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE 'neither' END AS drug_type
	FROM drug;

-- b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.

SELECT 
		CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
			 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			 ELSE 'neither' END AS drug_type,
	SUM(total_drug_cost)::money AS total_drug_cost
	FROM drug
INNER JOIN prescription 
USING(drug_name)
GROUP BY drug_type
ORDER BY SUM(total_drug_cost) DESC; 


-- a. How many CBSAs are in Tennessee? Warning: The cbsa table contains information for all states, not just Tennessee.
SELECT 
COUNT(DISTINCT cbsa) AS cbsa_count_TN
FROM cbsa
WHERE cbsaname ILIKE '%TN%';

-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
select * from cbsa;

SELECT 
	cbsaname,
SUM	(population) AS total_pop
FROM cbsa
INNER JOIN population
USING(fipscounty)
WHERE cbsaname ILIKE '%TN'
GROUP BY cbsaname
ORDER BY COUNT(*) DESC;

-- c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT 
	county,
	population
FROM population
LEFT JOIN cbsa
USING(fipscounty)
INNER JOIN fips_county
USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY population DESC;



-- a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT 
	drug_name, 
	total_claim_count
FROM prescription
WHERE total_claim_count > 3000 ;

-- b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT 
	drug_name, 
	total_claim_count,
	opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
WHERE total_claim_count > 3000;  

-- c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT 
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	drug_name, 
	total_claim_count,
	opioid_drug_flag
FROM prescription
INNER JOIN drug
USING (drug_name)
INNER JOIN prescriber
USING (npi)
WHERE total_claim_count > 3000;


-- The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. Hint: The results from all 3 parts will have 637 rows.

-- a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). Warning: Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT 
	npi, drug_name
FROM prescriber
CROSS JOIN
(SELECT 
	drug_name
FROM drug
WHERE opioid_drug_flag = 'Y') AS drugs
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management';


-- b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).


WITH thing AS (SELECT 
	npi, 
	drugs.drug_name
 
FROM prescriber
CROSS JOIN
(SELECT 
	drug_name
FROM drug
WHERE opioid_drug_flag = 'Y') AS drugs
WHERE nppes_provider_city = 'NASHVILLE' AND specialty_description = 'Pain Management')

SELECT  THING.NPI, THING.DRUG_NAME, COALESCE(total_claim_count, 0)
	FROM THING
LEFT JOIN PRESCRIPTION AS p
USING (npi, drug_name)
ORDER BY total_claim_count  DESC;

-- select * from prescription where npi = 11544365 order by npi, drug_name;

-- c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
