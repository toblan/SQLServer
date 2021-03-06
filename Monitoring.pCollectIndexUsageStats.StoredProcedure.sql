USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pCollectIndexUsageStats]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Verwendung der Indizes sammeln
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pCollectIndexUsageStats] 
	 @IndexScanID int,
	 @dbid int,
	 @dbname as varchar(100),
	 @Retention as int	= 180		-- Aufbewahrungsdauer alte Scandaten in Tagen / Default 180
as
begin

	declare @IndexPhysicalStatCreationTime as smalldatetime
	declare @sql as varchar(max)


	set @IndexPhysicalStatCreationTime=getdate()
	
	
	-- Alte Daten löschen
	
	set @Retention = ISNULL(@retention,180)		-- Default 180 Tage
	delete
	from Monitoring.tIndexUsageStats
	where Scantime < DATEADD(day,-@Retention,@IndexPhysicalStatCreationTime)
	
	-- Neue Daten sammeln
		
	set @SQL='
	insert Monitoring.tIndexUsageStats(IndexScanID,DBName,SchemaName,Tablename, Index_Or_Heap_Name, object_id, index_id, index_type_desc, user_seeks, user_scans, scan_ratio, user_lookups, user_updates, last_user_seek, last_user_scan, last_user_lookup, last_user_update, ScanTime)
	select 
			'+convert(varchar(10),@IndexScanID)+' as IndexScanID,
			''##DBNAME##'' as DBName,
			sc.name as SchemaName,
			so.name as Tablename,
		   isnull(si.name,so.name) as Index_Or_Heap_Name,	
		   so.object_id ,  	
		   si.index_id,
		   si.type_desc as index_type_desc,
		   u.user_seeks,
		   u.user_scans,
		   case when isnull(u.user_scans,0)=0 then 0 else  u.user_scans/convert(float,isnull(u.user_seeks,0)+isnull(user_scans,0)) end as scan_ratio,
		   u.user_lookups,
		   u.user_updates,
		   u.last_user_seek,
		   u.last_user_scan,
		   u.last_user_lookup,
		   u.last_user_update,
		   ##IndexPhysicalStatCreationTime## as IndexPhysicalStatCreationTime
	from ##DBNAME##.sys.indexes as si inner join ##DBNAME##.sys.objects as so
							on si.object_id = so.object_id
					inner join  ##DBNAME##.sys.dm_db_index_usage_stats as u
							on si.object_id = u.object_id
							   and si.index_id = u.index_id
					inner join  ##DBNAME##.sys.schemas as sc
							on so.schema_id=sc.schema_id

	where so.is_ms_shipped = 0 and u.database_id=##dbid##'


 	set @SQL = replace(@SQL,'##DBNAME##',@dbname)
	set @sql = replace(@sql,'##dbid##',convert(varchar(10),@dbid))
	set @SQL = replace(@SQL,'##IndexPhysicalStatCreationTime##',''''+convert(VARCHar(50),@IndexPhysicalStatCreationTime,126)+'''')

	execute(@SQL)
end
GO
