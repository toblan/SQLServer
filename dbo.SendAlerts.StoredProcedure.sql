USE [Logging]
GO
/****** Object:  StoredProcedure [dbo].[SendAlerts]    Script Date: 04/25/2014 10:06:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SendAlerts]
 
AS
BEGIN

declare @reciever nvarchar(255);

declare alert_cursor3 cursor
  for select Reciever
  from dbo.AlertsToSend with (nolock)
  group by Reciever
  
  open alert_cursor3
  FETCH NEXT FROM alert_cursor3 INTO @Reciever;
  WHILE @@FETCH_STATUS = 0
begin 

DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)

SET @xml = CAST(( SELECT Location AS 'td',''
        ,[Result] AS 'td',''
        ,[Table_Name] as 'td',''
FROM  dbo.AlertsToSend
where reciever=@reciever

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @body ='<html><body><H3>Alerts</H3>
<table border = 1> 
<tr>
<th> Location </th><th> Message </th><th> Table_Name </th></tr>'    

SET @body = @body + @xml +'</table></body></html>'


EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'test', -- replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
@recipients = @reciever,
@subject = 'windeln.de alert';
FETCH NEXT FROM alert_cursor3 INTO @Reciever;
end

CLOSE alert_cursor3;
DEALLOCATE alert_cursor3;

end
GO
