/* 
BONUS 1. How many npi numbers appear in the prescriber table but not in the prescription table?
*/

SELECT 
	COUNT(*) 
FROM prescriber
	LEFT JOIN prescription
		USING (npi)
WHERE prescription.npi IS NULL


/* 
BONUS 2. a. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
*/

SELECT
	generic_name,
	SUM(total_claim_count) AS sum_total_claim_count
FROM prescriber
	INNER JOIN prescription
		USING (npi)
	INNER JOIN drug
		USING (drug_name)
WHERE specialty_description ILIKE 'Family Practice'
GROUP BY generic_name
ORDER BY sum_total_claim_count DESC
LIMIT 5


/* 
BONUS 2. b. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
*/

SELECT
	generic_name,
	COUNT(total_claim_count) AS total_claim_count
FROM prescriber
	INNER JOIN prescription
		USING (npi)
	INNER JOIN drug
		USING (drug_name)
WHERE specialty_description ILIKE 'Cardiology'
GROUP BY generic_name
ORDER BY total_claim_count DESC
LIMIT 5

/* 
BONUS 2. c. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a and b into a single query to answer this question.
*/

SELECT
	generic_name,
	SUM(total_claim_count) AS sum_total_claim_count
FROM prescriber
	INNER JOIN prescription
		USING (npi)
	INNER JOIN drug
		USING (drug_name)
WHERE specialty_description IN ('Family Practice', 'Cardiology')
GROUP BY generic_name
ORDER BY sum_total_claim_count DESC
LIMIT 5

/* 
BONUS 3. Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.
a. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across all drugs. Report the npi, the total number of claims, and include a column showing the city.
*/

SELECT
	prescriber.npi,
	nppes_provider_city,
	SUM(total_claim_count) AS sum_total_claim_count
FROM prescriber
	INNER JOIN prescription
		USING(npi)
WHERE nppes_provider_city ILIKE 'NASHVILLE'
GROUP BY prescriber.npi, nppes_provider_city
ORDER BY sum_total_claim_count DESC
LIMIT 5

/* 
BONUS 3. b. Now, report the same for Memphis.
*/

SELECT
	prescriber.npi,
	nppes_provider_city,
	SUM(total_claim_count) AS sum_total_claim_count
FROM prescriber
	INNER JOIN prescription
		USING(npi)
WHERE nppes_provider_city ILIKE 'MEMPHIS'
GROUP BY prescriber.npi, nppes_provider_city
ORDER BY sum_total_claim_count DESC
LIMIT 5

/* 
BONUS 3. c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
*/

	(SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'NASHVILLE'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5)

UNION

	(SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'MEMPHIS'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5)

UNION

	(SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'Knoxville'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5)

UNION

	(SELECT
		prescriber.npi,
		nppes_provider_city,
		SUM(total_claim_count) AS total_claim_count
	FROM prescriber
		LEFT JOIN prescription
			USING(npi)
	WHERE nppes_provider_city ILIKE 'Chattanooga'
	GROUP BY prescriber.npi, nppes_provider_city
	ORDER BY total_claim_count DESC NULLS LAST
	LIMIT 5)

ORDER BY total_claim_count DESC


/* 
BONUS 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
*/

SELECT
	county,
	overdoses.deaths
FROM overdoses
	LEFT JOIN fips_county
		USING(fipscounty)
WHERE deaths > (SELECT AVG(deaths) FROM overdoses) -- Subquery for avg overdoses.deaths

/* 
BONUS 5. a. Write a query that finds the total population of Tennessee.
*/

SELECT
	state,
	SUM(population) AS total_population
FROM population
	INNER JOIN fips_county 
		USING(fipscounty)
WHERE state ILIKE 'TN'
GROUP BY state

/* 
BONUS 5. b. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population, and the percentage of the total population of Tennessee that is contained in that county.
*/

SELECT
	county,
	100 * -- % of county/TN population
		SUM(population) -- population of each county
		/
		(SELECT -- subquery to get sum.population of TN
		 	SUM(population)	
		 FROM population
			INNER JOIN fips_county 
				USING(fipscounty)
		 WHERE state ILIKE 'TN')
		AS tn_total_population
FROM population
	INNER JOIN fips_county 
		USING(fipscounty)
GROUP BY county