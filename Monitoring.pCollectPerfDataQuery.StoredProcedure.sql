USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pCollectPerfDataQuery]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Abfragepläne zu Queries sammeln
-- Performance Collector Framework
-- (c) 2010-2013 it innovations GmbH.
CREATE procedure [Monitoring].[pCollectPerfDataQuery] 

	@PerfDataScanID int
	-- Gesamtwerte für Server aus Monitoring.pCollectPerfDataWorkload für Prozentberechnungen
	,@total_worker_time_ms bigint = 0
	,@total_physical_reads bigint = 0
	,@total_logical_reads bigint = 0
	,@total_logical_writes bigint = 0
	,@total_clr_time_ms bigint = 0
	,@total_elapsed_time_ms bigint = 0
	,@Retention int = 180				-- Aufbewahrungsdauer Performancedaten
as
begin 
		declare @StatCreationTime datetime
		declare @SQL as nvarchar(max)
		declare @SQLWhereClause as nvarchar(max)
		declare @total_worker_time_target_ms nvarchar(50)
		declare @total_physical_reads_target nvarchar(50)
		declare @total_logical_reads_target nvarchar(50)
		declare @total_logical_writes_target nvarchar(50)
		declare @total_clr_time_target_ms nvarchar(50)
		declare @total_elapsed_time_target_ms nvarchar(50)
		declare @threshold as decimal(4,2)
		declare @MaxNumberOfQueries as int
		
		set @StatCreationTime=getdate()
		-- Alte Daten löschen
	
		set @Retention = ISNULL(@retention,180)		-- Default 180 Tage
		delete
		from Monitoring.PerfDataQuery
		where Scantime < DATEADD(day,-@Retention,@StatCreationTime)
		
		
		-- Quote der Workload in Prozent gegenüber gesamter Workload die zu einer Archivierung des Plans führt
		select @threshold = CONVERT(int, MonitorConfigValue)
		from Monitoring.tConfig
		where MonitorConfigOption='PERFDATA THRESHOLD'

		select @MaxNumberOfQueries = CONVERT(int, MonitorConfigValue)
		from Monitoring.tConfig
		where MonitorConfigOption='PERFDATA MAX NUMBER OF QUERIES TO LOG'
		
		set @Retention=ISNULL(@retention,1.0)		-- Default: 1% 
		
		if  isnull(@threshold,0) > 0 
			begin
				set @total_worker_time_target_ms = '(total_worker_time_ms>'+convert(nvarchar(20),convert(bigint,@total_worker_time_ms/100.0 * isnull(@threshold,0)))+') '
				set @total_physical_reads_target ='(total_physical_reads>'+convert(nvarchar(20),convert(bigint,@total_physical_reads/100.0 * isnull(@threshold,0)))+') '
				set @total_logical_reads_target ='(total_logical_reads>'+convert(nvarchar(20),convert(bigint,@total_logical_reads/100.0 * isnull(@threshold,0)))+') '
				set @total_logical_writes_target ='(total_logical_writes>'+convert(nvarchar(20),convert(bigint,@total_logical_writes/100.0 * isnull(@threshold,0)))+') '
				set @total_clr_time_target_ms ='(total_clr_time_ms>'+convert(nvarchar(20),convert(bigint,@total_clr_time_ms/100.0 * isnull(@threshold,0)))+') '
				set @total_elapsed_time_target_ms ='(total_elapsed_time_ms>'+convert(nvarchar(20),convert(bigint,@total_elapsed_time_ms/100.0 * isnull(@threshold,0)))+') '
				set @SQLWhereClause='WHERE ' + @total_worker_time_target_ms + ' OR ' + @total_physical_reads_target + ' OR ' + @total_logical_reads_target
											+ ' OR ' + @total_logical_writes_target + ' OR ' + @total_clr_time_target_ms + ' OR ' + @total_elapsed_time_target_ms
			end 
		else
			begin
				set @SQLWhereClause=''
			end 


		set @SQL = '
			insert into Monitoring.PerfDataQuery(PerfDataScanID, ObjectType, dbid, refcounts, usecounts, creation_time, execution_count, total_worker_time_ms, min_worker_time_ms, max_worker_time_ms, total_physical_reads, min_physical_reads, max_physical_reads, total_logical_writes, min_logical_writes, max_logical_writes, total_logical_reads, min_logical_reads, max_logical_reads, total_clr_time_ms, min_clr_time_ms, max_clr_time_ms, total_elapsed_time_ms, min_elapsed_time_ms, max_elapsed_time_ms, query_plan, Definition, Scantime)
			SELECT  TOP('+convert(nvarchar(100),isnull(@MaxNumberOfQueries,1))+')
				##PerfDataScanID## as PerfDataScanID
				,ObjectType
				,dbid
				,refcounts
				,usecounts
				,creation_time
				,execution_count
				,total_worker_time_ms
				,min_worker_time_ms
				,max_worker_time_ms
				,total_physical_reads
				,min_physical_reads
				,max_physical_reads
				,total_logical_writes
				,min_logical_writes
				,max_logical_writes
				,total_logical_reads
				,min_logical_reads
				,max_logical_reads
				,total_clr_time_ms
				,min_clr_time_ms
				,max_clr_time_ms
				,total_elapsed_time_ms
				,min_elapsed_time_ms
				,max_elapsed_time_ms
				,query_plan
				,Definition
				,''##StatCreationTime##'' as ScanTime
		FROM Monitoring.vPerfDataQueryBase '

	set @SQL = replace(@SQL,'##StatCreationTime##',convert(VARCHar(50),@StatCreationTime,126))
	set @sql = replace(@sql,'##PerfDataScanID##',convert(varchar(10),@PerfDataScanID))
	set @sql = @sql + @SQLWhereClause
	execute(@SQL)
end
GO
