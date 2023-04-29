-- DATA CLEANSING

	--- Retrieve the first 10 rows from the table
SELECT *
FROM donor_data dd 
LIMIT 10;

	--- Count the total number of rows in the table
SELECT count(*) 
FROM donor_data dd;

	--- Remove irrelevant columns
ALTER TABLE donor_data 
DROP COLUMN email_present_ind,
DROP COLUMN birth_date;

ALTER TABLE donor_data 
DROP COLUMN membership_ind;

ALTER TABLE donor_data 
DROP COLUMN pref_address_type;

ALTER TABLE donor_data 
DROP COLUMN donor_ind;



	--- Check and remove for NA values in the zipcode column
SELECT *
FROM donor_data dd 
WHERE zipcode = 'NA';

DELETE FROM donor_data 
WHERE zipcode = 'NA';

	--- Check for NA values and replace them with ''unknown in the age column
SELECT *
FROM donor_data dd 
WHERE age = 'NA';

UPDATE donor_data 
SET age = 'unknown'
WHERE age = 'NA';

	--- Check for NA values and replace them with ''unknown in the marital_status column
SELECT *
FROM donor_data dd 
WHERE marital_status = 'NA';

UPDATE donor_data 
SET marital_status  = 'unknown'
WHERE marital_status  = 'NA';

	--- Check for NA values and replace them with ''unknown in the gender column
SELECT COUNT(*)
FROM donor_data dd 
WHERE gender = 'NA';

UPDATE donor_data 
SET gender  = 'unknown'
WHERE gender  = 'NA';

	--- Check for NA values in the alumnus column
SELECT COUNT(*)
FROM donor_data dd 
WHERE alumnus_ind  = 'NA';


	--- Check for NA values in the parent column
SELECT COUNT(*)
FROM donor_data dd 
WHERE parent_ind  = 'NA';

	--- Check for NA values in the parent column
SELECT COUNT(*)
FROM donor_data dd 
WHERE has_involvement_ind  = 'NA';

	--- Check for NA values and replace them with ''unknown in the wealth_rating column
SELECT COUNT(*)
FROM donor_data dd 
WHERE wealth_rating  = 'NA';

UPDATE donor_data 
SET wealth_rating  = 'unknown'
WHERE wealth_rating  = 'NA';


	--- Check for NA values and replace them with ''unknown in the degree column
SELECT COUNT(*)
FROM donor_data dd 
WHERE degree_level  = 'NA';

UPDATE donor_data 
SET degree_level  = 'unknown'
WHERE degree_level  = 'NA';



	--- check for duplicate rows in the table
SELECT 
	DISTINCT *
FROM donor_data dd 
GROUP BY id, zipcode ,age , marital_status , gender , alumnus_ind , parent_ind , has_involvement_ind , wealth_rating ,
		degree_level , con_years , prevfygiving , prevfy1giving , prevfy2giving , prevfy3giving , prevfy4giving , 
		currfygiving , totalgiving 
HAVING count(*) >1;



	--- transfer data type from varchar to integer
ALTER TABLE donor_data 
ADD COLUMN currfygiving_int INTEGER,
ADD COLUMN prevfygiving_int INTEGER,
ADD COLUMN prevfy1giving_int INTEGER,
ADD COLUMN prevfy2giving_int INTEGER,
ADD COLUMN prevfy3giving_int INTEGER,
ADD COLUMN prevfy4giving_int INTEGER;

UPDATE donor_data 
SET currfygiving_int = CAST(REPLACE(REPLACE(currfygiving, ',', ''), '$', '') AS INTEGER),
	prevfygiving_int = CAST(REPLACE(REPLACE(prevfygiving, ',', ''), '$', '') AS INTEGER),
	prevfy1giving_int = CAST(REPLACE(REPLACE(prevfy1giving, ',', ''), '$', '') AS INTEGER),
	prevfy2giving_int = CAST(REPLACE(REPLACE(prevfy2giving, ',', ''), '$', '') AS INTEGER),
	prevfy3giving_int = CAST(REPLACE(REPLACE(prevfy3giving, ',', ''), '$', '') AS INTEGER),
	prevfy4giving_int = CAST(REPLACE(REPLACE(prevfy4giving, ',', ''), '$', '') AS INTEGER);




	--- save the cleaned data to a new table 


CREATE TABLE cleaned_donor_data AS
	SELECT *
	FROM donor_data dd;


	-- DATA ANALYSIS


--- How many donors in the current financial year? 
SELECT 
	DISTINCT COUNT(id)
FROM cleaned_donor_data cdd 
WHERE currfygiving_int > 0; 


--- Get the total donation for the current financial YEAR

SELECT SUM(currfygiving_int)
FROM cleaned_donor_data cdd 



--- Get the distribution of donations for the current financial year
SELECT currfygiving_int, COUNT(*) as count
FROM cleaned_donor_data cdd 
GROUP BY currfygiving_int
ORDER BY currfygiving_int DESC;



--- What is the average donation amount per donor in the current fiscal year?

SELECT AVG(currfygiving_int) AS avg_donation_per_donor
FROM cleaned_donor_data cdd
WHERE currfygiving_int <> 0;

--- What is the average and median age of donors? 


SELECT AVG(CAST(age AS INTEGER)) AS avg_donor_age
FROM cleaned_donor_data cdd 
WHERE currfygiving_int <> 0 AND age <> 'unknown'; 


SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY CAST(age AS INTEGER)) AS median_donor_age
FROM cleaned_donor_data
WHERE currfygiving_int <> 0 AND age <> 'unknown';


--- How many donors are alumni in the current financial year?

SELECT COUNT(id)
FROM cleaned_donor_data cdd 
WHERE alumnus_ind = 'Y' AND currfygiving_int <> 0;


--- How many donors are parents of current or past students in the current financial year?
SELECT COUNT(id)
FROM cleaned_donor_data cdd 
WHERE parent_ind = 'Y' AND currfygiving_int <> 0;


--- What is the distribution of degree levels among donors in the current financial year?
SELECT 	
	degree_level,
	COUNT(*) AS count
FROM cleaned_donor_data cdd 
WHERE currfygiving_int <> 0
GROUP BY degree_level 
ORDER BY count DESC;


--- What is the distribution of gender among donors in the current financial year?

UPDATE cleaned_donor_data
SET gender = 'Unknown'
WHERE gender IN ('Uknown', 'unknown', 'Unknown');


SELECT 	
	gender,
	COUNT(*) AS count
FROM cleaned_donor_data cdd 
WHERE currfygiving_int <> 0
GROUP BY gender 
ORDER BY count DESC;


--- What is the distribution of wealth ratings among donors?
SELECT wealth_rating, COUNT(*) AS count
FROM cleaned_donor_data
WHERE currfygiving_int <> 0
GROUP BY wealth_rating
ORDER BY count DESC;


--- which wealth rating group donated the most?
SELECT wealth_rating, SUM(currfygiving_int) AS total_donation_amount
FROM cleaned_donor_data cdd 
WHERE currfygiving_int <> 0
GROUP BY wealth_rating
ORDER BY total_donation_amount DESC;

--- What is the distribution of marital status among donors in the current financial year?
SELECT 	
	marital_status ,
	COUNT(*) AS count
FROM cleaned_donor_data cdd 
WHERE currfygiving_int <> 0
GROUP BY marital_status 
ORDER BY count DESC;

--- How many donors have given to our organization for two or more consecutive years?

 SELECT
  	id,zipcode ,
  	marital_status ,
  	gender, alumnus_ind ,
  	parent_ind , 
  	has_involvement_ind ,
  	degree_level,
  	(currfygiving_int +prevfygiving_int) AS total_giving_two_years
  FROM cleaned_donor_data dd
  WHERE currfygiving_int > 0 AND prevfygiving_int > 0
  ORDER BY total_giving_two_years DESC;



-- How many donors have given to our organization for six consecutive years?

  SELECT
  	id,zipcode , marital_status ,gender, alumnus_ind , parent_ind , has_involvement_ind , degree_level,
  	(currfygiving_int +prevfygiving_int +prevfy1giving_int +prevfy2giving_int +prevfy3giving_int +prevfy4giving_int) AS total_giving_six_years
  FROM cleaned_donor_data dd
  WHERE currfygiving_int > 0
  AND prevfygiving_int > 0
  AND prevfy1giving_int > 0
  AND prevfy2giving_int > 0
  AND prevfy3giving_int > 0
  AND prevfy4giving_int > 0
  ORDER BY total_giving_six_years DESC;

--- What is the donor retention rate? (divide the number of repeat donors this year by those that donated last year)
 
SELECT
	COUNT(DISTINCT CASE WHEN prevfygiving_int > 0 THEN id END) AS num_prev_donor,
	COUNT(DISTINCT CASE WHEN prevfygiving_int > 0 AND currfygiving_int > 0 THEN id END) AS num_repeat_donor,
	ROUND(COUNT(DISTINCT CASE WHEN prevfygiving_int > 0 AND currfygiving_int > 0 THEN id END)/ COUNT(DISTINCT CASE WHEN prevfygiving_int > 0 THEN id END):: NUMERIC, 2) AS retention_rate
FROM cleaned_donor_data cdd;

 
--- Calculate the difference in the total amount of donations for the past six years
 
SELECT 
	SUM(currfygiving_int) AS total_currfygiving,
	SUM(prevfygiving_int) AS total_prevfygiving,
	SUM(prevfy1giving_int) AS total_currfy1giving,
	SUM(prevfy2giving_int) AS total_currfy2giving,
	SUM(prevfy3giving_int) AS total_currfy3giving,
	SUM(prevfy4giving_int) AS total_currfy4giving
FROM cleaned_donor_data cdd 


--- Remove irrelevant columns to get the data ready for visualisation
ALTER TABLE cleaned_donor_data 
DROP COLUMN con_years,
DROP COLUMN prevfygiving,
DROP COLUMN prevfy1giving,
DROP COLUMN prevfy2giving,
DROP COLUMN prevfy3giving,
DROP COLUMN prevfy4giving,
DROP COLUMN currfygiving,
DROP COLUMN totalgiving;










 
