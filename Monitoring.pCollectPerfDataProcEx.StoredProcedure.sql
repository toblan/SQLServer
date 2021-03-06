USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pCollectPerfDataProcEx]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Abfragepläne zu Prozeduren sammeln
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pCollectPerfDataProcEx] 

	@PerfDataScanID int,
	@DBID int,					-- ID Datenbank für die Prozedurausführung gesammelt wird
	@dbname as nvarchar(50),   -- Name der Datenbank für die Prozdedurausführung gesammelt wird
	@Retention as int			-- Aufbewahrungsdauer Performancedaten / 180 Tage Default
	
as
begin 
		declare @StatCreationTime datetime
		declare @SQL as nvarchar(max)


		set @StatCreationTime=getdate()

		-- Alte Daten löschen
	set @Retention = ISNULL(@retention,180)		-- Default 180 Tage
	delete
	from Monitoring.PerfDataProcEx
	where Scantime < DATEADD(day,-@Retention,@StatCreationTime)

		-- Aktuelle Daten sammeln
		set @SQL = '
		insert into Monitoring.PerfDataProcEx(PerfDataScanID,ObjectType, dbid, DatabaseName, ProcedureName, ProcedureSchema, is_ms_shipped, refcounts, usecounts, creation_time, execution_count, total_worker_time_ms, min_worker_time_ms, max_worker_time_ms, total_physical_reads, min_physical_reads, max_physical_reads, total_logical_writes, min_logical_writes, max_logical_writes, total_logical_reads, min_logical_reads, max_logical_reads, total_clr_time_ms, min_clr_time_ms, max_clr_time_ms, total_elapsed_time_ms, min_elapsed_time_ms, max_elapsed_time_ms, query_plan, Definition, ScanTime)
		SELECT ##PerfDataScanID## as PerfDataScanID
				,cp.objtype as ObjectType
				,t.dbid
				,''##DBNAME##'' as DatabaseName
				,so.name as ProcedureName
				,sc.name as ProcedureSchema
				,so.is_ms_shipped
				,cp.refcounts
				,cp.usecounts
				,qs.creation_time
				,execution_count
				,total_worker_time/1000 as total_worker_time_ms
				,min_worker_time/1000 as min_worker_time_ms
				,max_worker_time/1000 as max_worker_time_ms
				,total_physical_reads
				,min_physical_reads
				,max_physical_reads
				,total_logical_writes
				,min_logical_writes
				,max_logical_writes
				,total_logical_reads
				,min_logical_reads
				,max_logical_reads
				,total_clr_time/1000 as total_clr_time_ms
				,min_clr_time/1000 as min_clr_time_ms
				,max_clr_time/1000 as max_clr_time_ms
				,total_elapsed_time / 1000 as total_elapsed_time_ms
				,min_elapsed_time / 1000 as min_elapsed_time_ms
				,max_elapsed_time / 1000 as max_elapsed_time_ms
				,qp.query_plan
				,null as Definition /*t.text as Definition*/
				,''##StatCreationTime##'' as ScanTime
		FROM sys.dm_exec_cached_plans AS cp inner join sys.dm_exec_query_stats AS qs
												ON cp.plan_handle = qs.plan_handle
											CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
											CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
											inner join ##DBNAME##.sys.objects as so
												  on t.objectid=so.object_id  
											inner join ##DBNAME##.sys.schemas as sc
												  on so.schema_id=sc.schema_id
		where cp.objtype IN(''Proc'',''Trigger'') and t.dbid=##dbid## '

	set @SQL = replace(@SQL,'##DBNAME##',@dbname)
	set @sql = replace(@sql,'##dbid##',convert(varchar(10),@dbid))
	set @SQL = replace(@SQL,'##StatCreationTime##',convert(VARCHar(50),@StatCreationTime,126))
	set @sql = replace(@sql,'##PerfDataScanID##',convert(varchar(10),@PerfDataScanID))
	execute(@SQL) 
	--select @sQL as SQL
end
GO
