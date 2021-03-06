USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pCollectMissingIndexInformation]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Sammeln von Indexwünschen des SQL Servers
-- Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pCollectMissingIndexInformation] 
	 @IndexScanID int,
	 @dbid int,
	 @dbname as varchar(100),
	 @Retention as int = 180		-- Aufbewahrungsdatuer alte Scandaten in Tagen / 180 Default
as
begin

	declare @StatCreationTime as smalldatetime
	declare @sql as varchar(max)


	-- Alte Daten löschen
	set @Retention = ISNULL(@retention,180)		-- Default 180 Tage
	delete
	from Monitoring.tIndexMissingDetails
	where Scantime < DATEADD(day,-@Retention,@StatCreationTime)
	
	delete
	from Monitoring.tIndexMissingGroupStats
	where Scantime < DATEADD(day,-@Retention,@StatCreationTime)

	-- Zuerst Missing Index Details (Auflistung der gewünschten Indizes sowie der dazugehörigen Spalten)
	set @StatCreationTime=getdate()
		
	set @SQL='
				insert into Monitoring.tIndexMissingDetails(IndexScanID, group_handle, DBName,Tablename, TableSchema, index_handle, equality_columns, inequality_columns, included_columns,ScanTime)
				select  ##ScanID## as IndexScanID
						,mig.index_group_handle as group_handle
						,''##DBNAME##'' as DBName
						,so.name as Tablename
						,sc.name as TableSchema
						,mid.index_handle
						,mid.equality_columns
						,mid.inequality_columns
						,mid.included_columns
						,##StatCreationTime## as ScanTime
				from ##DBNAME##.sys.dm_db_missing_index_groups mig inner join ##DBNAME##.sys.dm_db_missing_index_details as mid
															on mig.index_handle=mid.index_handle
														inner join ##DBNAME##.sys.objects as so
															on mid.object_id=so.object_id
														inner join ##DBNAME##.sys.schemas as sc
															on so.schema_id=sc.schema_id
				where mid.database_id=##dbid##
				order by index_group_handle,so.name
			'



 	set @SQL = replace(@SQL,'##DBNAME##',@dbname)
	set @sql = replace(@sql,'##dbid##',convert(varchar(10),@dbid))
	set @SQL = replace(@SQL,'##StatCreationTime##',''''+convert(VARCHar(50),@StatCreationTime,126)+'''')
	set @SQL = replace(@SQL,'##ScanID##',convert(varchar(10),@IndexScanID))
	execute(@SQL)

	set @SQL='

				with cte as (
					select distinct group_handle
					from Monitoring.tIndexMissingDetails
					where IndexScanID=1
				)
				insert into Monitoring.tIndexMissingGroupStats(IndexScanID,DBName, group_handle,unique_compiles, user_seeks, user_scans, last_user_seek, last_user_scan, avg_total_user_cost, avg_user_impact, system_seeks, system_scans, last_system_seek, last_system_scan, avg_total_system_cost, avg_system_impact, ScanTime)
				select	##ScanID## as IndexScanID
						,''##DBNAME##'' as DBName
						,migs.group_handle
						,migs.unique_compiles
						,migs.user_seeks
						,migs.user_scans
						,migs.last_user_seek
						,migs.last_user_scan
						,migs.avg_total_user_cost
						,migs.avg_user_impact
						,migs.system_seeks
						,migs.system_scans
						,migs.last_system_seek
						,migs.last_system_scan
						,migs.avg_total_system_cost
						,migs.avg_system_impact
						,##StatCreationTime## as ScanTime
				from ##DBNAME##.sys.dm_db_missing_index_group_stats as migs inner join cte
																on migs.group_handle=cte.group_handle'

	set @SQL = replace(@SQL,'##DBNAME##',@dbname)
	--set @sql = replace(@sql,'##dbid##',convert(varchar(10),@dbid))
	set @SQL = replace(@SQL,'##StatCreationTime##',''''+convert(VARCHar(50),@StatCreationTime,126)+'''')
	set @SQL = replace(@SQL,'##ScanID##',convert(varchar(10),@IndexScanID))

	execute(@SQL)

	-- Als nächstes damit verbundene Statistiken auf Gruppenebene schreiben

end
GO
