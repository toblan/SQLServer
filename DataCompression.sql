
USE [<DatabaseName>]
GO

SET STATISTICS IO OFF
SET NOCOUNT ON
GO

-- Server Uptime
select cast((datediff(hh, create_date, getdate()))/24 as varchar(3)) + ' days, '
     + cast((datediff(hh, create_date, getdate())) % 24 as varchar(2)) + ' hours'
     as [SQL Server Service Uptime]
from sys.databases where name = 'tempdb'
GO

SELECT
    --o.id, 
    o.name as "object_name",
    x.name as "index_name",
    --i.index_id,
    x.type_desc,
    s.rowcnt,
        
    (i.leaf_update_count + i.leaf_insert_count + i.leaf_delete_count + i.leaf_page_merge_count) * 100.0 / -- improved calculation by SSI : i.leaf_insert_count + i.leaf_delete_count + i.leaf_page_merge_count regarded
          (i.range_scan_count + i.leaf_insert_count +
           i.leaf_delete_count + i.leaf_update_count + 
           i.leaf_page_merge_count + i.singleton_lookup_count  -- improved calculation by MZA : singleton_lookup_count regarded
          ) as [Writes %],
                               
    (i.range_scan_count + i.singleton_lookup_count) * 100.0 /   -- improved calculation by MZA : singleton_lookup_count regarded
          (i.range_scan_count + i.leaf_insert_count +
           i.leaf_delete_count + i.leaf_update_count + 
           i.leaf_page_merge_count + i.singleton_lookup_count   -- improved calculation by MZA : singleton_lookup_count regarded
          ) as [Reads %],  
          
    CASE
      WHEN x.type_desc = 'CLUSTERED' THEN 'ALTER TABLE [' + o.name + '] REBUILD WITH (DATA_COMPRESSION = PAGE);'
      WHEN x.type_desc = 'NONCLUSTERED' THEN 'ALTER INDEX [' + x.name + '] ON [' + o.name + '] REBUILD WITH (DATA_COMPRESSION = PAGE);'
      WHEN x.type_desc = 'HEAP' THEN '-- No compression on Heaps!'
      ELSE '--'          
    END [TSQL (PAGE Compression)],
	CASE
      WHEN x.type_desc = 'CLUSTERED' THEN 'ALTER TABLE [' + o.name + '] REBUILD WITH (DATA_COMPRESSION = ROW);'
      WHEN x.type_desc = 'NONCLUSTERED' THEN 'ALTER INDEX [' + x.name + '] ON [' + o.name + '] REBUILD WITH (DATA_COMPRESSION = ROW);'
      WHEN x.type_desc = 'HEAP' THEN '-- No compression on Heaps!'
      ELSE '--'          
    END [TSQL (ROW Compression)],

    CASE
      WHEN x.type_desc = 'CLUSTERED' THEN 'EXEC sp_estimate_data_compression_savings @schema_name = ''dbo'', @object_name = [' + o.name + '], @index_id = 1, @partition_number = NULL, @data_compression = ''PAGE'';'
      WHEN x.type_desc = 'NONCLUSTERED' THEN 'EXEC sp_estimate_data_compression_savings @schema_name = ''dbo'', @object_name = [' + o.name + '], @index_id = [' + CAST( i.index_id as varchar(2) ) + '], @partition_number = NULL, @data_compression = ''PAGE'';'
      WHEN x.type_desc = 'HEAP' THEN '-- No compression on Heaps!'
      ELSE '--'          
    END [TSQL (sp_estimate_data_ompression PAGE)], 
	   
	CASE
      WHEN x.type_desc = 'CLUSTERED' THEN 'EXEC sp_estimate_data_compression_savings @schema_name = ''dbo'', @object_name = [' + o.name + '], @index_id = 1, @partition_number = NULL, @data_compression = ''ROW'';'
      WHEN x.type_desc = 'NONCLUSTERED' THEN 'EXEC sp_estimate_data_compression_savings @schema_name = ''dbo'', @object_name = [' + o.name + '], @index_id = [' + CAST( i.index_id as varchar(2) ) + '], @partition_number = NULL, @data_compression = ''ROW'';'
      WHEN x.type_desc = 'HEAP' THEN '-- No compression on Heaps!'
      ELSE '--'          
    END [TSQL (sp_estimate_data_ompression ROW)] 
  
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
	JOIN sys.sysobjects o ON o.id = i.object_id
	JOIN sys.indexes x ON x.object_id = i.object_id AND x.index_id = i.index_id
	JOIN sys.sysindexes s ON s.id = x.object_id and s.indid = x.index_id

WHERE (i.range_scan_count + i.leaf_insert_count
        + i.leaf_delete_count + leaf_update_count
        + i.leaf_page_merge_count + i.singleton_lookup_count) <> 0
	AND objectproperty(i.object_id,'IsUserTable') = 1
	
    AND (i.leaf_update_count + i.leaf_insert_count + i.leaf_delete_count + i.leaf_page_merge_count) * 100.0 / 
          (i.range_scan_count + i.leaf_insert_count +
           i.leaf_delete_count + i.leaf_update_count + 
           i.leaf_page_merge_count + i.singleton_lookup_count
          ) < 20 -- Write ratio less than 20%

	AND (i.range_scan_count + i.singleton_lookup_count) * 100.0 /
          (i.range_scan_count + i.leaf_insert_count +
           i.leaf_delete_count + i.leaf_update_count + 
           i.leaf_page_merge_count + i.singleton_lookup_count
          ) > 80 -- Read ratio greater than 20%

	AND s.rowcnt >= 1000000  -- filter on large tables/indexes; change threshold      

ORDER BY [object_name], [index_name]
GO

-- display compressed objects
SELECT OBJECT_NAME(part.[object_id]) AS [object_name], idx.name AS [index_name], part.[data_compression_desc],
 	CASE
      WHEN idx.type_desc = 'CLUSTERED' THEN 'ALTER TABLE [' + OBJECT_NAME(part.[object_id]) + '] REBUILD WITH (DATA_COMPRESSION = NONE);'
      WHEN idx.type_desc = 'NONCLUSTERED' THEN 'ALTER INDEX [' + idx.name + '] ON [' + OBJECT_NAME(part.[object_id]) + '] REBUILD WITH (DATA_COMPRESSION = NONE);'
      WHEN idx.type_desc = 'HEAP' THEN '-- No compression on Heaps!'
      ELSE '--'          
    END [TSQL (Undo Compression)]
FROM  sys.partitions part
JOIN sys.indexes idx ON part.[object_id] = idx.[object_id] AND part.index_id = idx.index_id
WHERE [data_compression] <> 0
ORDER BY [object_name], [index_name]
GO
