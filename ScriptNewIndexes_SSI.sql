

EXECUTE [dbo].[ssi_snapidx] 
   @description = 'Review SSI'
  ,@idx_filter = 'ssi%'

DECLARE @time varchar(30)
SELECT @time = "SnapDateTime" FROM ssi_IdxSnapshot WHERE "description" = 'Review SSI'

EXECUTE [dbo].[ssi_reindex] 
   @snap_date = @time
  ,@snap_idx = 'ssi%'
  ,@nci_only = 1
  ,@online = 0
  ,@create_new = 1

EXECUTE [dbo].[ssi_dropidxsnap] 
   @snap_date = @time
  ,@script = 0

GO

