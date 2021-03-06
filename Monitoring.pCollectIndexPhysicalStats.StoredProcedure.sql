USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pCollectIndexPhysicalStats]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Physikalische Struktur von Indizes und Heaps sammeln
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pCollectIndexPhysicalStats] 
		@IndexScanID int,
		@dbid int, 
		@dbname nvarchar(50),
		@Retention int		-- Aufbewahrungsdauer alte Montioringdaten
as
begin

	declare @IndexPhysicalStatCreationTime as smalldatetime
	declare @SQL as nvarchar(max)
		
	set @IndexPhysicalStatCreationTime=getdate()
	
	
		-- Alte Daten löschen
	
	set @Retention = ISNULL(@retention,180)		-- Default 180 Tage
	delete
	from Monitoring.tIndexPhysicalStats
	where Scantime < DATEADD(day,-@Retention,@IndexPhysicalStatCreationTime)
	
	-- Neue Daten sammeln
	set @SQL = '
	insert into Monitoring.tIndexPhysicalStats(IndexScanID,DBName,SchemaName,Tablename, Index_Or_Heap_Name, object_id, index_id,is_partitioned, partition_number, index_type_desc, alloc_unit_type_desc, index_depth, index_level, avg_fragmentation_in_percent, fragment_count, avg_fragment_size_in_pages, page_count, avg_page_space_used_in_percent, record_count, ghost_record_count, version_ghost_record_count, min_record_size_in_bytes, max_record_size_in_bytes, avg_record_size_in_bytes, forwarded_record_count, ScanTime)
	select '+convert(varchar(10),@IndexScanID)+'as IndexScanID,''##DBNAME##'' as DBName,sc.name as SchemaName,so.name as Tablename,
		   isnull(si.name,so.name) as Index_Or_Heap_Name,
			 i.object_id, i.index_id,
			 case when ds.type=''PS'' then 1 else 0 end as is_partitioned,
			  i.partition_number,
			   i.index_type_desc, i.alloc_unit_type_desc, i.index_depth, i.index_level, i.avg_fragmentation_in_percent, i.fragment_count, i.avg_fragment_size_in_pages, i.page_count, i.avg_page_space_used_in_percent, i.record_count, i.ghost_record_count, i.version_ghost_record_count, i.min_record_size_in_bytes, i.max_record_size_in_bytes, i.avg_record_size_in_bytes, i.forwarded_record_count, 
		  ''##IndexPhysicalStatCreationTime##''
	from ##DBNAME##.sys.dm_db_index_physical_stats(##dbid##,null,null,NULL,''DETAILED'') as i
					inner join ##DBNAME##.sys.objects as so
							on i.object_id = so.object_id
					inner join ##DBNAME##.sys.indexes as si
							on i.object_id = si.object_id
							   and i.index_id = si.index_id
					inner join ##DBNAME##.sys.schemas as sc
								on so.schema_id=sc.schema_id
					inner join ##DBNAME##.sys.data_spaces as ds
								on si.data_space_id=ds.data_space_id

		where so.is_ms_shipped = 0
			  and si.type in (0,1,2)			-- Heap,Clusterd, Nonclustered
		order by record_count desc'

	set @SQL = replace(@SQL,'##DBNAME##',@dbname)
	set @sql = replace(@sql,'##dbid##',convert(varchar(10),@dbid))
	set @SQL = replace(@SQL,'##IndexPhysicalStatCreationTime##',convert(VARCHar(50),@IndexPhysicalStatCreationTime,126))
	

	execute(@SQL)

end
GO
