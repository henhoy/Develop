/*
IF OBJECT_ID (N'dbo.RegexMatch') IS NOT NULL
   DROP FUNCTION dbo.RegexMatch
GO
CREATE FUNCTION dbo.RegexMatch
    (
      @pattern VARCHAR(2000),
      @matchstring VARCHAR(MAX)--Varchar(8000) got SQL Server 2000
    )
RETURNS INT
/* The RegexMatch returns True or False, indicating if the regular expression matches (part of) the string. (It returns null if there is an error).
When using this for validating user input, you'll normally want to check if the entire string matches the regular expression. To do so, put a caret at the start of the regex, and a dollar at the end, to anchor the regex at the start and end of the subject string.
*/ 
AS BEGIN
    DECLARE @objRegexExp INT,
        @objErrorObject INT,
        @strErrorMessage VARCHAR(255),
        @hr INT,
        @match BIT

    SELECT  @strErrorMessage = 'creating a regex object'
    EXEC @hr= sp_OACreate 'VBScript.RegExp', @objRegexExp OUT
    IF @hr = 0 
        EXEC @hr= sp_OASetProperty @objRegexExp, 'Pattern', @pattern
        --Specifying a case-insensitive match 
    IF @hr = 0 
        EXEC @hr= sp_OASetProperty @objRegexExp, 'IgnoreCase', 1
        --Doing a Test' 
    IF @hr = 0 
        EXEC @hr= sp_OAMethod @objRegexExp, 'Test', @match OUT, @matchstring
--    IF @hr &lt;&gt; 0 
    IF @hr <> 0
        BEGIN
            RETURN NULL
        END
    EXEC sp_OADestroy @objRegexExp
    RETURN @match
   END
GO

*/

SELECT dbo.RegexMatch('\b(\w+)\s+\1\b','this has has been repeated')--1
SELECT dbo.RegexMatch('\b(\w+)\s+\1\b','this has not been repeated')--0

--find a word near another word (in this case 'for' and 'last' 1 or 2 words apart)
SELECT dbo.RegexMatch('\bfor(?:\W+\w+){1,2}?\W+last\b', 'You have failed me for the last time, Admiral')--1
SELECT dbo.RegexMatch('\bfor(?:\W+\w+){1,2}?\W+last\b', 'You have failed me for what could be the last time, Admiral')--0

--is this likely to be a valid credit card
SELECT dbo.RegexMatch('^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6011[0-9]{12}|3(?:0
[0-5]|[68][0-9])[0-9]{11}|3[47][0-9]{13}|(?:2131|1800)\d{11})$','4953129482924435')          

--IS this a valid ZIP code
SELECT dbo.RegexMatch('^[0-9]{5,5}([- ]?[0-9]{4,4})?$','02115-4653')

--is this a valid Postcode
SELECT dbo.RegexMatch('^([Gg][Ii][Rr] 0[Aa]{2})|((([A-Za-z][0-9]{1,2})|(([A-Za-z][A-Ha
-hJ-Yj-y][0-9]{1,2})|(([A-Za-z][0-9][A-Za-z])|([A-Za-z][A-Ha-hJ-Yj-y][0-9]?[A-Za-z])))
) {0,1}[0-9][A-Za-z]{2})$','RG35 2AQ')

--is this a valid European date
SELECT dbo.RegexMatch('^((((31\/(0?[13578]|1[02]))|((29|30)\/(0?[1,3-9]|1[0-2])))\/(1[
6-9]|[2-9]\d)?\d{2})|(29\/0?2\/(((1[6-9]|[2-9]\d)?(0[48]|[2468][048]|[13579][26])|((16
|[2468][048]|[3579][26])00))))|(0?[1-9]|1\d|2[0-8])\/((0?[1-9])|(1[0-2]))\/((1[6-9]|[2
-9]\d)?\d{2})) (20|21|22|23|[0-1]?\d):[0-5]?\d:[0-5]?\d$','12/12/2007 20:15:27')

--is this a valid currency value (dollar)
SELECT dbo.RegexMatch('^\$(\d{1,3}(\,\d{3})*|(\d+))(\.\d{2})?$','$34,000.00')

--is this a valid currency value (Sterling)
SELECT dbo.RegexMatch('^\&pound;(\d{1,3}(\,\d{3})*|(\d+))(\.\d{2})?$',
'&pound;34,000.00')

--A valid email address?
SELECT dbo.RegexMatch('^(([a-zA-Z0-9!#\$%\^&\*\{\}''`\+=-_\|/\?]+(\.[a-zA-Z0-9!#\$%\^&
\*\{\}''`\+=-_\|/\?]+)*){1,64}@(([A-Za-z0-9]+[A-Za-z0-9-_]*){1,63}\.)*(([A-Za-z0-9]+[A
-Za-z0-9-_]*){3,63}\.)+([A-Za-z0-9]{2,4}\.?)+){1,255}$','Phil.Factor@simple-Talk.com')
/