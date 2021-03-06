USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pCollectOSWaitStats]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Wait Stats sammeln
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pCollectOSWaitStats] 
		@PerfDataScanID int,	-- ID Scan
		@Retention int = 180	-- Aufbewahrungsdatuer Altdaten in Tagen / 180 Default

as
begin

	declare @StatCreationTime as smalldatetime

		
	set @StatCreationTime=getdate()

	-- Alte Daten löschen
	
	set @Retention = ISNULL(@retention,180)		-- Default 180 Tage
	delete
	from Monitoring.tOSWaitStats
	where Scantime < DATEADD(day,-@Retention,@StatCreationTime)

	-- Waitstats
	insert into Monitoring.tOSWaitStats(PerfDataScanID, wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms, Scantime)
	select @PerfDataScanID,wait_type, waiting_tasks_count, wait_time_ms, max_wait_time_ms, signal_wait_time_ms, getdate() as Scantime
	from sys.dm_os_wait_stats

end
GO
