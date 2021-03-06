USE [Logging]
GO
/****** Object:  StoredProcedure [dbo].[GetTopStatements_AvgDuration]    Script Date: 04/25/2014 10:06:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		John Sterrett (@JohnSterrett)
-- Create date: 6/4/2013
-- Description:	Get statements from cache causing most average duration by executions
-- Example: exec dbo.GetTopStatements_AvgDuration @NumOfStatements = 25, @Executions = 5
-- =============================================
CREATE PROCEDURE [dbo].[GetTopStatements_AvgDuration]
	-- Add the parameters for the stored procedure here
	@NumOfStatements int = 25,
	@Executions int = 5
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--- top 25 statements by IO
IF OBJECT_ID('tempdb..#TopOffenders') IS NOT NULL
		DROP TABLE #TopOffenders
IF OBJECT_ID('tempdb..#QueryText') IS NOT NULL
		DROP TABLE #QueryText
CREATE TABLE #TopOffenders (AvgIO bigint, TotalIO bigint, TotalCPU bigint, AvgCPU bigint, TotalDuration bigint, AvgDuration bigint, [dbid] int, objectid bigint, execution_count bigint, query_hash varbinary(8))
CREATE TABLE #QueryText (query_hash varbinary(8), query_text varchar(max))

INSERT INTO #TopOffenders (AvgIO, TotalIO, TotalCPU, AvgCPU, TotalDuration, AvgDuration, [dbid], objectid, execution_count, query_hash)
SELECT TOP (@NumOfStatements)
        SUM((qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count) as [Avg IO],
        SUM((qs.total_logical_reads + qs.total_logical_writes)) AS [TotalIO],
        SUM(qs.total_worker_time) AS Total_Worker_Time,
        SUM((qs.total_worker_time) / qs.execution_count) AS [AvgCPU],
        SUM(qs.total_elapsed_time) AS TotalDuration,
		SUM((qs.total_elapsed_time)/ qs.execution_count) AS AvgDuration,
    qt.dbid,
    qt.objectid,
    SUM(qs.execution_count) AS Execution_Count,
    qs.query_hash
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text (qs.sql_handle) as qt
GROUP BY qs.query_hash, qs.query_plan_hash, qt.dbid, qt.objectid
HAVING SUM(qs.execution_count) > @Executions
ORDER BY [AvgDuration] DESC

--select * From #TopOffenders
--ORDER BY TotalIO desc

/* Create cursor to get query text */
DECLARE @QueryHash varbinary(8)

DECLARE QueryCursor CURSOR FAST_FORWARD FOR
select query_hash
FROM #TopOffenders

OPEN QueryCursor
FETCH NEXT FROM QueryCursor INTO @QueryHash

WHILE (@@FETCH_STATUS = 0)
BEGIN

		INSERT INTO #QueryText (query_text, query_hash)
		select MIN(substring (qt.text,qs.statement_start_offset/2, 
				 (case when qs.statement_end_offset = -1 
				then len(convert(nvarchar(max), qt.text)) * 2 
				else qs.statement_end_offset end -    qs.statement_start_offset)/2)) 
				as query_text, qs.query_hash
		from sys.dm_exec_query_stats qs
		cross apply sys.dm_exec_sql_text (qs.sql_handle) as qt
		where qs.query_hash = @QueryHash
		GROUP BY qs.query_hash;

		FETCH NEXT FROM QueryCursor INTO @QueryHash
   END
   CLOSE QueryCursor
   DEALLOCATE QueryCursor

		select distinct DB_NAME(dbid) DBName, OBJECT_NAME(objectid, dbid) ObjectName, qt.query_text, o.*
		INTO #Results
		from #TopOffenders o
		join #QueryText qt on (o.query_hash = qt.query_hash)

		SELECT TOP (@NumOfStatements) *
		FROM #Results
		ORDER BY AvgDuration desc  

		DROP TABLE #Results
		DROP TABLE #TopOffenders
		DROP TABLE #QueryText
	END
GO
