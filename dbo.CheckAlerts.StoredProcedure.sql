USE [Logging]
GO
/****** Object:  StoredProcedure [dbo].[CheckAlerts]    Script Date: 04/25/2014 10:06:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[CheckAlerts]
as
begin

declare @id int
declare @SQL_Statement nvarchar(max)
declare @Runtime datetime = GETDATE()
declare @result nvarchar(4000)
declare @last_number bigint
declare @minimuim_increase bigint
declare @num_value  bigint
declare @last_executed datetime
declare @ExtraCheck nvarchar(4000)

declare alert_cursor cursor
  for select id,SQL_Statement,minimuim_increase,last_number,last_executed, ExtraCheck
      from dbo.alertconfig with (nolock)
      where (dateadd(hh,Intervall_hours,last_executed)<@Runtime or last_executed is null)
             and isnull(DoNotExecuteBefore,'00:00:00')<= cast(@Runtime as time)
             and isnull(DoNotExecuteAfter,'23:59:59')>= cast(@Runtime as time) --and ID between '16' and '19'
  open alert_cursor
  FETCH NEXT FROM alert_cursor INTO @id,@SQL_Statement, @minimuim_increase, @last_number, @last_executed, @ExtraCheck;
  WHILE @@FETCH_STATUS = 0
  begin
    if(@ExtraCheck is null)
    begin
      set @result='OK'
    end
    else
    begin
      truncate table dbo.table_for_testresults_do_not_delete 
      exec('insert into logging.dbo.table_for_testresults_do_not_delete (result) ' +
           ' select case when (' + @ExtraCheck + ') then ''OK'' else ''SKIP'' end')
       set @result = (select top 1 result from dbo.table_for_testresults_do_not_delete)  
    end
    if(@result='OK')
    begin  
		truncate table dbo.table_for_testresults_do_not_delete 
		if @minimuim_increase is null
		begin
			exec('insert into logging.dbo.table_for_testresults_do_not_delete (result) ' + @SQL_Statement)
			set @result = (select top 1 result from dbo.table_for_testresults_do_not_delete)
			set @num_value = null
		end
		else
		begin
			if @last_number is null
			  set @last_number = 0
    		exec('insert into logging.dbo.table_for_testresults_do_not_delete (num_value) ' + @SQL_Statement)
			set @num_value = (select top 1 num_value from dbo.table_for_testresults_do_not_delete)
			if (@last_number+@minimuim_increase <=@num_value)
			begin
			 set @result = 'OK'  
			   --set @result = 'The table size increased only ' + cast((@num_value-@last_number) as nvarchar(20)) + ' lines'
			   --set @result = @result + ' in the time of ' + cast(datediff(hh, @last_executed,@Runtime) as nvarchar(50)) + ' hours.'
			end
			else
			begin
			    set @result = 'The table size increased only ' + cast((@num_value-@last_number) as nvarchar(20)) + ' lines'
			   set @result = @result + ' in the time of ' + cast(datediff(hh, @last_executed,@Runtime) as nvarchar(50)) + ' hours.' 
			  
			  ---set @result = 'OK'   
			end
		end 
		update dbo.alertconfig 
		  set last_Executed = @Runtime, last_Result = @result, last_number = @num_value 
		  where ID= @id
		insert into dbo.AlertHistory(ID_Config, Runtime, Result,[number])
		values(                         @id,@Runtime,@result,@num_value)
	end
    FETCH NEXT FROM alert_cursor INTO @id,@SQL_Statement, @minimuim_increase, @last_number, @last_executed, @ExtraCheck;
  end
  CLOSE alert_cursor;
  DEALLOCATE alert_cursor;
  
 exec dbo.PreparSendAlerts @Runtime
end
GO
