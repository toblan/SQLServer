select article, article_id from distribution.dbo.msarticles 
WHERE publication_id = 3 
--AND article ='Urban-Brand GmbH$Item'

SELECT publisher_database_id, article_id, COUNT(*)FROM distribution.dbo.MSrepl_commands c 
WITH(READUNCOMMITTED)
--WHERE article_id = 6360
group by publisher_database_id, article_id
order by COUNT(*) desc


Select * FROM distribution.dbo.MSrepl_commands c 
WITH(READUNCOMMITTED)

sp_browsereplcmds '0x0002C6470002181A0148', '0x0002C6470002181A0148'
