--select * from sys.tables

SELECT t.table_name, kcu.column_name, 
  OBJECTPROPERTY(OBJECT_ID(kcu.constraint_name), 'IsPrimaryKey') as IsPrimary,
  OBJECTPROPERTY(OBJECT_ID(kcu.constraint_name), 'CnstIsClustKey') as CnstIsClustKey,
  OBJECTPROPERTY(OBJECT_ID(kcu.constraint_name), 'IsUniqueCnst') as IsUniqueCnst,
  --OBJECTPROPERTY(OBJECT_ID(kcu.table_name), 'TableHasClustIndex') as TableHasClustIndex,
  OBJECTPROPERTY(OBJECT_ID(kcu.constraint_name), 'IsForeignKey') as IsForeignKey,
  OBJECTPROPERTY(OBJECT_ID(kcu.TABLE_NAME), 'IsView') as IsView
FROM information_schema.tables t
left outer join INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu 
on kcu.table_name = t.table_name  and kcu.table_schema = t.table_schema
WHERE 1=1
--and OBJECTPROPERTY(OBJECT_ID(kcu.table_name), 'IsUserTable') = 1
--AND kcu.column_name is null
order by t.table_name


-- select * from information_schema.tables



SELECT SCHEMA_NAME(schema_id) AS SchemaName,name AS TableName
FROM sys.tables
WHERE OBJECTPROPERTY(OBJECT_ID,'TableHasPrimaryKey') = 0
ORDER BY SchemaName, TableName;


SELECT SCHEMA_NAME(schema_id) AS SchemaName,name AS TableName
FROM sys.tables
WHERE OBJECTPROPERTY(OBJECT_ID,'TableHasUniqueCnst') = 0
ORDER BY SchemaName, TableName;


SELECT SCHEMA_NAME(schema_id) AS SchemaName,name AS TableName
FROM sys.tables
WHERE OBJECTPROPERTY(OBJECT_ID,'TableHasUniqueCnst') = 0 or OBJECTPROPERTY(OBJECT_ID,'TableHasUniqueCnst') = 0
ORDER BY SchemaName, TableName;
