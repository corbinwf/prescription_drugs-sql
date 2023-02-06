/* 1. 
a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
*/

-- SELECT * FROM prescription
-- SELECT COUNT(DISTINCT(npi)) FROM prescription

SELECT
	npi,
	SUM(total_claim_count) AS totaled_over_all_drugs
FROM prescription
GROUP BY npi
ORDER BY totaled_over_all_drugs DESC
--LIMIT 1


/* 1.
b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims
*/

SELECT
	prescription.npi,
	prescriber.nppes_provider_first_name,
	prescriber.nppes_provider_last_org_name,
	prescriber.specialty_description,
	SUM(prescription.total_claim_count) AS totaled_over_all_drugs
FROM prescription
	LEFT JOIN prescriber
		USING (npi)
GROUP BY 
	npi,
	prescriber.nppes_provider_first_name,
	prescriber.nppes_provider_last_org_name,
	prescriber.specialty_description
ORDER BY totaled_over_all_drugs DESC


/* 2. 
a. Which specialty had the most total number of claims (totaled over all drugs)?
*/

SELECT
	prescriber.specialty_description,
	SUM(prescription.total_claim_count) AS totaled_over_all_drugs
FROM prescription
	LEFT JOIN prescriber
		USING (npi)
GROUP BY prescriber.specialty_description
ORDER BY totaled_over_all_drugs DESC
--LIMIT 1


/* 2.
b. Which specialty had the most total number of claims for opioids?
*/

-- SELECT * FROM prescription
-- SELECT DISTINCT(opioid_drug_flag) FROM drug

SELECT
	prescriber.specialty_description,
	SUM(prescription.total_claim_count) AS totaled_over_all_drugs
FROM prescription
	LEFT JOIN prescriber
		USING (npi)
	LEFT JOIN drug
		USING (drug_name)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY totaled_over_all_drugs DESC


/* 2.
c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
*/

-- SELECT * FROM prescriber
-- SELECT * FROM prescription

SELECT
	prescriber.specialty_description
FROM prescriber
	LEFT JOIN prescription
		USING (npi)
WHERE prescription.npi IS NULL


/* 2.
d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
*/

SELECT
	prescriber.specialty_description,
	SUM(CASE WHEN drug.opioid_drug_flag = 'Y' THEN prescription.total_claim_count ELSE 0 END)/SUM(prescription.total_claim_count)	AS pct_of_opioid_per_total_claim
FROM prescription
	LEFT JOIN prescriber
		USING (npi)
	LEFT JOIN drug
		USING (drug_name)
GROUP BY prescriber.specialty_description
ORDER BY pct_of_opioid_per_total_claim DESC


/* 3. 
a. Which drug (generic_name) had the highest total drug cost?
*/

-- SELECT * FROM prescription

SELECT
	drug_name,
	total_drug_cost
FROM prescription
	LEFT JOIN drug
		USING (drug_name)
ORDER BY total_drug_cost DESC

/* 2.
b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
*/

-- SELECT * FROM prescription

SELECT
	drug_name,
	ROUND(AVG(total_drug_cost/total_day_supply), 2) AS cost_per_day
FROM prescription
GROUP BY drug_name
ORDER BY cost_per_day DESC


/* 4. 
a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
*/

-- SELECT * FROM drug

SELECT
	drug_name,
	CASE 
		WHEN long_acting_opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' 
		END AS drug_type
FROM drug


/* 4.
b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
*/

SELECT
	CASE 
		WHEN long_acting_opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' 
		END AS drug_type,
	AVG(total_drug_cost)::money AS avg_total_drug_cost_per_drug_type
FROM drug
	LEFT JOIN prescription
		USING (drug_name)
GROUP BY drug_type
ORDER BY avg_total_drug_cost_per_drug_type DESC


/* 5. 
a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
*/	

--SELECT * FROM cbsa
--SELECT DISTINCT(cbsa) FROM cbsa
-- SELECT * FROM fips_county

SELECT
	COUNT(DISTINCT(cbsa)) AS count_of_cbsa_in_tn
FROM cbsa
	LEFT JOIN fips_county
	USING (fipscounty)
WHERE fips_county.state ILIKE 'TN'


/* 5.
b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
*/

-- SELECT * FROM cbsa
-- SELECT COUNT(*) FROM cbsa -- 1238
-- SELECT COUNT(DISTINCT(fipscounty)) FROM cbsa -- 1237
-- SELECT COUNT(*) FROM cbsa WHERE fipscounty IS NULL -- 0
-- SELECT fipscounty FROM cbsa GROUP BY fipscounty HAVING COUNT(DISTINCT(fipscounty)) > 1
-- SELECT * FROM cbsa WHERE fipscounty ILIKE '06037'
-- "06037""06037"
-- SELECT * FROM cbsa LEFT JOIN population USING(fipscounty)
-- SELECT * FROM public.population

/* NOTE
There is duplicate fipscounty in cbsa table
06037
*/

SELECT
	cbsaname,
	SUM(population) AS combined_population
FROM 
	(SELECT 
	 	DISTINCT(fipscounty) AS dedup_fipscounty, 
	 	cbsaname 
	 FROM cbsa
	) AS dedup_cbsa
	LEFT JOIN population
		ON dedup_cbsa.dedup_fipscounty = population.fipscounty
GROUP BY cbsaname
ORDER BY combined_population DESC NULLS LAST


/* 5.
c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
*/

-- SELECT * FROM population ORDER BY population DESC
-- SELECT * FROM cbsa

SELECT
	county,
	SUM(population) AS combined_population
FROM population
	LEFT JOIN 
		(SELECT 
			DISTINCT(fipscounty) AS dedup_fipscounty,
			cbsaname 
		 FROM cbsa
		) AS dedup_cbsa
		ON dedup_cbsa.dedup_fipscounty = population.fipscounty
	LEFT JOIN fips_county
		USING(fipscounty)
WHERE cbsaname IS NULL
GROUP BY county
ORDER BY combined_population DESC NULLS LAST


/* 6. 
a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
*/

-- SELECT * FROM prescription WHERE total_claim_count > 3000

SELECT
	drug_name,
	total_claim_count
FROM prescription
WHERE total_claim_count > 3000


/* 6.
b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
*/

SELECT
	drug_name,
	total_claim_count,
	opioid_drug_flag
FROM prescription
	LEFT JOIN drug
		USING(drug_name)
WHERE 
	total_claim_count > 3000


/* 6.
c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
*/

SELECT
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	drug_name,
	total_claim_count,
	opioid_drug_flag
FROM prescription
	LEFT JOIN drug
		USING(drug_name)
	LEFT JOIN prescriber
		USING (npi)
WHERE 
	total_claim_count > 3000


/* 7. 
The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
*/

-- SELECT DISTINCT(specialty_description) FROM prescriber WHERE specialty_description ILIKE '%pain%'
-- SELECT * FROM prescriber
-- SELECT * FROM drug

SELECT
	npi,
	drug_name
FROM prescriber
	CROSS JOIN drug
WHERE 
	prescriber.specialty_description = 'Pain Management'
	AND nppes_provider_city ILIKE 'Nashville'
	AND opioid_drug_flag = 'Y'


/* 7.
b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
*/

SELECT
	prescriber.npi,
	drug_name,
	SUM(total_claim_count) AS total_claim_count
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription
		USING(drug_name)
WHERE 
	prescriber.specialty_description = 'Pain Management'
	AND nppes_provider_city ILIKE 'Nashville'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug_name



/* 7.
c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
*/

SELECT
	prescriber.npi,
	drug_name,
	SUM(COALESCE(total_claim_count, 0)) AS total_claim_count
FROM prescriber
	CROSS JOIN drug
	LEFT JOIN prescription
		USING(drug_name)
WHERE 
	prescriber.specialty_description = 'Pain Management'
	AND nppes_provider_city ILIKE 'Nashville'
	AND opioid_drug_flag = 'Y'
GROUP BY prescriber.npi, drug_name

/* NOTE
5 + null = null?
otherwise it doesn't really do anything other than replacing null to 0
*/


/* BONUS 1. 
How many npi numbers appear in the prescriber table but not in the prescription table?
*/

SELECT 
	COUNT(*) 
FROM prescriber
	LEFT JOIN prescription
		USING (npi)
WHERE prescription.npi IS NULL


/* BONUS 2.
a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
*/

SELECT
	generic_name,
	COUNT(total_claim_count) AS total_claim_count
FROM prescriber
	LEFT JOIN prescription
		USING (npi)
	LEFT JOIN drug
		USING (drug_name)
WHERE specialty_description ILIKE 'Family Practice'
GROUP BY generic_name
ORDER BY total_claim_count DESC

/* BONUS 2.
b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
*/

SELECT
	generic_name,
	COUNT(total_claim_count) AS total_claim_count
FROM prescriber
	LEFT JOIN prescription
		USING (npi)
	LEFT JOIN drug
		USING (drug_name)
WHERE specialty_description ILIKE 'Cardiology'
GROUP BY generic_name
ORDER BY total_claim_count DESC

/* BONUS 2.
c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
*/

SELECT
	generic_name,
	COUNT(total_claim_count) AS total_claim_count
FROM prescriber
	LEFT JOIN prescription
		USING (npi)
	LEFT JOIN drug
		USING (drug_name)
WHERE specialty_description IN ('Family Practice', 'Cardiology')
GROUP BY generic_name
ORDER BY total_claim_count DESC

/* BONUS 3. 
Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
*/

SELECT
	prescriber.npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claim_count
FROM prescriber
	LEFT JOIN prescription
		USING(npi)
WHERE nppes_provider_city ILIKE 'NASHVILLE'
GROUP BY prescriber.npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5

/* BONUS 3. 
b. Now, report the same for Memphis.
*/

SELECT
	prescriber.npi,
	nppes_provider_city,
	SUM(total_claim_count) AS total_claim_count
FROM prescriber
	LEFT JOIN prescription
		USING(npi)
WHERE nppes_provider_city ILIKE 'MEMPHIS'
GROUP BY prescriber.npi, nppes_provider_city
ORDER BY total_claim_count DESC NULLS LAST
LIMIT 5

/* BONUS 3. 
c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
*/

(
	SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'NASHVILLE'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5
)
UNION
(
	SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'MEMPHIS'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5
)
UNION
(
	SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'Knoxville'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5
)
UNION
(
	SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'Chattanooga'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5
)
ORDER BY total_claim_count DESC


/* BONUS 4. 
Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
*/

SELECT
	county,
	CASE WHEN deaths > AVG(deaths) THEN deaths ELSE 0 END AS deaths_count
FROM overdoses
	LEFT JOIN fips_county
		USING(fipscounty)
GROUP BY county
ORDER BY deaths_count DESC

/* BONUS 5.
a. Write a query that finds the total population of Tennessee.
*/

SELECT
	state,
	SUM(population) AS total_population
FROM population
	LEFT JOIN fips_county 
		USING(fipscounty)
WHERE state ILIKE 'TN'
GROUP BY state

/* BONUS 5.
b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
*/

SELECT
	county,
	SUM(population)/
	SUM(population) AS county_total_population
FROM population
	LEFT JOIN fips_county 
		USING(fipscounty)
WHERE state ILIKE 'TN'