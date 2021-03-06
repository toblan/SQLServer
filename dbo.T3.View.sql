USE [master]
GO
/****** Object:  View [dbo].[T3]    Script Date: 04/25/2014 10:08:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [dbo].[T3] as
SELECT
T1.[datum], 
T1.[Reason Code], 
T1.[Pro_KampagnenName], 
COUNT(T1.ExtDocNo_) AS ExtDocNo_, 
COUNT(T1.Transaktion) AS Transaktion, 
SUM(T1.Nav_OrderIntake) AS Nav_OrderIntake, 
AVG(T2.DAILY_COST) AS DAILY_COST, 
SUM(T2.Visits) AS Visits, 
SUM(T2.NewVisits) AS NewVisits, 
SUM(T2.Bounces) AS Bounces, 
SUM(T1.SalesDoNo_) AS SalesDoNo, 
SUM(T1.GA_OrderIntake) AS GA_OrderIntake
FROM 
T1 INNER JOIN
T2 ON T1.[datum] = T2.[datum] AND T1.[Reason Code] = T2.[Reason Code] COLLATE Latin1_General_100_CS_AS
AND T1.[Pro_KampagnenName] = T2.KampagnenName COLLATE Latin1_General_100_CS_AS
GROUP BY T1.[datum], T1.[Reason Code], T1.[Pro_KampagnenName]
GO
