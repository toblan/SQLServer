USE Urban_NAV600_SL
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
last_logical_reads,
min_logical_reads,
max_logical_reads,
qs.sql_handle,
plan_handle,
ph.query_plan,

-- Query Plan Information
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
end as missing_index_table,
case when ph.query_plan.exist('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/ns:ColumnGroup/ns:Column/@Name)[1]') = 0
then ''
else ph.query_plan.value('declare namespace ns="http://schemas.microsoft.com/sqlserver/2004/07/showplan";(/ns:ShowPlanXML/ns:BatchSequence/ns:Batch/ns:Statements/ns:StmtSimple/ns:QueryPlan/ns:MissingIndexes/ns:MissingIndexGroup/ns:MissingIndex/ns:ColumnGroup/ns:Column/@Name)[1]','nvarchar(max)')
end as missing_index_field

FROM sys.dm_exec_query_stats as qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) as st 
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) as ph

WHERE (st.text is not null)

AND (execution_count >= 100)  -- change threshold
AND (total_logical_reads/execution_count >= 1000) -- change threshold

ORDER BY execution_count DESC 
GO

---

SELECT migs.group_handle, mig.index_handle, migs.user_seeks, migs.last_user_seek, migs.user_scans, migs.last_user_scan, migs.avg_user_impact,
       db_name(mid.database_id) as db, object_name(mid.object_id) as object, mid.equality_columns, mid.inequality_columns, mid.included_columns,

	   'CREATE INDEX [ssi_' + convert(varchar, migs.group_handle) + '_' +  convert(varchar, mig.index_handle) + '] ON [' +  object_name(mid.object_id) + '] ' + '(' +
	   CASE WHEN mid.equality_columns is not null THEN mid.equality_columns ELSE '' END +
	   CASE WHEN mid.inequality_columns is not null THEN ', ' + mid.inequality_columns ELSE '' END + ')' +
	   CASE WHEN mid.included_columns is not null THEN ' INCLUDE (' + mid.included_columns + ')' ELSE '' END as tsql
	    
FROM sys.dm_db_missing_index_group_stats AS migs
INNER JOIN sys.dm_db_missing_index_groups AS mig
    ON (migs.group_handle = mig.index_group_handle)
INNER JOIN sys.dm_db_missing_index_details AS mid
    ON (mig.index_handle = mid.index_handle)
WHERE (mid.database_id = db_id())

AND (migs.user_seeks >= 10)  -- change threshold
AND (migs.avg_user_impact >= 80)  -- change threshold

ORDER BY object_name(mid.object_id) ASC, migs.user_seeks DESC, migs.user_scans DESC
GO
  

