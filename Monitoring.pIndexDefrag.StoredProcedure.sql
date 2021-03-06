USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pIndexDefrag]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Indexdefragmentierung durchführen
-- Performance Collector Framework
-- (c) 2010-2013 it innovations GmbH.
CREATE procedure [Monitoring].[pIndexDefrag] as 
begin

	
	declare @DatabaseID as int;
	declare @DatabaseName as sysname;
	declare @IndexScanID as int;
	declare @IndexPhysicalStatsID as int;
	declare @DBNAme as sysname;
	declare @SchemaName as sysname
	declare @Tablename as sysname
	declare @Index_Or_Heap_Name as sysname
	declare @is_partitioned as bit
	declare @partition_number as int
	declare @avg_fragmentation_in_percent as float
	declare @SQL as nvarchar(max)
	declare @Operation as nvarchar(50)
	declare @DefragDate as datetime
	declare @StartTime as datetime
	declare @EndTime as datetime
	
	
	set @DefragDate = GETDATE();
	
	-- Hole aktuellste Index Physical die nicht älter als 1 Monat
	declare csDB cursor fast_forward local for	
	with cte as (
		select DatabaseID,DatabaseName,IndexScanID
				,ROW_NUMBER() over (partition by DatabaseID order by ScanStart desc) as rang
		from Monitoring.tIndexScans
		where ScanStart > DATEADD(month,-1,getdate())
	)
		select DatabaseID,DatabaseName,IndexScanID
		from cte
		where rang=1;
	
	open csDB;
	fetch next from csDB into @DatabaseID,@DatabaseName,@IndexScanID;
	
	while @@FETCH_STATUS=0
	begin
				declare csIndexesToDefrag cursor fast_forward local for
						select IndexPhysicalStatsID,DBNAme,SchemaName,Tablename,Index_Or_Heap_Name,is_partitioned,partition_number,avg_fragmentation_in_percent
						from Monitoring.tIndexPhysicalStats
						where DBName=@DatabaseName
							  and	IndexScanID=@IndexScanID
							  and index_id>=1 and index_level=0
							  and index_type_desc in ('CLUSTERED INDEX','NONCLUSTERED INDEX')
							  and avg_fragmentation_in_percent >= 5;  -- Tabellen unter 5% Fragementierung überspringen

				open csIndexesToDefrag;
				
				fetch next from csIndexesToDefrag into @IndexPhysicalStatsID,@DBNAme,@SchemaName,@Tablename,@Index_Or_Heap_Name,@is_partitioned,@partition_number,@avg_fragmentation_in_percent			

				while @@FETCH_STATUS=0
				begin
					set @SQL = N'ALTER INDEX '+@Index_Or_Heap_Name + N' ON ' +@DBNAme+N'.'+@SchemaName+N'.'+@Tablename+N' '
					

					set @Operation = case when @avg_fragmentation_in_percent < 30 then N'REORGANIZE' else  N'REBUILD' end
					
					set @SQL = @SQL +N' '+@Operation 

					if @is_partitioned=1
						begin	
							set @SQL = @SQL +  N' PARTITION = '+ CONVERT(nvarchar(50),@partition_number) +  N' ' ;
						end
					else
						begin
							if SERVERPROPERTY('EngineEdition') = 3	-- Enterprise
								set @SQL = @SQL + ' WITH (ONLINE = ON) '			-- ab 2014 auch auf Partitionen. Dann ändern
						end 
					--print @SQL;
					set @StartTime=getdate()
					execute(@SQL);
					set @EndTime = getdate()

					if @@ERROR =0
						begin;
							update Monitoring.tIndexPhysicalStats
							set DefragDate=@DefragDate
								,Rebuilded=case when @Operation = 'REBUILD' then 1 else 0 end
								,Reorganized =case when @Operation = 'REORGANIZE' then 1 else 0 end
								,[DefragStatement] = @SQL 
								,[DefragDurationSec] = datediff(second,@StartTime,@EndTime)
							where IndexScanID=@IndexScanID;
						end ;
					
					

					fetch next from csIndexesToDefrag into @IndexPhysicalStatsID,@DBNAme,@SchemaName,@Tablename,@Index_Or_Heap_Name,@is_partitioned,@partition_number,@avg_fragmentation_in_percent;			
				end;
				close csIndexesToDefrag;
				deallocate csIndexesToDefrag;
			fetch next from csDB into @DatabaseID,@DatabaseName,@IndexScanID;
				
	end ;

	close csDB;
	deallocate csDB;

end
GO
