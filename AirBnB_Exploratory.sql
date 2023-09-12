
--	1. investigate NULLs in all columns

select *
from AirBnB.dbo.listingsDec22$
where review_scores_rating is null              ----> Change for each column

-- bedrooms column: 287 rows NULLs (immaterial)
-- beds column: 53 rows NULLs (immaterial)

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 2. Check for duplicate ids

select id, count(*) as Id_count
from AirBnB.dbo.listingsDec22$                  
group by id
order by Id_count desc

-- Immaterial minor number of duplicate id's for each scrape. The duplicates are actually different listings, likely human or technical error.  Will not materially impact the analysis.

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 3. High level information on composition (Dec table provides sufficient data)

--  a) Neighbourhood AirBnB density
	
Select neighbourhood_cleansed 
		,count(*) as AirBnb_Listings
		,(count(*) * 100) / sum(count(*)) over () AS Percent_of_Total
From AirBnB.dbo.listingsDec22$
Group By neighbourhood_cleansed
order by AirBnb_Listings desc

-- Point Nepean accounts for 50% of all listings, second most listings is Rosbud - McCrae 15%.  The suburbs with the highest listing (Point Nepean, Rosebud, Dromana, Mount Martha, Flinders) account for 90%
-- of all listings.

-- b) Accomodation capacity counts

Select accommodates 
		,count(*) as Accomodation_Count
		,(count(*) * 100) / sum(count(*)) over () AS Percent_of_Total
From AirBnB.dbo.listingsDec22$
Group By accommodates
order by Accomodation_Count desc

-- 51% of all listings accommodate 8 - 10
-- 80% of all listing accomodate 2 - 10

-- c) Accomodation capacity for top three neighbourhoods

Select accommodates 
		,count(*) as Accomodation_Count
		,(count(*) * 100) / sum(count(*)) over () AS Percent_of_Total
From AirBnB.dbo.listingsDec22$
where neighbourhood_cleansed = 'Dromana'                               ----> Alternate between Point Nepean, Rosbud - McCrae, Rosebud
Group By accommodates
order by Accomodation_Count desc

-- All three neighbourhoods have similar accommodation number composition

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 4. Correlation of accomodation capacity and price for highest listing three neighbourhoods

Select accommodates, AVG(Price) AS avg_price
From AirBnB.dbo.listingsDec22$
group by accommodates
order by accommodates

-- Average price does generally increase as accomodation capacity inceases.
-- Accomodates = 1 is not in line with this trend, showing a far higher avg price than the highest accommodation capacity.

select id, accommodates, price, neighbourhood_cleansed
From AirBnB.dbo.listingsDec22$
where accommodates = 1 

-- Two records which well above the others exist, likely need to be excluded if any further analysis is done for this segment.
-- One of those records has a price of $9999, which is unrealistic, remove  in any future analysis

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 5. Join data to include consolidate 12 months

---- Each data set is scraped every three months. Four of the datasets have been joined below, they include September 22, December 22, March 23, and June 23. This allows analysis of the data for seasonal differences


With CTE_AirBnB as
(
Select id, scrape_id, case when cast(left(scrape_id,7) as varchar) = '2.02209' then 'Sept22' else 'NA' end as Scrape_Month_Year, 1 as scrape_num 
,neighbourhood_cleansed, host_name, property_type, room_type, accommodates, bedrooms, beds, amenities, price, minimum_nights, availability_30, availability_60, availability_90, availability_365, number_of_reviews
,review_scores_rating, review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_value, calculated_host_listings_count, reviews_per_month

From AirBnB.dbo.listingsSep22$

Union all 

Select id, scrape_id, case when cast(left(scrape_id,7) as varchar) = '2.02212' then 'Dec22' else 'NA' end as Scrape_Month_Year, 2 as scrape_num 
,neighbourhood_cleansed, host_name, property_type, room_type, accommodates, bedrooms, beds, amenities, price, minimum_nights, availability_30, availability_60, availability_90, availability_365, number_of_reviews
,review_scores_rating, review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_value, calculated_host_listings_count, reviews_per_month

From AirBnB.dbo.listingsDec22$

Union all

Select id, scrape_id ,case when cast(left(scrape_id,7) as varchar) = '2.02303' then 'Mar23' else 'NA' end as Scrape_Month_Year, 3 as scrape_num
,neighbourhood_cleansed, host_name, property_type, room_type, accommodates, bedrooms, beds, amenities, price, minimum_nights, availability_30, availability_60, availability_90, availability_365, number_of_reviews
,review_scores_rating, review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_value, calculated_host_listings_count, reviews_per_month

From AirBnB.dbo.listingsMar23$

Union all

Select id, scrape_id, case when cast(left(scrape_id,7) as varchar) = '2.02306' then 'Jun23' else 'NA' end as Scrape_Month_Year, 4 as scrape_num
,neighbourhood_cleansed, host_name, property_type, room_type, accommodates, bedrooms, beds, amenities, price, minimum_nights, availability_30, availability_60, availability_90, availability_365, number_of_reviews
,review_scores_rating, review_scores_cleanliness, review_scores_checkin, review_scores_communication, review_scores_value, calculated_host_listings_count, reviews_per_month
From AirBnB.dbo.listingsJune23$
)

----select *
----from CTE_AirBnB

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


-- 6. Look at average daily price and number of days available over the next 30 days: Provides revenue expectation summary 

-- a) All four scrapes which consolidates September 22, December 22, March 23, and June 23 (Includes all seasons)

-- select neighbourhood_cleansed
--		,Round(AVG(price),0) AS Average_Price
--		,Round(AVG(availability_30),0) AS available_next30Days
--from CTE_AirBnB
--group by neighbourhood_cleansed
--order by Average_Price desc

-- b) Peak Season - Summer (Scraped Dec22)

--select neighbourhood_cleansed
--		,Round(AVG(price),0) AS Average_Price
--		,Round(AVG(30 - availability_30),0) AS Booked_Next30Days
--		,Round(AVG(30 -availability_30) / 30, 2) * 100 AS Perc_Booked_Next30days
--from CTE_AirBnB
--where Scrape_Month_Year = 'Dec22'
--group by neighbourhood_cleansed
--order by Average_Price desc

-- c) Off-Peak Season - Winter (June23)

--select neighbourhood_cleansed
--		,Round(AVG(price),0) AS Average_Price
--		,Round(AVG(30 - availability_30),0) AS Booked_Next30Days
--		,Round(AVG(30 -availability_30) / 30, 2) * 100 AS Perc_Booked_Next30days
--from CTE_AirBnB
--where Scrape_Month_Year = 'Jun23'
--group by neighbourhood_cleansed
--order by Average_Price desc

--    Insight: Average prices are reduced 15% - 25% in June relative to Dec across each state. Rosebud - McCrae is an outlier, average price reduced only 3%. Rosebud - MCcrae is the neigbourhood with the lowest average price in Dec.

-- d) Pivot of all average prices


select * From
(
select neighbourhood_cleansed, Price, Scrape_num, Scrape_Month_Year
from CTE_AirBnB
) a
PIVOT
(
AVG(Price)
FOR neighbourhood_cleansed IN (
	[Mount Martha],
	[flinders],
	[Point Nepean],
	[Mount Eliza],
	[Somerville],
	[Dromana],
	[Hastings - Somers],
	[Mornington - West],
	[Mornington - East],
	[Rosebud - McCrae])
) AS pivot_t;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 7. AVG / MIN / MAX prices for the peak December period by acccomodation capacity and neighbourhood

With CTE_AirBnB_Dec22 AS
(
select neighbourhood_cleansed
		, CASE WHEN accommodates >= 1 AND accommodates <= 3  THEN '1 - 3'
				WHEN accommodates >= 4 AND accommodates <= 6 THEN '4 - 6'
				WHEN accommodates >= 7 AND accommodates <= 9 THEN '7 - 9'
				WHEN accommodates >= 10 AND accommodates <= 12 THEN '10 - 12'
				WHEN accommodates >= 13 AND accommodates <= 16 THEN '13 - 16'
				Else 'Above 16'
				End as 'Capacity'
		, price
		, accommodates
from AirBnB.dbo.listingsDec22$
)

--  a) Average price by accommodation capacity

select * From
(
select neighbourhood_cleansed, Price,
case when Capacity = '1 - 3' then 1
	 when Capacity = '4 - 6' then 2
	 when Capacity = '7 - 9' then 3
	 when Capacity = '10 - 12' then 4
	 when Capacity = '13 - 16' then 5
	 else 0
END AS 'Row_Order'
,Capacity
from CTE_AirBnB_Dec22
) a
PIVOT
(
AVG(Price)
FOR neighbourhood_cleansed IN (
	[Mount Martha],
	[flinders],
	[Point Nepean],
	[Mount Eliza],
	[Somerville],
	[Dromana],
	[Hastings - Somers],
	[Mornington - West],
	[Mornington - East],
	[Rosebud - McCrae])
) AS pivot_t
Order by Row_Order;



--  b) MIN/MAX price by capacity


With CTE_AirBnB_Dec22 AS
(
select neighbourhood_cleansed
		, CASE WHEN accommodates >= 1 AND accommodates <= 3  THEN '1 - 3'
				WHEN accommodates >= 4 AND accommodates <= 6 THEN '4 - 6'
				WHEN accommodates >= 7 AND accommodates <= 9 THEN '7 - 9'
				WHEN accommodates >= 10 AND accommodates <= 12 THEN '10 - 12'
				WHEN accommodates >= 13 AND accommodates <= 16 THEN '13 - 16'
				Else 'Above 16'
				End as 'Capacity'
		, price
		, accommodates
from AirBnB.dbo.listingsDec22$
)

select * From
(
select neighbourhood_cleansed, Price,
case when Capacity = '1 - 3' then 1
	 when Capacity = '4 - 6' then 2
	 when Capacity = '7 - 9' then 3
	 when Capacity = '10 - 12' then 4
	 when Capacity = '13 - 16' then 5
	 else 0
END AS 'Row_Order'
,Capacity
from CTE_AirBnB_Dec22
) a
PIVOT
(
MAX(Price)                         ---> Alternate MIN or MAX 
FOR neighbourhood_cleansed IN (
	[Mount Martha],
	[flinders],
	[Point Nepean],
	[Mount Eliza],
	[Somerville],
	[Dromana],
	[Hastings - Somers],
	[Mornington - West],
	[Mornington - East],
	[Rosebud - McCrae])
) AS pivot_t
Order by Row_Order;

-- The spread between MIN/MAX is significant. Recommend to plot these as a scatterplot or boxplot to find any outliers, check url if legitimate.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 8. Hosts with most listings - Top 10

Select distinct(host_id), host_name, calculated_host_listings_count
from AirBnB.dbo.listingsDec22$
order by calculated_host_listings_count desc

-- Hosts with most listings in top 20 seem to be commercial with listings of 40+

-- 9. Top 20 earners

SELECT Top 20 id, listing_url, name, host_name, 30 - availability_30 AS booked_out_30 , 
CAST (Price as int) AS price_clean, 
CAST (Price as int)*(30 - availability_30) AS proj_rev_30
FROM AirBnB.dbo.listingsDec22$
ORDER BY proj_rev_30 DESC

-- The top 20 earners forecast revenue greater than $75k over the next 30 days during the peak season.




 














