USE [Logging]
GO
/****** Object:  View [dbo].[RS_Process]    Script Date: 04/25/2014 10:06:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create View [dbo].[RS_Process]
 as
 select Process, min(datediff(ss, Startdate, Enddate)) as duration, COUNT(*) as Anzahl
  from [Logging].[dbo].[ETL_Log]
  where Message like '%succeded%'
 group by process
GO
