
USE [master]
GO

SELECT TOP 100
SUBSTRING(st.text, (qs.statement_start_offset/2) + 1,
((CASE statement_end_offset 
WHEN -1 THEN DATALENGTH(st.text)
ELSE qs.statement_end_offset END 
- qs.statement_start_offset)/2) + 1) as statement_text,
execution_count,
case 
when execution_count = 0 then null
else total_logical_reads/execution_count 
end as avg_logical_reads, 
case 
when execution_count = 0 then null
else (total_worker_time/execution_count) / 1000
end as [avg_cpu_(msec)], 
case 
when execution_count = 0 then null
else (total_elapsed_time/execution_count) / 1000
end as [avg_duration_(msec)], 
case 
when execution_count = 0 then null
else total_rows/execution_count
end as [avg_rows], 

-- Query Plan Information
ph.query_plan,
qs.creation_time,
qs.last_execution_time,
case when 
ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtCursor/ns:CursorPlan/@CursorRequestedType)[1]') = 0
then '' else
ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtCursor/ns:CursorPlan/@CursorRequestedType)[1]','nvarchar (max)')
end as cursor_type

-- Missing Indexes
,case when ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup)[1]') = 0
then '' 
else ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/@Impact)[1]','nvarchar (max)')
end as missing_index_impact,
case when ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/@Table)[1]') = 0
then ''
else ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/@Table)[1]','nvarchar(max)')
end as missing_index_table

FROM sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st 
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as ph

WHERE (st.text is not null)

--AND (execution_count >= 100)  -- change threshold
AND (total_logical_reads/execution_count >= 1000) -- change threshold

ORDER BY total_logical_reads DESC 
GO