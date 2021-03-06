USE [HMH]
GO
/****** Object:  UserDefinedFunction [dbo].[GetShortName]    Script Date: 01/04/2012 13:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MO_GetShortName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
  execute dbo.sp_executesql @statement = N'
    drop function [dbo].[MO_GetShortName]
    '
end

execute dbo.sp_executesql @statement = N'
create function [dbo].[MO_GetShortName] (@input nvarchar(255))
returns nvarchar(255)
as
begin
  declare @output nvarchar(255)
  set @output = case when len(@input) > 27 then ''<a class="substr" title="'' + @input + ''">'' + substring(@input,1,24) + ''...'' else @input end;
  return (@output);
end;
'