USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pCollectPerfDataWorkload]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Gesamtworkload über Prozdurcache ermitteln
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pCollectPerfDataWorkload] 
		@PerfDataScanID int
		-- Rückgabewerte Gesamtworkload
		,@total_worker_time_ms bigint output
		,@total_physical_reads_ms bigint output
		,@total_logical_reads_ms bigint output
		,@total_logical_writes_ms bigint output
		,@total_clr_time_ms bigint output
		,@total_elapsed_time bigint output
		,@Retention int						-- Aufbewahrungsdauer Performancedaten

as
begin

	declare @StatCreationTime as smalldatetime
	declare @SQL as nvarchar(max)
	declare @ParamDef as nvarchar(max)

		
	set @StatCreationTime=getdate()
	
	
	-- Alte Daten löschen
	
	set @Retention = ISNULL(@retention,180)		-- Default 180 Tage
	delete
	from Monitoring.tWorkload
	where Scantime < DATEADD(day,-@Retention,@StatCreationTime)

	-- Neue Daten Sammeln
	set @SQL ='
				select @total_worker_time_ms=sum(total_worker_time)/1000  
					  ,@total_physical_reads_ms=sum(total_physical_reads)  	
					  ,@total_logical_reads_ms=sum(total_logical_reads)   
					  ,@total_logical_writes_ms = sum(total_logical_writes)  
					  ,@total_clr_time_ms = sum(total_clr_time) / 1000  
					  ,@total_elapsed_time = sum(total_elapsed_time) / 1000  
				from sys.dm_exec_cached_plans as cp inner join sys.dm_exec_query_stats as qs
										on cp.plan_handle=qs.plan_handle'

	set @ParamDef='@total_worker_time_ms bigint output,@total_physical_reads_ms bigint output,@total_logical_reads_ms bigint output,@total_logical_writes_ms bigint output,@total_clr_time_ms bigint output,@total_elapsed_time bigint output'
	exec sp_executesql @SQL,@ParamDef, @total_worker_time_ms =@total_worker_time_ms output,@total_physical_reads_ms =@total_physical_reads_ms output,@total_logical_reads_ms =@total_logical_reads_ms output,@total_logical_writes_ms=@total_logical_writes_ms output,@total_clr_time_ms =@total_clr_time_ms output,@total_elapsed_time =@total_elapsed_time output

	insert into Monitoring.tWorkload(PerfDataScanID, total_worker_time_ms, total_physical_reads_ms, total_logical_reads_ms, total_logical_writes_ms, total_clr_time_ms, total_elapsed_time, ScanTime)
	values(@PerfDataScanID, @total_worker_time_ms, @total_physical_reads_ms, @total_logical_reads_ms, @total_logical_writes_ms, @total_clr_time_ms, @total_elapsed_time,@StatCreationTime)

end
GO
