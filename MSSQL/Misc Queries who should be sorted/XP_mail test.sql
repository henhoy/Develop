DECLARE @ProfileName VARCHAR(255)
DECLARE @AccountName VARCHAR(255)
DECLARE @SMTPAddress VARCHAR(255)
DECLARE @EmailAddress VARCHAR(128)
DECLARE @DisplayUser VARCHAR(128)
DECLARE @SMPort		 VARCHAR(255)
DECLARE @Pwd    VARCHAR(255)

SET @ProfileName = 'henhoy';
SET @AccountName = 'GMailAccount';
SET @SMTPAddress = 'smtp.gmail.com';
SET @EmailAddress = 'henhoy@gmail.com';
SET @DisplayUser = 'Henhoy';
set @SMport        = '465'
set @Pwd   = 'Tru4U&Me'


EXECUTE msdb.dbo.sysmail_add_account_sp
@account_name = @AccountName,
@email_address = @EmailAddress,
@display_name = @DisplayUser,
@mailserver_name = @SMTPAddress,
@username = @EmailAddress,
@password = @Pwd,
@port = @SMPort

EXECUTE msdb.dbo.sysmail_add_profile_sp
@profile_name = @ProfileName 

EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
@profile_name = @ProfileName,
@account_name = @AccountName,
@sequence_number = 1 ;



DECLARE @ProfileName VARCHAR(255)
SET @ProfileName = 'henhoy';

EXEC msdb.dbo.sp_send_dbmail
@recipients=N'hmh@miracleas.dk',
@body= 'Test Email Body', 
@subject = 'Test Email Subject',
@profile_name = @ProfileName



SELECT * FROM msdb.dbo.sysmail_allitems
select * from msdb.dbo.sysmail_log

The mail could not be sent to the recipients because of the mail server failure. 
(Sending Mail using Account 1 (2013-09-13T11:44:12). Exception Message: Cannot send mails to mail server. (The operation has timed out.). )