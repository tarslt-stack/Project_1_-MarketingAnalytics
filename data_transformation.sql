
---- Query to categorize products based on their price 
 SELECT 
	 ProductID,
	 ProductName,
	 Price,
	 CASE 
		 WHEN Price < 50 THEN 'LOW'
		 WHEN Price BETWEEN 50 AND 200  THEN 'Medium'
		 ELSE 'High'
	 END AS PriceCategory
 FROM dbo.products ;

 ---*************************************************************************

 ---- statement to join dim_customers with dim_geography to enrich customer data with geographic information 
 SELECT 
	 c.CustomerID,
	 c.CustomerName,
	 c.Email,
	 c.Gender,
	 c.Age,
	 g.Country,
	 g.City
 FROM dbo.customers c
 LEFT JOIN 
 dbo.geography g
 ON c.GeographyID = g.GeographyID 

 ----***********************************************************************
  
----Query to clean  whitespace issues in the ReviewText  column 
SELECT 
	ReviewID,
	CustomerID,
	ProductID,
	ReviewDate,
	Rating,
	REPLACE (ReviewText ,'  ',' ')AS ReviewText
FROM dbo.customer_reviews

----************************************************************************

----Query to clean  and normalize the engagement_data table 
SELECT
	EngagementID,
	ContentID,
	CampaignID,
	ProductID,
	UPPER(REPLACE (ContentType,'Socialmedia','Social Media'))AS ContentType,
	LEFT (ViewsClicksCombined, CHARINDEX('-',ViewsClicksCombined) -1) AS Views,
	RIGHT (ViewsClicksCombined , LEN(ViewsClicksCombined)  - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,
	Likes,
	FORMAT(CONVERT(DATE,EngagementDate),'dd.mm.yyyy') AS EngagementDate	
FROM dbo.engagement_data
WHERE ContentType != 'NEWSLETTER'

-----*********************************************************************

---Common Table Expressionn (CTE) to identify and tag duplicate records 
WITH DuplacateRecords AS (
	SELECT 
		JourneyID,
		CustomerID,
		ProductID,
		VisitDate,
		Stage,
		Action,
		ROW_NUMBER () OVER (
			PARTITION BY CustomerID,ProductID,VisitDate,Stage,Action
			ORDER BY JourneyID
		) AS row_num 

	FROM dbo.customer_journey 
)
---- select all from the CTE where row_num > 1 , which indicates duplicate entries
SELECT * 
FROM DuplacateRecords 
WHERE row_num > 1
ORDER BY JourneyID

---- Outer query selects the final cleaned and standardized data
SELECT 
			JourneyID,
			CustomerID,
			ProductId,
			VisitDate,
			Stage,
			Action,
			COALESCE(Duration, avg_duration) AS Duration ---replaces missing duration with the average duration for the corresponding
FROM (
  ---subquery to clean and process the data
	  SELECT
		JourneyID,
		CustomerID,
		ProductId,
		VisitDate,
		UPPER(Stage) AS Stage,
		Action,
		Duration ,
		AVG (Duration) OVER (PARTITION BY VisitDate )  AS avg_duration, 
		ROW_NUMBER () OVER (
				PARTITION BY CustomerID,ProductID,VisitDate,UPPER(Stage),Action
				ORDER BY JourneyID
			) AS row_num 
	FROM dbo.customer_journey
) AS subquery 
WHERE row_num = 1
