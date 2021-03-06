USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pPurgePerfData]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Tabellen mit Performancedaten räumen
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
create procedure [Monitoring].[pPurgePerfData] 
		@PurgeIndexData bit =0		-- Indexdaten löschen
		,@PurgePerfData bit = 0		-- Performancedaten löschen
	as

begin

	if @PurgeIndexData=1
		begin
			truncate table Monitoring.tIndexMissingDetails
			truncate table Monitoring.tIndexMissingGroupStats
			truncate table Monitoring.tIndexUsageStats
			truncate table Monitoring.tIndexPhysicalStats
			truncate table Monitoring.tIndexScans
		
		end
		
	if @PurgePerfData = 1
		begin
			truncate table Monitoring.PerfDataProcEx
			truncate table Monitoring.PerfDataQuery
			truncate table Monitoring.tOSWaitStats
			truncate table Monitoring.tWorkload
			truncate table Monitoring.tPerfDataScans
		
		end 
		

end
GO
