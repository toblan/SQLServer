USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pPerfDataScanMain]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Zentrale Routine Performancekollektor
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pPerfDataScanMain] as 

begin

	declare @DBName as nvarchar(50)
	declare @DBID as int
	declare @ServerName as nvarchar(50)
	declare @ScanStart as datetime
	declare @ServerBootTime as datetime
	declare @PerfDataScanID as int

	-- Gesamtworkload
	declare @total_worker_time_ms bigint
	declare @total_physical_reads bigint
	declare @total_logical_reads bigint
	declare @total_logical_writes bigint
	declare @total_clr_time_ms bigint
	declare @total_elapsed_time_ms bigint

	set @ServerName = @@servername

	begin try
	
		declare @Retention as int -- Aufbewahrungsdauer Performancedaten
		
		-- Aufbewahrungsdauer aus Konfigurationstabelle holen
		select @Retention = CONVERT(int, MonitorConfigValue)
		from Monitoring.tConfig
		where MonitorConfigOption='PERFDATA RETENTION'
		
		set @Retention=ISNULL(@retention,180)		-- Default: 180 Tage
	
		set @ScanStart=getdate()
		select @ServerBootTime=login_time
		from sys.dm_exec_sessions
		where session_id=1


			-- Scan-Header erzeugen
		insert into Monitoring.tPerfDataScans(ServerName, ScanStart, ServerBootTime)
		values (@ServerName,@ScanStart,@ServerBootTime)
		set @PerfDataScanID=scope_identity()

		-- Gesamten SErver Workload seit letztem ClearCache ermitteln
		exec Monitoring.pCollectPerfDataWorkload @PerfDataScanID,@total_worker_time_ms output,@total_physical_reads output,@total_logical_reads output,@total_logical_writes output,@total_clr_time_ms output,@total_elapsed_time_ms output,@Retention
		--select @total_worker_time_ms as total_worker_time_ms

		-- Performanceinformationen aus dem PlanCache lesen die nicht einer Datenbank zuordenbar sind (AdHoc, Prepared, etc.)
		exec Monitoring.pCollectPerfDataQuery @PerfDataScanID,@Retention

		-- Wait Stats sammeln
		exec Monitoring.pCollectOSWaitStats @PerfDataScanID,@Retention

		-- Datenbankspezifische Performancedaten ermitteln
		declare csDBsToScan cursor local fast_forward for
			select ScannedDBName,PerformanceDataRetention
			from Monitoring.tScannedDB
			where EnableScan=1

		open csDBsToScan

		fetch next from csDBsToScan into @DBName,@Retention

		while @@fetch_status = 0
		begin

				set @DBID=db_id(@DBName)


				if @DBID is not null
					begin

						set @Retention=ISNULL(@retention,180)		-- Default: 180 Tage
						
						exec Monitoring.pCollectPerfDataProcEx @PerfDataScanID,@DBID,@dbname,@retention
						
						fetch next from csDBsToScan into @DBName,@Retention
				end 
		end 

		close  csDBsToScan

		deallocate  csDBsToScan

		-- Falls bisher kein Fehler, Prozedurcache räumen & Wait Stats zurücksetzen
		DBCC FREEPROCCACHE						
		DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR); 

		update Monitoring.tPerfDataScans
		set ScanEnd=getdate()
		where PerfDataScanID=@PerfDataScanID
	
	end try



	begin catch
		declare @errormessage as nvarchar(max)
		set @errormessage = convert(varchar(10),error_number())+' - ' + error_message()
		raiserror(@errormessage,15,0)


	end catch

end
GO
