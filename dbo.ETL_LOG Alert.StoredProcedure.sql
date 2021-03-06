USE [Logging]
GO
/****** Object:  StoredProcedure [dbo].[ETL_LOG Alert]    Script Date: 04/25/2014 10:06:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ETL_LOG Alert]
 
AS
BEGIN
SET NOCOUNT ON;

Declare @Rowcount Int
Set @Rowcount=(select count('X') from Logging.dbo.ETL_Log
where Message  not like '%succeded%' 
 
---AND  Startdate>=Dateadd(day,datediff(day,0,getdate()),0)
---and Enddate< Dateadd(day,datediff(day,0,getdate()),1))
and datediff(hour, Startdate ,getdate())<=2
and datediff(hour, Enddate ,getdate())<= 2)
if @Rowcount>0
begin 

DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)


SET @xml = CAST(( SELECT [ID]AS 'td',''
      ,[GenID] AS 'td',''
      ,CAST([Description] as varchar(100))  AS 'td',''
      ,CAST([Startdate] as datetime) AS   'td',''
      ,CAST([Enddate] as datetime) AS     'td',''
      ,CAST([Process] as varchar(100)) AS     'td',''
      ,CAST([Message] as varchar(1000)) AS     'td','' 
FROM  Logging.dbo.ETL_Log
where Message  not like '%succeded%' 
---AND  Startdate>=Dateadd(day,datediff(day,0,getdate()),0)
---and Enddate< Dateadd(day,datediff(day,0,getdate()),1)
and datediff(hour, Startdate ,getdate())<=2
and datediff(hour, Enddate ,getdate())<= 2

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @body ='<html><body><H3>ETL_LOG</H3>
<table border = 1> 
<tr>
<th> [ID] </th><th> [GenID] </th><th> [Description] </th><th> [Startdate] </th><th> [Enddate] </th><th> [Process] </th><th> [Message] </th></tr>'    

SET @body = @body + @xml +'</table></body></html>'


EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'test', -- replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
@recipients = 'Tobias.Helm@windeln.de;venkatarao.kandra@urban-brand.de;fabian.graf@windeln.de;joan.ferrer@windeln.de;lucie.salwiczek@windeln.de', -- replace with your email address
@subject = 'E-mail about ETL_LOG alert';
end
end
GO
