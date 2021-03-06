USE [master]
GO
/****** Object:  StoredProcedure [Monitoring].[pIndexScanMain]    Script Date: 04/25/2014 10:08:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Zentrale Routine Indexanalyse
--Performance Collector Framework
-- (c) 2010-2011 it innovations GmbH.
CREATE procedure [Monitoring].[pIndexScanMain] as 

begin

	declare @DBName as nvarchar(50)
	declare @DBID as int
	declare @ServerName as nvarchar(50)
	declare @ScanStart as datetime
	declare @ServerBootTime as datetime
	declare @IndexScanID as int
	declare @Retention as int -- Aufbewahrungsdauer Performancedaten
	declare @RetentionDefault int
	
	set @ServerName = @@servername

	set @ScanStart=getdate()
	
	select @ServerBootTime=login_time
	from sys.dm_exec_sessions
	where session_id=1
	
		
	-- Aufbewahrungsdauer aus Konfigurationstabelle holen
	select @RetentionDefault = CONVERT(int, MonitorConfigValue)
	from Monitoring.tConfig
	where MonitorConfigOption='INDEX RETENTION'

	declare csDBsToScan cursor local fast_forward for
		select ScannedDBName,IndexDataRetention
		from Monitoring.tScannedDB
		where EnableScan=1

	open csDBsToScan

	fetch next from csDBsToScan into @DBName,@Retention

	while @@fetch_status = 0
	begin

			set @DBID=db_id(@DBName)
			
			set @Retention=coalesce(@Retention,@RetentionDefault,180)

			if @DBID is not null
				begin
					-- Scan-Header erzeugen
					insert into Monitoring.tIndexScans(ServerName, ScanStart, ServerBootTime, DatabaseID, DatabaseName)
					values (@ServerName,@ScanStart,@ServerBootTime, @DBID,@DBName)

					set @IndexScanID=scope_identity()

					-- Hier Aufruf der Indexsubroutinen

					-- Physikalische Statistiken abrufen
					exec Monitoring.pCollectIndexPhysicalStats @IndexScanID,@DBID,@DBName,@Retention

					-- Verwendungsstatistiken abrufen
					exec Monitoring.pCollectIndexUsageStats @IndexScanID,@DBID,@DBName,@Retention

					-- Missing Index Information abrufen
					exec [Monitoring].[pCollectMissingIndexInformation]  @IndexScanID,@DBID,@DBName,@Retention
			
					update Monitoring.tIndexScans
					set ScanEnd=getdate()
					where IndexScanID=@IndexScanID
				end
			fetch next from csDBsToScan into @DBName,@Retention
	end 

	close  csDBsToScan

	deallocate  csDBsToScan

end
GO
