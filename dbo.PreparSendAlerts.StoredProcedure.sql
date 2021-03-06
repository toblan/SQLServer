USE [Logging]
GO
/****** Object:  StoredProcedure [dbo].[PreparSendAlerts]    Script Date: 04/25/2014 10:06:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[PreparSendAlerts](
  @Runtime datetime
)
  as
begin

  declare @Database_Name nvarchar(255)
  declare @Schema_Name nvarchar(255)
  declare @Table_Name nvarchar(255)
  declare @Procedue_Name nvarchar(255)
  declare @Job_Name nvarchar(255)
  declare @last_Result nvarchar(4000)
  declare @Reciever nvarchar(255)
  declare @last_Reciever nvarchar(255)
  declare @location nvarchar(511)
  declare @message nvarchar(max) = ''
  
  declare @indexStart int
  declare @indexEnd int
  declare @subString nvarchar(4000)
  
 
  truncate table dbo.AlertsToSend
  
  declare alert_cursor2 cursor
  for select last_Result, Reciever, Database_Name, [Schema_Name], Table_Name, Procedue_Name, Job_Name
      from dbo.alertconfig with (nolock)
      where last_executed = @Runtime and last_Result <> 'OK'
  open alert_cursor2
  FETCH NEXT FROM alert_cursor2 INTO @last_Result, @Reciever, @Database_Name, @Schema_Name, @Table_Name, @Procedue_Name, @Job_Name;
  WHILE @@FETCH_STATUS = 0
  begin
    set @location = isnull(@Database_Name,'') + '.' + ISNULL(@Schema_Name,'') + '.'+ isnull(ISNULL(@Procedue_Name,@Table_Name),'') 
    if @Job_Name is not null
      set @location = 'Job: ' + @Job_Name  + ': ' + @location
    set @indexStart = 0
    set @subString = @Reciever
 
    while(len(@subString)>4)
    begin  
		set @indexEnd = PATINDEX('%[ ,;]%',@subString)
		if @indexEnd =0 and LEN(@subString)>4
		  begin
		    --last one
		    insert into dbo.AlertsToSend (Location,[Result],Reciever,[Table_Name])
		        values(@location,@last_Result , @subString,@Table_Name);     
		    Break     
		  end
		if @indexEnd >4 
		  begin
			 set @subString = left(@subString,@indexEnd-1)
		     insert into dbo.AlertsToSend (Location,[Result],Reciever,[Table_Name])
		        values(@location,@last_Result, @subString, @Table_Name);	 
           end
		set @indexStart = @indexStart + @indexEnd
		set @subString = SUBSTRING(@Reciever,@indexStart+1,9999)
    end
    FETCH NEXT FROM alert_cursor2 INTO @last_Result, @Reciever, @Database_Name, @Schema_Name, @Table_Name, @Procedue_Name, @Job_Name;
  end
  
  CLOSE alert_cursor2;
  DEALLOCATE alert_cursor2;
  
exec dbo.SendAlerts
end
GO
