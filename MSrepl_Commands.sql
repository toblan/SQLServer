/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [publisher_database_id]
      ,[xact_seqno]
      ,[type]
      ,[article_id]
      ,[originator_id]
      ,[command_id]
      ,[partial_command]
      ,[command]
      ,[hashkey]
      ,[originator_lsn]
  FROM [distribution].[dbo].[MSrepl_commands] WITH (READUNCOMMITTED)
  Where publisher_database_id = 3 and article_id = '6360'
  --where [xact_seqno] = 0x0002C59B0002671000EA
 order by [xact_seqno]
 
 
 SELECT COUNT(*)
 FROM [distribution].[dbo].[MSrepl_commands] WITH (READUNCOMMITTED)
 
 