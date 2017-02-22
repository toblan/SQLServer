use Urban_NAV600_SL
GO


-- Verify Index Usage (current usage stats)
SELECT object_name(IDX."object_id") AS "object", IDX."name", 
       IDXUSG."user_seeks", IDXUSG."user_scans", IDXUSG."user_lookups", IDXUSG."user_updates" 
FROM sys.dm_db_index_usage_stats IDXUSG (nolock)
  JOIN sys.indexes IDX (nolock) ON IDX."object_id" = IDXUSG."object_id" AND IDX."index_id" = IDXUSG."index_id"
WHERE IDXUSG."database_id" = db_id()
  AND object_name(IDX."object_id") not like 'ssi_%'
  AND (IDX."name" LIKE 'ssi[0-9][0-9]%' OR IDX."name" LIKE 'ssi_%' OR IDX."name" LIKE 'IX_%')
ORDER BY object_name(IDX."object_id"), IDX."name" 
GO 





