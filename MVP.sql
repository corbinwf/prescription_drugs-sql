/* 
1. a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.
*/

SELECT
	npi,
	COUNT(total_claim_count) AS totaled_over_all_drugs
FROM prescription
GROUP BY npi
ORDER BY totaled_over_all_drugs DESC
LIMIT 1


/* 
1. b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims
*/

SELECT
	prescriber.npi,
	prescriber.nppes_provider_first_name,
	prescriber.nppes_provider_last_org_name,
	prescriber.specialty_description,
	COUNT(prescription.total_claim_count) AS totaled_over_all_drugs
FROM prescription
	INNER JOIN prescriber
		USING (npi)
GROUP BY 
	prescriber.npi,
	prescriber.nppes_provider_first_name,
	prescriber.nppes_provider_last_org_name,
	prescriber.specialty_description
ORDER BY totaled_over_all_drugs DESC


/* 
2. a. Which specialty had the most total number of claims (totaled over all drugs)?
*/

SELECT
	prescriber.specialty_description,
	COUNT(prescription.total_claim_count) AS totaled_over_all_drugs
FROM prescriber
	INNER JOIN prescription
		USING (npi)
GROUP BY prescriber.specialty_description
ORDER BY totaled_over_all_drugs DESC
LIMIT 1


/* 
2. b. Which specialty had the most total number of claims for opioids?
*/

SELECT
	prescriber.specialty_description,
	COUNT(prescription.total_claim_count) AS totaled_over_all_drugs
FROM prescriber
	INNER JOIN prescription
		USING (npi)
	INNER JOIN drug
		USING (drug_name)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY prescriber.specialty_description
ORDER BY totaled_over_all_drugs DESC


/* 
2. c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
*/

SELECT
	DISTINCT(prescriber.specialty_description)
FROM prescriber
	LEFT JOIN prescription
		USING (npi)
WHERE prescription.npi IS NULL


/* 
2. d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?
*/

SELECT
	prescriber.specialty_description,
	100 * -- % of opioid claim / total claim count
		SUM(CASE WHEN drug.opioid_drug_flag = 'Y' 
			THEN prescription.total_claim_count 
			ELSE 0 END)
		/ 
		SUM(prescription.total_claim_count) 
		AS pct_of_opioid_claim 
FROM prescriber
	INNER JOIN prescription
		USING (npi)
	INNER JOIN drug
		USING (drug_name)
GROUP BY prescriber.specialty_description
ORDER BY pct_of_opioid_claim DESC


/* 
3. a. Which drug (generic_name) had the highest total drug cost?
*/

SELECT
	generic_name,
	AVG(total_drug_cost) AS sum_total_drug_cost
FROM prescription
	INNER JOIN drug
		USING (drug_name)
GROUP BY generic_name
ORDER BY sum_total_drug_cost DESC


/* 
3. b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
*/

SELECT
	generic_name,
	ROUND(
		AVG(
			(total_drug_cost/total_claim_count) -- total_drug_cost / total_claim_count = cost of drug per count
			*
			(total_30_day_fill_count/30) -- total_30_day_fill_count / 30 = count of drug for 1 day
			)
		, 2) AS cost_per_day -- round up to 2 decimal point
FROM prescription
	INNER JOIN drug
		USING (drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC


/* 
4. a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
*/

SELECT
	drug_name,
	CASE 
		WHEN long_acting_opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END 
		AS drug_type
FROM drug


/* 
4. b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
*/

SELECT
	CASE 
		WHEN long_acting_opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END 
		AS drug_type,
	SUM(total_drug_cost)::money AS total_drug_cost_per_drug_type
FROM drug
	INNER JOIN prescription
		USING (drug_name)
GROUP BY drug_type
ORDER BY total_drug_cost_per_drug_type DESC


/* 
5. a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
*/	

SELECT
	COUNT(DISTINCT(cbsa)) AS count_of_cbsa_in_tn
FROM cbsa
	INNER JOIN fips_county
		USING (fipscounty)
WHERE fips_county.state ILIKE 'TN'


/* 
5. b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
*/

SELECT
	cbsaname,
	SUM(population) AS sum_population
FROM 
	-- Subquery to deduplicate cbsa.fipscounty "06037"
	(SELECT 
	 	DISTINCT(fipscounty) AS dedup_fipscounty, 
	 	cbsaname 
	 FROM cbsa
	) AS dedup_cbsa
	INNER JOIN population
		ON dedup_fipscounty = fipscounty
GROUP BY cbsaname
ORDER BY sum_population DESC


/* 
5. c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
*/

SELECT
	county,
	SUM(population) AS sum_population
FROM 
	-- Subquery to deduplicate cbsa.fipscounty "06037"
	(SELECT 
	 	DISTINCT(fipscounty) AS dedup_fipscounty, 
	 	cbsaname 
	 FROM cbsa
	) AS dedup_cbsa
	FULL JOIN population
		ON dedup_fipscounty = fipscounty
	INNER JOIN fips_county
		USING(fipscounty)
WHERE cbsaname IS NULL
GROUP BY county
ORDER BY sum_population DESC


/* 
6. a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
*/

SELECT
	drug_name,
	total_claim_count
FROM prescription
WHERE total_claim_count > 3000


/* 
6. b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
*/

SELECT
	drug_name,
	prescription.total_claim_count,
	drug.opioid_drug_flag
FROM prescription
	INNER JOIN drug
		USING(drug_name)
WHERE 
	total_claim_count > 3000


/* 
6. c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
*/

SELECT
	nppes_provider_first_name,
	nppes_provider_last_org_name,
	drug_name,
	total_claim_count,
	opioid_drug_flag
FROM prescription
	INNER JOIN drug
		USING(drug_name)
	INNER JOIN prescriber
		USING (npi)
WHERE 
	total_claim_count > 3000


/* 
7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
*/


SELECT
	npi,
	drug_name
FROM prescriber
	CROSS JOIN drug
WHERE 
	specialty_description ILIKE 'Pain Management'
	AND nppes_provider_city ILIKE 'Nashville'
	AND opioid_drug_flag = 'Y'


/* 
7. b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
*/

SELECT
	npi,
	drug.drug_name,
	SUM(total_claim_count) AS total_claim_count
FROM prescriber
	CROSS JOIN drug
	INNER JOIN prescription
		USING(npi)
WHERE 
	specialty_description = 'Pain Management'
	AND nppes_provider_city ILIKE 'Nashville'
	AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name



/* 
7. c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
*/

SELECT
	npi,
	drug.drug_name,
	SUM(COALESCE(total_claim_count, 0)) AS total_claim_count
FROM prescriber
	CROSS JOIN drug
	INNER JOIN prescription
		USING(npi)
WHERE 
	prescriber.specialty_description = 'Pain Management'
	AND nppes_provider_city ILIKE 'Nashville'
	AND opioid_drug_flag = 'Y'
GROUP BY npi, drug.drug_name

/* NOTE
5 + null = null?
otherwise it doesn't really do anything other than replacing null to 0
*/


