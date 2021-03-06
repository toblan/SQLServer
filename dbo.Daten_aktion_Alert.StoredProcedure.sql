USE [Logging]
GO
/****** Object:  StoredProcedure [dbo].[Daten_aktion_Alert]    Script Date: 04/25/2014 10:06:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Daten_aktion_Alert]
 
AS
BEGIN
SET NOCOUNT ON;

Declare @Rowcount Int
Set @Rowcount=(select count('X') from [BI_Data].[dbo].[Datenaction_test])

if @Rowcount>0
begin 

DECLARE @xml NVARCHAR(MAX)
DECLARE @body NVARCHAR(MAX)


SET @xml = CAST(( SELECT [EAN] AS 'td',''
      ,CAST([Aktion] as nvarchar(255))  AS 'td',''
      ,CAST([Start] as date) AS   'td',''
      ,CAST([Ende] as date) AS     'td',''
      ,CAST([Vorlauf] as date) AS     'td',''
      ,CAST([Menge] as int) AS     'td','' 
FROM  [BI_Data].[dbo].[Datenaction_test]

FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))

SET @body ='<html><body><H3>New_Daten_Aktion</H3>
<table border = 1> 
<tr>
<th> [EAN] </th><th> [Aktion] </th><th> [Start]  </th><th> [Ende] </th><th> [Vorlauf] </th><th> [Menge] </th></tr>'    

SET @body = @body + @xml +'</table></body></html>'


EXEC msdb.dbo.sp_send_dbmail
@profile_name = 'test', -- replace with your SQL Database Mail Profile 
@body = @body,
@body_format ='HTML',
@recipients = 'venkatarao.kandra@urban-brand.de;Tobias.Helm@windeln.de;nikola.kellhammer@windeln.de;josef.bauer@urban-brand.de;marina.bub@windeln.de;franziska.lausch@windeln.de;michaela.schneider@windeln.de;kristina.wehrhahn@windeln.de', -- replace with your email address
@subject = 'Feedback for new Daten_aktion';
end
end 


----;Tobias.Helm@windeln.de;nikola.kellhammer@windeln.de;josef.bauer@urban-brand.de;marina.bub@windeln.de;franziska.lausch@windeln.de;michaela.schneider@windeln.de
GO
