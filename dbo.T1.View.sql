USE [master]
GO
/****** Object:  View [dbo].[T1]    Script Date: 04/25/2014 10:08:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create view [dbo].[T1] as
SELECT DISTINCT datum, 
[Reason Code], 
[Pro_KampagnenName], 
COUNT([External Document No_]) AS ExtDocNo_, 
COUNT([Transaktion]) AS Transaktion, 
COUNT([Sales Document No_]) AS SalesDoNo_, 
SUM([Nav_OrderIntake]) AS Nav_OrderIntake, 
SUM([GA_OI]) AS GA_OrderIntake
FROM Marketing_Staging.[dbo].BestNavGA
GROUP BY datum, 
[Reason Code], 
[Pro_KampagnenName]
GO
