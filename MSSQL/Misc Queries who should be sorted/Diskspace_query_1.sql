--EXEC master.dbo.xp_fixeddrives

-- 1 - Declare variables
DECLARE @MBfree int
DECLARE @CMD1 varchar(1000)

-- 2 - Initialize variables
SET @MBfree = 0
SET @CMD1 = ''

-- 3 - Create temp tables
CREATE TABLE #tbl_xp_fixeddrives
(Drive varchar(2) NOT NULL,
[MB free] int NOT NULL)

-- 4 - Populate #tbl_xp_fixeddrives
INSERT INTO #tbl_xp_fixeddrives(Drive, [MB free])
--EXEC master.sys.xp_fixeddrives
EXEC master.dbo.xp_fixeddrives

-- 5 - Initialize the @MBfree value
--SELECT @MBfree = [MB free]
select Drive, [MB free] as "MB Free"
FROM #tbl_xp_fixeddrives 
--WHERE Drive = @Drive

-- 6 - Determine if sufficient fre space is available
----IF @MBfree > @MinMBFree
---- BEGIN
----  RETURN
---- END
----ELSE
---- BEGIN
----  RAISERROR ('*** ERROR *** - Insufficient disk space.', 16, 1)
---- END

-- 7 - DROP TABLE #tbl_xp_fixeddrives
DROP TABLE #tbl_xp_fixeddrives