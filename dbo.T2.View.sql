USE [master]
GO
/****** Object:  View [dbo].[T2]    Script Date: 04/25/2014 10:08:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[T2] as
SELECT DISTINCT [datum]
      ,[Reason Code]
      ,[KampagnenName],
SUM([NoOfTA]) AS NoOfTA, 
SUM([Umsatz]) AS GA_OrderIntake, 
AVG([DAILY_COST]) AS DAILY_COST, 
SUM([Visits]) AS Visits, 
SUM([NewVisits]) AS NewVisits, 
SUM([Bounces]) AS Bounces
FROM Marketing_Staging.[dbo].TransktionenVisitsCosts
GROUP BY [datum]
      ,[Reason Code]
      ,[KampagnenName]
GO
