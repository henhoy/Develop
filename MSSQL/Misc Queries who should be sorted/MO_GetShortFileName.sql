USE [HMH]
GO
/****** Object:  UserDefinedFunction [dbo].[GetShortFileName]    Script Date: 01/04/2012 13:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MO_GetShortFileName]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
  execute dbo.sp_executesql @statement = N'
    drop function [dbo].[MO_GetShortFileName]
    '
end

execute dbo.sp_executesql @statement = N'
create function [dbo].[MO_GetShortFileName] (@input nvarchar(255))
returns nvarchar(255)
as
begin
  declare @output nvarchar(255)
  set @output = case
                  when len (@input) > 45 then
                    ''<a class="substr" title="'' + @input + ''">'' +
                     substring(@input,0,charindex(''\'',@input,4)+1)+ ''..\..'' +
                     reverse(substring(reverse(@input),0,charindex(''\'',reverse(@input))+1)) +
                     ''</a>''
                  else @input
                end;
  return (@output);
end;
' 

