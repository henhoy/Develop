DECLARE @dbName varchar(100)
DECLARE @sqlCommand nvarchar(300) 
DECLARE @errorMsg nvarchar(100) 
DECLARE @Return INT


DECLARE myCursor CURSOR FAST_FORWARD FOR 
SELECT a.name AS LogicalName from SYS.databases a 
WHERE a.database_id > 4 --Only User DB 
and state = 0
ORDER BY name DESC

OPEN myCursor
  
FETCH NEXT FROM myCursor INTO @dbName
WHILE (@@FETCH_STATUS <> -1) 
BEGIN 

SET @errorMsg = 'DB ['+@dbName+'] is corrupt'
SET @sqlCommand = 'Use ['+@dbName+']' 

SET @sqlCommand += 'DBCC CHECKDB (['+@dbName +']) WITH PHYSICAL_ONLY,NO_INFOMSGS, ALL_ERRORMSGS;'

print @sqlCommand
EXEC @Return = sp_executesql @sqlCommand 

IF @Return <> 0 RAISERROR (@errorMsg , 11, 1)

FETCH NEXT FROM myCursor INTO @dbName 
END
  
CLOSE myCursor 
DEALLOCATE myCursor