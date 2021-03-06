USE [master]
GO
/****** Object:  View [Monitoring].[vPerfDataQueryBase]    Script Date: 04/25/2014 10:08:23 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view [Monitoring].[vPerfDataQueryBase] as

		SELECT  
				
				cp.objtype as ObjectType
				,t.dbid
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
				,t.text as Definition
		FROM sys.dm_exec_cached_plans AS cp inner join sys.dm_exec_query_stats AS qs
												ON cp.plan_handle = qs.plan_handle
											CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
											CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS t
		where cp.objtype not IN('Proc','Trigger')
GO
