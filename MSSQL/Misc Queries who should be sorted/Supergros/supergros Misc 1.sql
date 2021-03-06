USE [tpcc]
GO

declare @sqlcmd nvarchar(500), @result nvarchar(500);

declare @ERROR_NUMBER		int,
		@ERROR_SEVERITY		int,
		@ERROR_STATE		int,
		@ERROR_MESSAGE		nvarchar(max);

set @result = 0
set @sqlcmd =  N'ALTER INDEX [STOCK_I1] ON [dbo].[STOCK] REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)'

--select @sqlcmd

begin try
  exec (@sqlcmd);
end try

begin catch
  --select @ERROR_NUMBER = ERROR_NUMBER(), @ERROR_SEVERITY = ERROR_SEVERITY(), @ERROR_STATE = ERROR_STATE(), @ERROR_MESSAGE = ERROR_MESSAGE()
  --select @ERROR_NUMBER, @ERROR_SEVERITY, @ERROR_STATE, @ERROR_MESSAGE
  --select @sqlcmd
  set @result = 1;
end catch

--set @result = @@ERROR

select @result

GO
