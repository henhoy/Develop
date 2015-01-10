exec sp_configure
go

exec sp_configure 'show advanced option', 1
reconfigure
go

exec sp_configure 'Ole Automation Procedures', 1
reconfigure
go


exec sp_configure
go

--exec sp_configure 'xp_cmdshell', 1
-- Configuration option 'xp_cmdshell' changed from 0 to 1. Run the RECONFIGURE statement to install.

exec sp_configure 'Ole Automation Procedures', 0
reconfigure
go

exec sp_configure 'show advanced option', 0
reconfigure
go

exec sp_configure
go
