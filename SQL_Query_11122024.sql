
--- sparse column -----------

CREATE TABLE ajay
(	ID INT IDENTITY (1,1),
	FirstCol INT SPARSE, ---- saves space for columns that contain many NULL values
	SecondCol VARCHAR (100), 	
	ThirdCol SmallDateTime,
	ProductID uniqueidentifier DEFAULT NEWID() PRIMARY KEY	)   

sp_spaceused 'ajay'

drop table ajay

----NEWID() & TableSample--------------------

Select top 3 * From dbo.Customer
order by NEWID()  ---- get 3 random records every time(use in small table) // generates a Global unique identifier (GUID) for each row.

--NEWSEQUENTIALID() --sequential(across different databases or servers.)
					--only use NEWSEQUENTIALID() with default constraints, meaning it can't be used directly in an INSERT statement like NEWID()
--newid() 		    -- non sequential (across different databases or servers.) ---internally): 16 bytes. & human readability: 36 characters (incl -)

Select * From dbo.Customer tablesample (30 percent) ----use, when LARGE TABLES
Select TOP 1 * From dbo.Customer tablesample (2 rows)
Select  * From dbo.Customer tablesample (2 rows)

/*Note: 
1.IN small table with few pages , you might not want to use TableSample as it will include or exclude the entire page.
ex.If I would run this query on small table, Sometime I will get no records 
 and when get the records, it will return all the records as they are placed on single page.*/

--- OFFSET -----------------------------------------------------
-- order by must used in offset 
SELECT *
FROM Cnfcity
ORDER BY CityName
OFFSET 6 ROWS   -- It will not select first 6 rows
FETCH NEXT 4 ROWS ONLY -- it will select next 4 rows only from offset 6 rows.

Select *
from dbo.TotalSale 
order by id
OFFSET 5 rows --output: 6,7,8,9,10,11

select * from dbo.TotalSale 
order by id
OFFSET 0 ROWS FETCH NEXT 3 ROWS ONLY; --output: 1,2,3 

-- Running total -----------
-- identity id needs some case

CREATE TABLE table_sujith(id INT)

INSERT INTO table_sujith
SELECT 100
UNION ALL
SELECT 100
UNION ALL
SELECT 200

ALTER TABLE table_sujith ADD rowid INT identity

SELECT id,
	(SELECT sum(id) FROM table_sujith WHERE rowid <= s.rowid) as RunningTotal
FROM table_sujith s 

SELECT * FROM table_sujith
drop table table_sujith

--or
SELECT rowid, id, 
       SUM(id) OVER (ORDER BY rowid) AS RunningTotal
FROM table_sujith;

--Or
WITH RunningTotals AS (
    SELECT rowid, SUM(id) OVER (ORDER BY rowid) AS RunningTotal
    FROM table_sujith
)
SELECT t.rowid, t.id, rt.RunningTotal
FROM table_sujith t
JOIN RunningTotals rt ON t.rowid = rt.rowid;

-- # VS ## Temporarty Table -------------------------------------------

-- ##TEMP_SUJITH Golabal temperary table will work in accross database in single server until the last session using it disconnects 

CREATE TABLE ##TEMP_SUJITH(ID INT)
select * from ##TEMP_SUJITH

--- JOINS ----------------------------------------------
-- NATURAL JOIN //automatically joins two tables based on all columns with the same name with out on condition
-- JOIN (INNER JOIN) 

--- Primary & Foreign key & Cascase ----------------------------------

CREATE TABLE dbo.Customer (
	Customerid INT Identity(1,1)
	,FName VARCHAR(100) Not Null
	,LName VARCHAR(100)
	,SSN VARCHAR(10) Not Null,
	Constraint Pk_FName_SSN Primary Key (FName,SSN))

CREATE TABLE dbo.Orders (
	OrderId INT Identity(1, 1)
	,OrderitemName VARCHAR(50)
	,OrderItemAmt INT
	,Customer_id INT FOREIGN KEY REFERENCES Customer(CustomerId))
--or
CREATE TABLE dbo.Orders (
	OrderId INT Identity(1, 1)
	,OrderitemName VARCHAR(50)
	,OrderItemAmt INT
	,FirstName VARCHAR(100),
		SSN VARCHAR(10) Not Null,
		Constraint Fk_Order_Customer_FName_SSN 
		FOREIGN KEY (FirstName,SSN) REFERENCES dbo.Customer(FName,SSN))  
		
--don''t have to have the same column name in both tables FName or Firstname
--THE ORDER OF COLUMNS SHOULD BE SAME WHAT YOU HAVE IN PRIMARY KEY WHEN WE CREATE FOREIGN KEY CONSTRAINT.
--or
 Alter table dbo.Orders
     Add Constraint Fk_Order_Customer_FName_SSN 
     FOREIGN KEY (FirstName,SSN) REFERENCES dbo.Customer(FName,SSN)

Alter table dbo.Orders WITH NOCHECK -- ignore the check for existing data
Add Constraint Fk_CustomerId  
Foreign Key(CustomerId) References dbo.Customer(CustomerId)

Alter table dbo.Orders with check
Add Constraint Fk_CustomerId  
Foreign Key(CustomerId) References dbo.Customer(CustomerId)

--- CASCADE -----------------------------------

CREATE TABLE products_sujith
( product_id INT PRIMARY KEY,
	product_name VARCHAR(50) NOT NULL,
	category VARCHAR(25));

CREATE TABLE inventory_sujith
( inventory_id INT PRIMARY KEY,
	product_id INT NOT NULL,
	quantity INT,
	CONSTRAINT fk_inv_product_id FOREIGN KEY (product_id) REFERENCES products_sujith (product_id)
	ON DELETE CASCADE );

ALTER TABLE inventory
ADD CONSTRAINT fk_inv_product_id FOREIGN KEY (product_id) REFERENCES products (product_id)
	ON DELETE CASCADE;

insert into products_sujith
select 1,'aa','cc'
union all
select 2,'aa','cc'

insert into inventory_sujith
select 1,1,20
union all
select 2,2,50000

select * from products_sujith
select * from inventory_sujith

delete from products_sujith where product_id = 1

CREATE TABLE inventory_sujith
( inventory_id INT PRIMARY KEY,
	product_id INT NULL,
	quantity INT,
	CONSTRAINT fk_inv_product_id FOREIGN KEY (product_id) REFERENCES products_sujith (product_id)
	ON DELETE SET NULL -- -- when we delete the records in primary table, then foreigh key table values 	as NULL
);

delete from products_sujith where product_id = 1

drop table products_sujith
drop table inventory_sujith

-- check ----------------------

Create table dbo.Customer
(
FName VARCHAR(100) Not Null,
LName VARCHAR(100),
StreetAddress VARCHAR(255),
Constraint Chk_dbo_Customer_FName_AlphabetsOnly Check  (FName not like '%[^a-z]%'))

Alter table dbo.Employee with nocheck Add Constraint Chk_dbo_Employee_FName Check (FName not like '%[^a-z]%') 

-- 
CREATE TABLE dbo.Customer (
    CustomerId INT identity(1, 1)
    ,NAME VARCHAR(100)
    ,Age INT
    ,AgeType VARCHAR(15)
    ,CONSTRAINT dbo_Customer_AgeAndAgeType CHECK (
        (
            Age <= 17
            AND AgeType = 'Child'
            )
        OR (
            Age > 17
            AND Age < 65
            AND AgeType = 'Adult'
            )
        OR (
            Age >= 65
            AND AgeType = 'Senior'
            )
        )
    )

-- default and unique constraint ----------

Alter table dbo.Customer
Add Constraint DF_dbo_Customer_CountryName Default  'USA' for CountryName
,Constraint  DF_dbo_Customer_Region default 'North America' for Region

CREATE TABLE [dbo].[Customer](
    [FirstName] [varchar](50) NULL,
    [LastName] [varchar](50) NULL,
    [SSN] VARCHAR(11),
    Constraint UQ_Dbo_Customer_FName_LName Unique(FirstName,LastName)
) 

-- identity --------------------------------------------------------------------

-- if we want to remove the identity in existing column, 1st drop that column and create new column with identity
-- we can't alter existing non identity column to identity column or indentity column to non identity column

CREATE TABLE dbo.Customer(
  ID INT IDENTITY(1,1)
, CustomerCode VARCHAR(50)
, FirstName VARCHAR(50)
, LastName VARCHAR(50))

SET IDENTITY_INSERT dbo.Customer ON

INSERT INTO dbo.Customer ( ID,CustomerCode,FirstName,LastName)
VALUES (-1,'UNKNOWN','UNKNOWN','UNKNOWN')

SET IDENTITY_INSERT Dbo.Customer OFF

SELECT * FROM dbo.Customer

DBCC CHECKIDENT ('dbo.Customer', RESEED, 5);

INSERT INTO dbo.Customer ( CustomerCode,FirstName,LastName)
VALUES ('UNKNOWN','UNKNOWN','UNKNOWN')

/** Drop Identity ********/
ALTER TABLE dbo.Employee ADD TestId INT --Add a new column with any name

ALTER TABLE dbo.Employee alter column TestId bigINT

UPDATE dbo.Employee SET TestId=Id --Update the Records in newly Added column , in our case TestID

ALTER TABLE dbo.Employee DROP COLUMN Id --Drop Identity Column

select * from Employee
--Rename the newly Added Column to Identity Column you had at first.
EXEC sp_rename 'dbo.Employee.TestId','Id','COLUMN'  

----String Function -------------------------------------------------------------------------------------

SELECT CHARINDEX('t', 'Custometr',5) AS MatchPosition; --3rd parameter optional(the search starting)

SELECT CHARINDEX('World','Hello World'),
		CHARINDEX('World','Hello World',8),
		CHARINDEX('World','Hel World lo World',8) --last parameter is optional parameter

SELECT ASCII('A'), ASCII('AB') , ASCII('B')
SELECT LEFT('Hello World',5) , RIGHT('Hello Wolrd',5)
SELECT LOWER('Hello World') , UPPER('Hello World')
select PATINDEX('%[0-9]M%','PC-105M5MNC')
select PATINDEX('%M%','PC-105M5MNC')
SELECT SUBSTRING('Hello World',1,5), SUBSTRING('Hello World',7,2)

SELECT QUOTENAME('abc','{'), --only brackets [], single quotes ‘’, double quotes “”, parenthesis (), braces {}, signs <>.
		QUOTENAME('abc',',') --The default quote characters are brackets []. ,Note that only a few characters are accepted, or the function will return NULL,

SELECT REPLICATE('100',5)
SELECT REVERSE('Hello World')
SELECT REPLACE('Hello World','Hello','This is my')
SELECT 'Hello' + SPACE(3) + 'World'

------------- Conversion functions (PARSE, TRY_PARSE, TRY_CONVERT) -----
--TRY_CONVERT function is protecting from data converting errors during query execution

SELECT TRY_CONVERT(INT,'AnyString') AS ConvertFunc -- null
SELECT CONVERT(INT,'AnyString') AS ConvertFunc -- ERROR

-- previous we can not convert string into int
SELECT CONVERT(int, '100.000') AS CONINT; --err
SELECT CAST('100.000' AS int) AS AAA  --err
-- we can result as 
SELECT CONVERT(varchar, '100.000') AS CONINT; --100.000
SELECT CAST('100.000' AS varchar) AS AAA   --100.000
-- we can convert decimal into int
SELECT CONVERT(INT, 100.000) AS CONINT  --100
SELECT CAST(100.000 AS INT) AS AAA   --100

SELECT PARSE('A100.000' AS INT) AS ValueInt; -- error
SELECT PARSE('100.00' AS INT) AS ValueInt; --100
SELECT PARSE('100' AS INT) AS ValueInt; -- 100

SELECT PARSE('30 July 2011' AS DATETIME) AS ValueDT
SELECT PARSE('2011 July 30' AS DATETIME) AS ValueDT
SELECT PARSE('July 30  2011' AS DATETIME) AS ValueDT
SELECT PARSE('30 2011 Jul ' AS DATETIME) AS ValueDT

SELECT TRY_PARSE('A100.000' AS INT) AS ValueInt  -- null   (diff PARSE show Error but TRY_PARSE show NULL)
SELECT TRY_PARSE('100.000' AS INT) AS ValueInt  -- 100
SELECT TRY_PARSE('100' AS INT) AS ValueInt --100

SELECT TRY_CONVERT(INT, 'A100.000') AS ValueInt;  -- null
SELECT TRY_CONVERT(INT, '100.00') AS ValueInt;  -- null
SELECT TRY_CONVERT(INT, '100') AS ValueInt;  -- 100

------------- String functions(CONCAT, FORMAT) -------------------

SELECT CONCAT(1, 2, 3, 4) AS SingleString  -- 1234
SELECT CONCAT('One',1, 1.1, GETDATE()) AS SingleString  -- One11.1Jul  5 2017  1:54PM
SELECT CONCAT('One',2,NULL) AS SingleString -- One2
SELECT CONCAT('One',2,isnull(NULL,'-'),4,'abc') AS SingleString -- One24abc
SELECT CONCAT('','','','') AS SingleString -- 
SELECT CONCAT('','','','',2) AS SingleString -- 
SELECT CONCAT(NULL, NULL) AS SingleString -- 
	
  AS FR_Result; -- 06/07/2017
SELECT FORMAT ( getdate(), 'd', 'de-DE' ) AS DE_Result; -- 06.07.2017

SELECT FORMAT ( GETDATE(), 'm', 'en-US' ) AS US_Result; --July 6
SELECT FORMAT ( GETDATE(), 'MM', 'en-US' ) AS US_Result; --07
SELECT FORMAT ( GETDATE(), 'mm', 'en-US' ) AS US_Result; --05 
SELECT FORMAT ( GETDATE(), 'MMM', 'en-US' ) AS US_Result --Jul
SELECT FORMAT ( GETDATE(), 'MMMM', 'en-US' ) AS US_Result --July

-- Year
SELECT FORMAT ( GETDATE(), 'y', 'en-US' ) AS US_Result; -- July 2017
SELECT FORMAT ( GETDATE(), 'yy', 'en-US' ) AS US_Result; --17
SELECT FORMAT ( GETDATE(), 'yyy', 'en-US' ) AS US_Result; --2017

SELECT FORMAT (GETDATE(), N'dddd MMMM dd, yyyy', 'ta') AS English_Result; --வியாழக்கிழமை ஜூலை 06, 2017
SELECT FORMAT (GETDATE(), N'dddd MMMM dd yyyy') AS English_Result;

---------------- logical functions(IIF, CHOOSE) -----------------------------
	
SELECT IIF ( -1 < 1, 'TRUE', 'FALSE' ) AS Result;  --like CASE 
SELECT IIF ( -1 < 1, IIF ( 1=1, 'Inner True', 'Inner False' ), 'FALSE' ) AS Result;

SELECT GETDATE(),
	DATEPART(dw, GETDATE()) DayofWeek,
	DATENAME(dw, GETDATE()) DayofWeek,
	CHOOSE(DATEPART(dw,GETDATE()), 'WEEKEND','Weekday','Weekday','Weekday','Weekday','Weekday','WEEKEND') WorkDay
	
SELECT CHOOSE ( 0, 'TRUE', 'FALSE', 'Unknown' ) AS Returns_Null; -- NULL
SELECT CHOOSE ( 1, 'TRUE', 'FALSE', 'Unknown' ) AS Returns_First; --TRUE
SELECT CHOOSE ( 2, 'TRUE', 'FALSE', 'Unknown' ) AS Returns_Second; --FALSE
SELECT CHOOSE ( 3, 'TRUE', 'FALSE', 'Unknown' ) AS Returns_Third; -- Unknown
SELECT CHOOSE ( 4, 'TRUE', 'FALSE', 'Unknown' ) AS Result_NULL;  -- NULL

SELECT CHOOSE ( 1.1, 'TRUE', 'FALSE', 'Unknown' ) AS Returns_First; --TRUE (1)
SELECT CHOOSE ( 2.9, 'TRUE', 'FALSE', 'Unknown' ) AS Returns_Second --FALSE (bcz it convert 2.9 to 2)

---DATE ------- ----------------------------------------------------------

Date function
Date Part
Date Parts an integer which represents the specified part of a date. 
DATENAME (date part, value)

SELECT DATEPART (YEAR, GETDATE ()) as Year, -- 2005
       DATEPART (WEEK, GETDATE ()) as Week, -- 33
       DATEPART (DAYOFYEAR, GETDATE ()) as DayOfYear, -- 222
       DATEPART (MONTH, GETDATE ()) as Month, -- 8
       DATEPART (DAY, GETDATE ()) as Day, -- 10
       DATEPART (WEEKDAY, GETDATE ()) as WEEKDAY -- 2

DATENAME
DateName is a very useful function that is used to return various parts of a date such as the name of the month, or day of the week corresponding to a particular date.

	   DATENAME (year, GETDATE ()) as Year, --2005
	   DATENAME (week, GETDATE ()) as Week, -- 33
       DATENAME (dayofyear, GETDATE ()) as DayOfYear, -- 222
       DATENAME (month, GETDATE ()) as Month,	 -- August
       DATENAME (day, GETDATE ()) as Day, -- 10
       DATENAME (weekday, GETDATE ()) as WEEKDAY – Monday
DATEADD
SELECT DATEADD (DAY, 30, GETDATE ())
DATEDIFF
SELECT DATEDIFF (DAY, '01/01/2009', GETDATE ())

SELECT ISDATE ('07/44/09')
SELECT MONTH (getdate ()), 
SELECT DAY (getdate ()), 
SELECT YEAR (getdate ())


Time			hh:mm:ss[.nnnnnnn]
Date			YYYY-MM-DD
SmallDateTime	YYYY-MM-DD hh:mm:ss
DateTime		YYYY-MM-DD hh:mm:ss[.nnn]
DateTime2		YYYY-MM-DD hh:mm:ss[.nnnnnnn]
DateTimeOffset	YYYY-MM-DD hh:mm:ss[.nnnnnnn] [+|-]hh:mm

Select SYSDATETIME() as [SYSDATETIME]  --2021-02-12 00:50:11.0152162 (server’s date and time)
Select SYSDATETIMEOffset() as [SYSDATETIMEOffset]  --2021-02-12 00:50:11.0152162 +05:30 (server’s date and time, along with UTC offset)
Select GETUTCDATE() as [GETUTCDATE] -- 2021-02-11 19:20:11.060 (returns date and GMT (Greenwich Mean Time ) time)
Select GETDATE() as [GETDATE]  --2021-02-12 00:50:11.060 (returns server date and time)

SELECT DATEADD(month, 2, GETDATE()) AS NewDate;

SELECT
  DATENAME(DW, GETDATE()),
  DATENAME(DAY, GETDATE()),
  DATENAME(MONTH, GETDATE()) ,
  DATENAME(YEAR, GETDATE()) 

SELECT DATEFROMPARTS (2010,12,31) AS Result					  --( year, month, day)
SELECT SMALLDATETIMEFROMPARTS (2010,12,31,23,59) AS Result    --( year, month, day, hour, minute ) (2010-12-31 23:59:00)
SELECT DATETIME2FROMPARTS (2010,12,31,23,59,59,0,0) AS Result;--( year, month, day, hour, minute, seconds, fractions, precision ) [2010-12-31 23:59:59]
SELECT DATETIMEFROMPARTS (2010,12,31,23,59,59,0) AS Result;   --( year, month, day, hour, minute, seconds, milliseconds ) [2010-12-31 23:59:59.000]
SELECT DATETIMEOFFSETFROMPARTS (2010,12,31,14,23,23,0,12,0,7) AS Result; --( year, month, day, hour, minute, seconds, fractions, hour_offset, minute_offset, precision )[2010-12-31 14:23:23.0000000 +12:00]
SELECT TIMEFROMPARTS (23,59,59,0,0) AS Result;				  --( hour, minute, seconds, fractions, precision ) [23:59:59]

SELECT EOMONTH(GETDATE()) LastDayofMonth --to find end of the month
SELECT EOMONTH('20120201') LeapYearFebLastDay --to find LeapYear(29)
SELECT EOMONTH(GETDATE(),-1) PreviousMonthLastDay; --last date of previous month
SELECT EOMONTH(GETDATE(),1) NextMonthLastDay;
SELECT REPLACE(EOMONTH(GETDATE(),1),31,1) NextMonthFirstDay

SELECT DATEADD(d,1,EOMONTH(GETDATE(),-1)) thisMonthFirstDay --2021-03-01
SELECT DATEADD(d,1,EOMONTH(GETDATE(),1)) Next_next_MonthFirstDay --2021-05-01
SELECT DATEADD(d,1,EOMONTH(GETDATE())) NextMonthFirstDay --2021-04-01
SELECT EOMONTH(GETDATE()) LastDayofMonth --2021-03-31
SELECT DATENAME(dw,EOMONTH(GETDATE())) LastDayofMonthDay; --Monday

SELECT YEAR(DATEADD(YY,2,GETDATE()))

SELECT 935 AS [number], FORMAT (935,'000000') AS length_6

SELECT REPLICATE('0',4-LEN('31')) +'31'
SELECT FORMAT(31,'0000')
	
---------------Carriage Return & Line Feed.****************
/*
CHAR(13) is Carriage Return (\r)
CHAR(10) is Line Feed. (\n)
char(9) for TAB

How to remove carriage return line feed from SQL Server for displaying in Excel
Carriage return (chr13) + line feed (chr10) is the default line terminator for Windows, */

SELECT Notify,REPLACE(AdrLine1, CHAR(13) + CHAR(10),' ') AS ADDRES FROM NotifyMaster

DECLARE @String VARCHAR(100)
DECLARE @CorrectedString VARCHAR(100)
 
SELECT @String = 'abcd	ab		cd
zyx	vrsuv	rsm
	
	nm'
	
SELECT @CorrectedString = replace(replace(REPLACE(@String, CHAR(13),''),char(10),''),char(9),' ')
select @CorrectedString

-----------
DECLARE @NewLineChar AS CHAR(2) = CHAR(13) + CHAR(10)
PRINT ('SELECT FirstLine AS FL ' +@NewLineChar+ 'SELECT SecondLine AS SL' )

------
DECLARE @text NVARCHAR(100)
SET @text = 'This is line 1.' + CHAR(13) + 'This is line 2.'
SELECT @text
print @text  -- message

-- remove 1st 2 and last 2 string ------------------

declare @a varchar(30)
set @a = 'NetAccessIndiaLimited'
select SUBSTRING(@a,3,len(@a)-4)

SELECT SUBSTRING('software',5,3)--war
SELECT STUFF('software',1,4,'hard')--hardware
----
DECLARE @GMAIL VARCHAR(50)='NETAccessIndiaLimited@GMAIL.COM'
SELECT CHARINDEX('@',@GMAIL) -- 22
SELECT PATINDEX('%@%',@GMAIL) -- 22 (find particular word in multiple mail id )

SELECT RIGHT(@GMAIL,LEN(@GMAIL)-CHARINDEX('@',@GMAIL))--GMAIL.COM ( When used RIGHT operand it will come right answer)
SELECT LEFT(@GMAIL,LEN(@GMAIL)-CHARINDEX('@',@GMAIL))--NETAccess ( When used LEFT operand it will come Wrong answer)
SELECT LEFT(@GMAIL,CHARINDEX('@',@GMAIL)-1) -- NETAccessIndiaLimited
SELECT SUBSTRING(@GMAIL,PATINDEX('%@%',@GMAIL)+1,20)-- GMAIL.COM
SELECT SUBSTRING(@GMAIL, CHARINDEX('@', @GMAIL) + 1, LEN(@GMAIL))-- GMAIL.COM
-------
DECLARE @Input VARCHAR(50)
SET @Input = 'Malayalam'
SELECT REPLICATE('0',12-len(@Input))
select replicate('0',3)
SELECT REVERSE(@Input)
SELECT REPLACE(@Input,'y','xx')

SELECT * FROM cnfpartymaster WHERE ISNUMERIC(partyid ) = 1 -- it will display only when table column partyid have id values

-- substirng & len ( REMOVE 1 ST Nvalues and remove last n values )

SELECT SUBSTRING('ABCdefgh',3,LEN('ABCdefgh')-4)
SELECT SUBSTRING('ABCdefgh',3,LEN('ABCdefgh')-2)
SELECT SUBSTRING('ABCdefgh',3,LEN('ABCdefgh')-1)

------Query for take data from the table---------------------------
--  run that in the Text Mode

SELECT 'SELECT ' + QUOTENAME('suji','''')+','
SELECT 'SELECT ' + 'suji'+','

------------------
-- How to SELECT Numer only using [0-9] like wise for Alphabet [a-z]
--EX. 
-- 4 starting letter is 5 for [0-9] and 1 starting letter is 1 for TOTAL

SELECT PatINdex('%[^0-9]%','TOTAL 430 CARTONS ONLY') 
SELECT PatINdex('%[0-9]%','TOTAL 430 CARTONS ONLY') 
SELECT SUBSTRING('TOTAL 430 CARTONS ONLY',PatINdex('%[0-9]%','TOTAL 430 CARTONS ONLY'),LEN('TOTAL 430 CARTONS ONLY')) 
SELECT PATINDEX('%[^0-9]%',SUBSTRING('TOTAL 430 CARTONS ONLY',PatINdex('%[0-9]%','TOTAL 430 CARTONS ONLY'),LEN('TOTAL 430 CARTONS ONLY'))) 
SELECT SUBSTRING('TOTAL 430 CARTONS ONLY',PatINdex('%[0-9]%','TOTAL 430 CARTONS ONLY'),
		PATINDEX('%[^0-9]%',SUBSTRING('TOTAL 430 CARTONS ONLY',PatINdex('%[0-9]%','TOTAL 430 CARTONS ONLY'),LEN('TOTAL 430 CARTONS ONLY')))
		)	

-- How To Check If String Contains Numeric Number (SQL Server) ----------------------------------

--In First Scenario we will query the records which contains atleast one numeric digit 
SELECT * FROM CNFCity WHERE CityName LIKE '%[0-9]%'
Or 
SELECT * FROM CNFCity WHERE PATINDEX('%[0-9]%',CityName) > 0

select PATINDEX('%[0-9]%','2aaa123sddf')

-- Second and Third Max Salary
select * from (
		select *,dense_rank() over(order by stateid desc) as maxs from CNFCity
		) bb where bb.maxs between 2 and 3

-----------------------
SELECT REPLACE(9654,'6','JH')
SELECT CONVERT(DECIMAL(2),10.89565) or SELECT cast(10.89565 as DECIMAL(2))

----STR---------------------
-- If length is not specified, it will default to 10.
-- The number of decimal places to display in the resulting string and can not exceed 16.
-- If decimal_places is not specified, it will default to 0

SELECT STR(123); --123
SELECT STR(123.5); -- 124
SELECT STR(123.5, 5); -- 124
SELECT STR(123.5, 5, 1); -- 123.5
SELECT STR(123.456, 7, 3); -- 123.456
SELECT STR(123.456, 7, 2); --  123.46
SELECT STR(123.43434343438889999, 25, 17); --      123.4343434343889100
SELECT STR(123.456, 7, 0); -- 123
SELECT STR(123.456, 7);  -- 123  (result is rounded because decimal places defaults to 0)
SELECT STR(123.456, 7, 3); -- 123.456

SELECT DATENAME(WEEKDAY,GETDATE())
SELECT CONVERT(VARCHAR(10),DATEADD(DD,-5,GETDATE()),120)

-- with out cast it will come 4 insteated of 0004
	
SELECT REPLICATE('0',5-LEN('DD')) + CAST(4 AS VARCHAR)
SELECT REPLICATE(0,5) 
SELECT REPLACE(234324,2,3)
SELECT REPLACE('welwelwel','e','NN')

-- Globle uique id(across db,server)
SELECT NEWID()

-----------------------------------
select null + 1
select null + null
SELECT COUNT(*) 
SELECT NULL +1
SELECT NULL +'1'
SELECT NULL +NULL
SELECT NULL + A

-- % Wildcard ------------
SELECT * FROM CNFCity where cityname like '%bat%'

SELECT * FROM CNFCity
WHERE cityname like '_atal_' -- exact 1 character

SELECT * FROM CNFCity
WHERE cityname like '_[aeiou]%' -- this for second lettter

SELECT * FROM CNFCity
WHERE cityname  like '[aeiou]%'

SELECT * FROM CNFCity
WHERE cityname like '_[a-d]%'  -- this for between a to d lettter

SELECT * FROM CNFCity
WHERE cityname like '_[^a-z]%' 

---Query- --------------------------------------------

DBCC FREEPROCCACHE --Clearing the plan cache

SELECT * FROM sys.dm_os_wait_stats ORDER BY wait_time_ms DESC

sp_tables '%cons%'

SP_RENAME 'HR_ProposalClientMaster.CreatedOn' , 'ApprovedOn', 'COLUMN'
alter table  HR_ProposalClientMaster add  ApprovalStatus char(1) --add new column
Alter Table dbo.Customer Alter Column LastName VARCHAR(50) Not Null
alter table  HR_ProposalClientMaster drop column  ModifiedBy,ModifiedOnc 

SELECT * FROM SYS.OBJECTS WHERE TYPE = 'u' and name like '%de%' -- tables , (P & FN & U)
SELECT * FROM SYS.tables WHERE name like '%de%' -- tables
SELECT * FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_NAME like '%de%' -- tables
SELECT * FROM INFORMATION_SCHEMA.COLUMNS   WHERE COLUMN_NAME  like '%CLIENT%' -- columns
SELECT DISTINCT o.name FROM sysobjects  o JOIN syscomments c ON o.id = c.id AND c.text like '%cursor%' -- comments 

select value from STRING_SPLIT('apple,banana,lemon,kiwi,orange,coconut,3,67',',') 
order by 1 desc (order by optional)

WAITFOR DELAY '00:00:10';

sp_who2
sp_who

dbcc inputbuffer(58)--spid)-- find out last run query statement

select * from sysprocesses
select * from sys.dm_exec_sql_text(0x03000600CE960648CC320100D5AC000001000000)

begin tran  update person.address set city = 'ji' 

kill 54 

--Get the Data File and Log file for a Database in MB
SELECT file_id, name, type_desc, physical_name, (size*8)/1024 SizeinMB, max_size
FROM sys.database_files ;

Select top (2) WITH TIES  * From dbo.Customer 
order by ID --Must be used with the ORDER BY clause , when we want to use with ties

-----------------------------

--ISNull provides output according to the data type of column used in ISNull function, 
--Instead of using Isnull use case statement to produce Unknow value for Null values.
Select *,Cast(HouseNumber AS  VARCHAR(10)) +' '+StreetName+' '+City+' '+ISNULL(State,'') 
AS FullAddress,
Case
When State is null  Then 'Unknown' ELSE State END AS StateAvailableOrNot
from dbo.CustomerAddress

--Use Coalesce function instead of using ISNULL 
Select *,Cast(HouseNumber AS  VARCHAR(10)) +' '+StreetName+' '+City+' '+ISNULL(State,'') ,

ISNULL(State,'Uknown') StateAvailableOrNot_ISNULL,
Coalesce(State,'Uknown') StateAvailableOrNot_Coalesce
from dbo.CustomerAddress

 ------

 ISNULL( ) function replaces the Null value with placed value. 
	The use of ISNULL ( ) function is   very common in different situations such as 
	changing the Null value to some value in Joins, in Select statement etc.

NULLIF ( ) function returns us Null if two arguments passed to functions are equal. 
	NULLIF( )  function works like Case statement. If both arguments are not same then 
	it will return us first argument value.

  SELECT [Id],
       [FName],
       ISNULL([LName], 'Unknown') AS LName,
       NULLIF(FName, LName)       AS ColValueNotEqual
FROM   #tmp 

-- choose ---
-- The Index starts with 1. The maximum values you can have it 254.T
Select 
SalePersonName,
SaleAmt,
DATEPART(QUARTER,SaleDate) AS Qtr#
,Choose(DATEPART(QUARTER,SaleDate),'Quarter1','Quarter2','Quarter3','Quarter4') 
AS QtrName from #Sales

Select Choose ( 1,2,'AAMIR')
--Output will be 2 

Select Choose(1,'Aamir','Shahzad')
--output will be Aamir

----LEN VS DataLen()--------------------------------------------

 LEN( ) function returns us the number of characters or length of text. 
 This function can be used in different scenarios, It is very common we want to know the 
 Max number of characters available in our one of the columns.

For that we can use
SELECT MAX(LEN(colname)) FROM dbo.TABLE

DataLength( ) function returns us the space(memory) taken by value we provide to this function in Bytes.
ex. suji as varchar
len -- 4
data lenth -- 4

if my column have NvarCHAR

len -- 4
datalen -- 8

---- NEW FEATURES STRING in 2017 ----------------

--1.STRING_AGG ( FOR comma seperator)

SELECT value FROM  STRING_SPLIT('Mark,Donald,Peter',',') --2016

CREATE TABLE #TEMP1(FirstName varchar(50), LastName varchar(50))
 
INSERT INTO #TEMP1(FirstName,LastName)
VALUES ('Mark', ' Zuckerberg'), ('Donald', 'Trump')
 
SELECT STRING_AGG(FirstName + ' ' + LastName, ',') FROM #TEMP1

----
drop table #temp
CREATE  TABLE  #temp(id int,name char(3))
 
INSERT INTO #temp VALUES (1,'CD'),(1,'AB'),(2,'LM'),(3,'BC'),(3,'GH'),(4,'KJ'),(3,'AB')
select * from #temp

SELECT id, 
	STRING_AGG (name, ',') AS data 
FROM #temp
GROUP BY id; 
 
SELECT id, 
	STRING_AGG (name, ',') WITHIN GROUP (ORDER BY name ASC) AS data 
FROM #temp
GROUP BY id; 
	
select STUFF((SELECT distinct ',' + t2.name
			from #temp t2
			FOR XML PATH(''), TYPE
			).value('.', 'NVARCHAR(MAX)') 
		,1,1,'') data

select  STUFF((SELECT distinct ',' + t2.name
from #temp t2
FOR XML PATH('')), 1,1,'') data

select distinct t1.id,
	STUFF((SELECT distinct ',' + t2.name
			from #temp t2
			where t1.id = t2.id 
			FOR XML PATH(''))--, TYPE ).value('.', 'NVARCHAR(MAX)') 
		,1,1,'') data
from #temp t1 --order by t1.id desc
 
DROP TABLE #temp

--
CREATE TABLE #TEMP(FirstName varchar(50), LastName varchar(50))
 
INSERT INTO #TEMP(FirstName,LastName)
VALUES ('Mark', ' Zuckerberg'), ('Donald', 'Trump')
 
DECLARE @str varchar(500) = ''
SELECT @str = @str + ',' + FirstName + ' ' + LastName FROM #TEMP
SELECT @str, STUFF(@str,1,1,'')
----------------

CREATE TABLE [PersonTestTable](
    [FirstName] [varchar](400) NULL,
    [LastName] [varchar](400) NULL,
    [Mail] [varchar](100) NULL,
    Country [varchar](100) NULL,
    Age [int] NULL
    
) ON [PRIMARY]
GO

INSERT INTO [dbo].[PersonTestTable]([FirstName],[LastName],[Mail],[Country],[Age]) VALUES (N'Lawrence',N'Williams',N'uhynb.ndlguey@vtq.org',N'U.S.A.',21)    
INSERT INTO [dbo].[PersonTestTable]([FirstName],[LastName],[Mail],[Country],[Age]) VALUES (N'Lawrence',N'Williams',N'uhynb.ndlguey@vtq.org',N'U.S.A.',21)
INSERT INTO [dbo].[PersonTestTable]([FirstName],[LastName],[Mail],[Country],[Age]) VALUES (N'Gilbert',N'Miller',N'loiysr.jeoni@wptho.co',N'U.S.A.',53)
INSERT INTO [dbo].[PersonTestTable]([FirstName],[LastName],[Mail],[Country],[Age]) VALUES (N'Salvador',N'Rodriguez',N'tjybsrvg.rswed@uan.org',N'Russia',46)
INSERT INTO [dbo].[PersonTestTable]([FirstName],[LastName],[Mail],[Country],[Age]) VALUES (N'Ernest',N'Jones',N'psxkrzf.jgcmc@pfdknl.org',N'U.S.A.',48)
INSERT INTO [dbo].[PersonTestTable]([FirstName],[LastName],[Mail],[Country],[Age]) VALUES (N'Jerome',N'Garcia',NULL,N'Russia',46)
INSERT INTO [dbo].[PersonTestTable]([FirstName],[LastName],[Mail],[Country],[Age]) VALUES (N'Ray',N'Wilson',NULL,N'Russia',41)
-- The order_clause parameter is an optional parameter
SELECT STRING_AGG(FirstName,'-')  WITHIN GROUP ( ORDER BY FirstName ASC)  AS Result FROM [PersonTestTable]

SELECT Country,STRING_AGG(Mail,',')  WITHIN GROUP ( ORDER BY FirstName ASC)  AS
Result FROM PersonTestTable
GROUP BY Country
ORDER BY Country asc

-- The NULL values are ignored when the STRING_AGG concatenates the expressions in the rows 
	--and it also does not add an extra separator between the expressions due to NULL values. 
SELECT Country,Mail
Result FROM [PersonTestTable]
where country='Russia' 
group by Country, Mail
    
SELECT Country,
STRING_AGG(Mail,',')  WITHIN GROUP ( ORDER BY Mail ASC)  AS
Result FROM [PersonTestTable]
where country='Russia' 
group by Country

--old
SELECT STUFF((SELECT '-' + FirstName as [text()] FROM PersonTestTable FOR XML PATH('')),1,1,'') AS Result

--dulicate remove
SELECT STRING_AGG(Cnty, '-')  FROM
(
 (SELECT DISTINCT Country AS [Cnty] FROM PersonTestTable)
) AS TMP_TBL

--STRING_AGG function
--There is no doubt that the nvarchar and varchar types concatenated results will be in the same type.
However, if we concatenate other datatypes which can be converted into string datatypes (int, float, datetime and etc.) 
The result data types will be NVARCHAR(4000) for non-string data types
	
	CREATE TABLE TempTableForFunction(SampleVal Float)
    
INSERT INTO TempTableForFunction VALUES (12.67) , (98.09),(65.42),(56.72),(129.12)
    
SELECT STRING_AGG(SampleVal,'-') WITHIN GROUP ( ORDER BY SampleVal ASC) AS Result 
INTO  TempTableForFunctionResult  
FROM TempTableForFunction  -- in TempTableForFunctionResult table , result column value data type as nvarchar instead of float

--2.Trim
DECLARE @Str NVARCHAR(MAX)
SET @Str = '           SQLShack           '
SELECT @Str OriginalString, RTRIM(LTRIM(@Str)) TrimmedString  -- better than ltrim,rtrim
SELECT @Str OriginalString, TRIM(@Str) TrimmedString

--3.TRANSLATE
DECLARE @Str NVARCHAR(MAX)
SET @Str = '{~~[##SQLShack##]~~}'
SELECT TRANSLATE(@Str, '#[]{}~~', '1111111');  -- allows us to perform a one-to-one, single-character substitution

SELECT @Str InputString, 
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(@Str,'#','1'),
										'[','1'
									),
								']','1'
							),
							'~','1'
						), 
					'{','1'
				),
			'}','1'		) OutPutString  -- to replace each character 

--Note: 
The second and third arguments of the built-in SQL string function, 
	TRANSLATE, must contain an equal number of characters.

--4.CONCAT_WS
--One primary difference is that concat_ws() skips NULL arguments, but + does not.
--CONCAT_WS() is very similar to CONCAT() function, 
	--but it allows the user to specify a separator between the concatenated input strings. 

select top 10 stuff(
			(coalesce (' - ' + FirstName, '') + coalesce(' - ' + MiddleName, '') + coalesce(' - ' + LastName, '') 
				), 2, 1, ' ')
		, FirstName, MiddleName, LastName
FROM [Person].[Person] WHERE MIDDLENAME IS NULL
 
SELECT 
	CONCAT_WS ( ' - ' , FirstName , MiddleName , LastName  ) as FullName, 
	FirstName, MiddleName,LastName
FROM [Person].[Person] 
where BusinessEntityID between 1 and 6
--WHERE MIDDLENAME IS NULL

SELECT CONCAT(FIRSTNAME,+ ' - ' + MIDDLENAME, + ' - ' + LASTNAME),* 
FROM [Person].[Person] --WHERE MIDDLENAME IS NULL
	where BusinessEntityID between 1 and 6

-------IN & Exists-------------------------------------------------------
 
drop table employee_tbl,
truncate table company_tbl

create table employee_tbl( empid int, fullname varchar(20))
insert into employee_tbl
select 1	,'Ankit Sarkar'
union all
select 2	,'Mohit Jain'
union all
select 3	,'Naina Pathak'
union all
select 4	,'Anshul Jain'
union all
select 5	,'Vinay Tripathi'

create table company_tbl(id int, company varchar(20), contact_id int)
insert into company_tbl
select 1	,'Apple',	2
union all
select 2	,'Mango',	3
union all
select 4	,'Blackberry',	2

SELECT * FROM Employee_tbl WHERE EmpId IN (SELECT Contact_Id FROM Company_tbl ) --2,3
SELECT * FROM Employee_tbl WHERE exists (SELECT Contact_Id FROM Company_tbl )--all data table1

SELECT * FROM Employee_tbl WHERE EmpId NOT IN (SELECT Contact_Id FROM Company_tbl )-- 1,4,5
SELECT * FROM Employee_tbl WHERE not exists (SELECT Contact_Id FROM Company_tbl ) -- no data

truncate table company_tbl
SELECT * FROM Employee_tbl WHERE not exists (SELECT Contact_Id FROM Company_tbl )--rtn all row frm table1

SELECT * FROM Employee_tbl e 
	WHERE e.EmpId IN (SELECT Contact_Id FROM Company_tbl c where c.contact_id = e.empid)--2,3
SELECT * FROM Employee_tbl e 
	WHERE exists (SELECT Contact_Id FROM Company_tbl c where c.contact_id = e.empid) --2,3

SELECT * FROM Employee_tbl e
	WHERE EmpId NOT IN (SELECT Contact_Id FROM Company_tbl where contact_id  = e.empid) -- 1,4,5
SELECT * FROM Employee_tbl e 
	WHERE not exists (SELECT Contact_Id FROM Company_tbl c where c.contact_id = e.empid) -- 1,4,5

insert into company_tbl
select 3	,'Orange',	NULL

SELECT * FROM Employee_tbl WHERE EmpId NOT IN (SELECT Contact_Id FROM Company_tbl ) -- no data

--EXISTS will return TRUE if subquery contains any rows.
--That is right, if our subquery will return any rows and we have used EXISTS, 
--the outer query is going to return all rows.

Select * from dbo.Customer
WHERE Exists ( Select 1)

select * into tests from Customer where 1 = 2

Select * from dbo.Customer
WHERE Exists ( Select ID from tests)-- TEST TABLE HAVING NO DATA  , so data will not return from customer

-- NOT IN ( When with out joing two tables this sinario comes)
-- if Table1 is NULL in joining column then based NOT IN data will come
-- if Table2 is NULL in joining column then based NOT IN data will not come

CREATE TABLE #TEMP1(ID INT,BranchId INT)
INSERT INTO #TEMP1
SELECT 1,55
UNION ALL
SELECT 3,55

CREATE TABLE #TEMP2(ID INT,BranchId INT)
INSERT INTO #TEMP2
SELECT 7,null
union all
SELECT 1,55
UNION ALL
SELECT 5,55
	
SELECT * FROM #TEMP1
SELECT * FROM #TEMP2

drop table #TEMP1
drop table #TEMP2

--ex1.
SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID)   -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID)  -- 1

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID) -- 3
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID) -- 3

SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b ) -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B ) -- 1,3 

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b ) -- 3
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B)  -- no data will come

--ex2.(NULL IN 1st table)
	if we insert like this
	INSERT INTO #TEMP1
	SELECT null,null
SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID)   -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID)  -- 1

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID) -- 3,NULL
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID) -- 3,NULL

SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b ) -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B ) -- 1,3,NULL

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b ) -- 3
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B)  -- no data will come

--if we insert like this
INSERT INTO #TEMP1
SELECT null,22

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID) -- 3,NULL,null
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID) -- 3,NULL,null

SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b ) -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B ) -- 1,3,NULL,null 

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b ) -- 3
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B)  -- no data will come

--ex3.(NULL IN 2nd table)
--if we insert like this
INSERT INTO #TEMP2
SELECT NULL,null

SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID)   -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID)  -- 1

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID) -- 3,NULL,NULL
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID) --3,NULL,NULL

SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b ) -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B ) -- 1,3,NULL,NULL

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b ) -- 
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B)  -- no data will come
		
--if we insert like this
INSERT INTO #TEMP2
SELECT null,NULL

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID) -- 3,NULL,NULL
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID) -- 3,NULL,NULL

SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b ) -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B ) -- 1,3,NULL,NULL

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b ) -- no data will come
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B)  -- no data will come

--ex4.(NULL IN 1st,2nd table)
SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID)   -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID)  -- 1

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b WHERE A.ID = B.ID) -- 3,NULL,NULL
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B WHERE A.ID = B.ID) -- 3,NULL,NULL

SELECT * FROM #TEMP1 A WHERE ID IN (SELECT ID FROM #TEMP2 b ) -- 1
SELECT * FROM #TEMP1 A WHERE  EXISTS (SELECT ID FROM #TEMP2 B ) -- 1,3,NULL,NULL

SELECT * FROM #TEMP1 A WHERE ID NOT IN (SELECT ID FROM #TEMP2 b ) -- no data will come
SELECT * FROM #TEMP1 A WHERE NOT EXISTS (SELECT ID FROM #TEMP2 B)  -- no data will come

---- UNION ALL -------------------------------------------------------
---no need to give header name for all select st 	
-- only first select st header name will be displayed
SELECT 'VendorID' AS ColumnHeader,'0'  AS ColumnWidth,'VendorID' AS DataField 
UNION ALL SELECT 'VendorName','20', 'VendorName' 
UNION ALL SELECT 'AssetCatgID','0', 'AssetCatgID'
	
-- cortesion values will come ---------------------------

CREATE TABLE TABLE_SUJITH4( ID INT)
INSERT INTO TABLE_SUJITH4 
SELECT 1
UNION ALL
SELECT 1
UNION ALL
SELECT 1
UNION ALL
SELECT 1
	
CREATE TABLE TABLE_SUJITH5( ID INT)
INSERT INTO TABLE_SUJITH5
SELECT 1
UNION ALL
SELECT 1
UNION ALL
SELECT 1

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
LEFT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
RIGHT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
FULL JOIN TABLE_SUJITH5 B ON A.ID = B.ID

INSERT INTO TABLE_SUJITH5
SELECT NULL

SELECT * FROM TABLE_SUJITH4
UNION 
SELECT * FROM TABLE_SUJITH5

SELECT * FROM TABLE_SUJITH4
UNION ALL
SELECT * FROM TABLE_SUJITH5

SELECT COUNT(*) FROM TABLE_SUJITH5
SELECT SUM(1) FROM TABLE_SUJITH5

TRUNCATE TABLE TABLE_SUJITH4
TRUNCATE TABLE TABLE_SUJITH5

SELECT COUNT(*) FROM TABLE_SUJITH5
SELECT SUM(1) FROM TABLE_SUJITH5

----
INSERT INTO TABLE_SUJITH4 
SELECT 1

INSERT INTO TABLE_SUJITH5
SELECT NULL

SELECT COUNT(*) FROM TABLE_SUJITH5
SELECT SUM(1) FROM TABLE_SUJITH5

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
LEFT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
RIGHT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
FULL JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT * FROM TABLE_SUJITH4
UNION 
SELECT * FROM TABLE_SUJITH5

SELECT * FROM TABLE_SUJITH4
UNION ALL
SELECT * FROM TABLE_SUJITH5

--null in both table

TRUNCATE TABLE TABLE_SUJITH4
TRUNCATE TABLE TABLE_SUJITH5

INSERT INTO TABLE_SUJITH4 
SELECT null

INSERT INTO TABLE_SUJITH5
SELECT NULL

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
LEFT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
RIGHT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
FULL JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT * FROM TABLE_SUJITH4
UNION 
SELECT * FROM TABLE_SUJITH5

SELECT * FROM TABLE_SUJITH4
UNION ALL
SELECT * FROM TABLE_SUJITH5

------------------------

TRUNCATE TABLE TABLE_SUJITH4
TRUNCATE TABLE TABLE_SUJITH5

INSERT INTO TABLE_SUJITH4 
SELECT null
union all
select null

INSERT INTO TABLE_SUJITH5
SELECT NULL

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
LEFT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
RIGHT JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT A.ID,B.ID
FROM TABLE_SUJITH4 A 
FULL JOIN TABLE_SUJITH5 B ON A.ID = B.ID

SELECT * FROM TABLE_SUJITH4
UNION 
SELECT * FROM TABLE_SUJITH5

SELECT * FROM TABLE_SUJITH4
UNION ALL
SELECT * FROM TABLE_SUJITH5

drop TABLE TABLE_SUJITH4
drop TABLE TABLE_SUJITH5

-- EXCEPT vs NOT IN ----------------

--EXCEPT is similar as NOT IN with DISTINCT queries.
--NOT IN will return all rows from left hand side table which are not present in right hand side table but it will not remove duplicate rows from the result.
-- All queries combined using a UNION, INTERSECT or EXCEPT operator must have an equal number of expressions in their target lists

CREATE TABLE# NewData(ID INT, Name[nvarchar](30));  
CREATE TABLE# ExistingData(ID INT, Name[nvarchar](30));  
  
INSERT INTO #NewData (ID, Name)  
VALUES  (8, 'Pankaj'), (9, 'Rahul'), (10, 'Sanjeev'), (1, 'Sandeep'), (3, 'Priya'), (8, 'Deepak');  
  
INSERT INTO #ExistingData (ID, Name)  
VALUES (1, 'Sandeep'), (2, 'Neeraj'), (3, 'Priya'), (4, 'Omi'), (5, 'Divyanshu');  

--EXCEPT filters  
for DISTINCT values  
SELECT nc.ID FROM# NewData AS nc  
EXCEPT  
SELECT ec.ID FROM# ExistingData AS ec   -- O/P 8,9,10 

--NOT IN returns all values without filtering  
SELECT nc.ID FROM# NewData AS nc 
WHERE ID NOT IN(SELECT ec.ID FROM# ExistingData AS ec)   -- 8,9,10,8

-- USING Distinct in not in to get same result as except
--EXCEPT filters  
SELECT nc.ID FROM# NewData AS nc  
EXCEPT  
SELECT ec.ID FROM# ExistingData AS ec   -- O/P 8,9,10 
  
--NOT IN returns all values without filtering  
SELECT DISTINCT nc.ID FROM# NewData AS nc  
WHERE ID NOT IN(SELECT ec.ID FROM# ExistingData AS ec) -- 8,9,10

-- ** insert some NULL values for both columns in “#ExistingData” table  --

--We know that NOT IN command just  work like an “AND” operator. It means,
WHERE ID NOT IN (SELECT ec.ID FROM #ExistingData AS ec) -- no data

--Above condition is similar as below condition.( ID !=NULL ) this condition alway returns false so Not in data val will not come
WHERE ID !=1 AND ID !=2 AND ID !=3 AND ID !=NULL AND ID !=4 AND ID !=5

-- INTERSECT between two tables.
-- When INNER JOIN is used it gives us duplicate records, but that is not in the case of INTERSECT operator.

SELECT VendorID,ModifiedDate
FROM Purchasing.VendorContact
INTERSECT
SELECT VendorID,ModifiedDate
FROM Purchasing.VendorAddres

-- Using INNER JOIN with Distinct.

SELECT DISTINCT va.VendorID,va.ModifiedDate
FROM Purchasing.VendorContact vc
INNER JOIN Purchasing.VendorAddress va ON vc.VendorID = va.VendorID
AND vc.ModifiedDate = va.ModifiedDate

-- Not work properly in #temp foreign key table 

CREATE TABLE #TEMP1(ID INT ,NAME VARCHAR(10)) 
ALTER TABLE #TEMP1 ADD PRIMARY KEY(ID) --Cannot define PRIMARY KEY constraint on nullable column(ID) in table '#TEMP1'

CREATE TABLE #TEMP1(ID INT NOT NULL,NAME VARCHAR(10))
INSERT INTO #TEMP1
SELECT 2,'BB'

ALTER TABLE #TEMP1 ADD PRIMARY KEY(ID) -- Now PRIMARY KEY will Create bcz we defined column as (ID INT NOT NULL)

SELECT * FROM #TEMP1
DROP TABLE #TEMP1

CREATE TABLE #TEMP2(ID INT NOT NULL,NAME VARCHAR(10) DEFAULT 'AA')
INSERT INTO #TEMP2(ID)
SELECT 2 

ALTER TABLE #TEMP2 ADD FOREIGN KEY(ID) REFERENCES #TEMP1(ID)
--Skipping FOREIGN KEY constraint '#TEMP2' definition for temporary table. FOREIGN KEY constraints are not enforced on local or global temporary tables.

INSERT INTO #TEMP2
SELECT 3,'BB'
SELECT * FROM #TEMP2  -- we can create FOREIGN KEY, but values are not insert correction (ex. #table1 having 2 values ,if we insert  #table2 as value 3 it will insert)
DROP TABLE #TEMP2

---Types of Window functions -----------------------------------

CREATE TABLE [dbo].[Orders]
(
	order_id INT,
	order_date DATE,
	customer_name VARCHAR(250),
	city VARCHAR(100),	
	order_amount MONEY
)
 
INSERT INTO [dbo].[Orders]
SELECT '1001','04/01/2017','David Smith','GuildFord',10000
UNION ALL	  
SELECT '1002','04/02/2017','David Jones','Arlington',20000
UNION ALL	  
SELECT '1003','04/03/2017','John Smith','Shalford',5000
UNION ALL	  
SELECT '1004','04/04/2017','Michael Smith','GuildFord',15000
UNION ALL	  
SELECT '1005','04/05/2017','David Williams','Shalford',7000
UNION ALL	  
SELECT '1006','04/06/2017','Paum Smith','GuildFord',25000
UNION ALL	 
SELECT '1007','04/10/2017','Andrew Smith','Arlington',15000
UNION ALL	  
SELECT '1008','04/11/2017','David Brown','Arlington',2000
UNION ALL	  
SELECT '1009','04/20/2017','Robert Smith','Shalford',1000
UNION ALL	  
SELECT '1010','04/25/2017','Peter Smith','GuildFord',500
 
--Aggregate Window Functions
SUM(), MAX(), MIN(), AVG(). COUNT() --	show an aggregated value for each row. 
/*
Note:
that DISTINCT is not supported with window COUNT() function whereas it is supported for the 
regular COUNT() function. DISTINCT helps you to find the distinct values of a specified field. */

SELECT order_id, order_date, customer_name, city, order_amount
	,SUM(order_amount) OVER(PARTITION BY city) as grand_total 
FROM [dbo].[Orders]

SELECT order_id, order_date, customer_name, city, order_amount
	,AVG(order_amount) OVER(PARTITION BY city, MONTH(order_date)) as   average_order_amount 
FROM [dbo].[Orders]

--eg.( Wrong query)
SELECT order_id, order_date, customer_name, city, order_amount
,COUNT(DISTINCT customer_name) OVER(PARTITION BY city) as number_of_customers
FROM [dbo].[Orders] 
	 
-- correct query
SELECT order_id, order_date, customer_name, city, order_amount
,COUNT(order_id) OVER(PARTITION BY city) as total_orders
FROM [dbo].[Orders]

--Ranking Window Functions
RANK(), DENSE_RANK(), ROW_NUMBER(), NTILE()

--Value Window Functions
LAG(), LEAD(), FIRST_VALUE(), LAST_VALUE()

/*
LAG -- function allows to access data from the previous row in the same result set 
LEAD -- function allows to access data from the next row in the same result set

--FIRST_VALUE() and LAST_VALUE()
These functions help you to identify first and last record within a partition or entire table if PARTITION BY is not specified.
Note ORDER BY clause is mandatory for FIRST_VALUE() and LAST_VALUE() functions

*/
SELECT order_id,customer_name,city, order_amount,order_date,
--in below line, 1 indicates check for previous row of the current row
LAG(order_date,1) OVER(ORDER BY order_date) prev_order_date
FROM [dbo].[Orders]

SELECT order_id,customer_name,city, order_amount,order_date,
--in below line, 1 indicates check for next row of the current row
LEAD(order_date,1) OVER(ORDER BY order_date) next_order_date
FROM [dbo].[Orders]

SELECT order_id,order_date,customer_name,city, order_amount,
FIRST_VALUE(order_date) OVER(PARTITION BY city ORDER BY city) first_order_date,
LAST_VALUE(order_date) OVER(PARTITION BY city ORDER BY city) last_order_date
FROM [dbo].[Orders]

----duplicate data

DELETE FROM [SampleDB].[dbo].[Employee]
WHERE ID NOT IN
(
    SELECT MAX(ID) AS MaxRecordID
    FROM [SampleDB].[dbo].[Employee]
    GROUP BY [FirstName], 
                [LastName], 
                [Country]
);

WITH CTE([FirstName], 
[LastName], 
[Country], 
DuplicateCount)
AS (SELECT [FirstName], 
			[LastName], 
			[Country], 
			ROW_NUMBER() OVER(PARTITION BY [FirstName], 
											[LastName], 
											[Country]
			ORDER BY ID) AS DuplicateCount
	FROM [SampleDB].[dbo].[Employee])
DELETE FROM CTE
WHERE DuplicateCount > 1;

----
SELECT * 
FROM 
	(SELECT *,ROW_NUMBER() OVER(ORDER BY PARTYID) ROWSS FROM CNFPartyMaster) AA
WHERE AA.ROWSS BETWEEN 2 AND 10

---- Delete duplicate with CTE & Rank function -------------------------------------

create table empdetails(empid int, fullname varchar(20), managerid int, dateofjoining date)
truncate table empdetails
insert into empdetails
select 20101	,'Ankit Sarkar',	201101	,'2001-02-15'
union all
select 20102,	'Akhil Rawat',	201101,	'2010-04-14'
union all
select 20103,	'Naina Pathak',	201101,	'2010-04-14'
union all
select 20104,	'Akhil Rawat',	201101,	'2010-04-14'
union all
select 20105,	'Ankit Sarkar',	201101,	'2001-02-15'

select * from empdetails

with cte as 
(
select *,
row_number() over (partition by fullname,managerid,dateofjoining order by empid desc) as dd 
from empdetails
)
select * from cte where dd > 1

---Generating Custome and system error Message ------------------------------ 
 
 --Custom error

BEGIN CATCH

	DECLARE @Message nvarchar(MAX) ;
	set @Message= N'error happened in sp';
   
	RAISEERROR (@Message, 11,1)

END CATCH
 
 --System error

BEGIN CATCH
INSERT INTO dbo.DB_Errors
VALUES
(SUSER_SNAME(),
ERROR_NUMBER(),
ERROR_STATE(),
ERROR_SEVERITY(),
ERROR_LINE(),
ERROR_PROCEDURE(),
ERROR_MESSAGE(),
GETDATE());
 
DECLARE @Message varchar(MAX) = ERROR_MESSAGE(),
    @Severity int = ERROR_SEVERITY(),
    @State smallint = ERROR_STATE()

----------------------------
DECLARE @a INT= 1000;
PRINT CONCAT('Your queue no is : ',@a)

DECLARE @a INT= 1000;
PRINT 'Your queue no is ' + CAST(@a AS VARCHAR(10));

Print NULL -- it will not return any message

DECLARE @a NVarChar(100)= NULL
PRINT 'Hello' + @a  -- it will not return any message

WHILE(@a < 10)
    BEGIN
        PRINT CONCAT('This is Iteration no:' , @a)
        SET @a  = @a + 1;
    END;


   RAISEERROR (@Message, @Severity, @State)
  END CATCH

 ---XACT_STATE --------------------------------

 analyzing the XACT_STATE function that reports transaction state.
 
BEGIN CATCH

    IF (XACT_STATE()) = -1 -- Transaction uncommittable
      ROLLBACK TRANSACTION
 

    IF (XACT_STATE()) = 1 -- Transaction committable
      COMMIT TRANSACTION
END CATCH

---XACT_ABORT?

When the XACT_ABORT is enabled, if any SQL statement has an error on the transaction, 
the whole transaction is terminated and rolled back. If we disable the XACT_ABORT, 
when a statement returns an error, only the errored query is rolled back and other queries complete the operations.

--SET XACT_ABORT ON
 
IF OBJECT_ID(N'tempdb..#Test') IS NOT NULL
BEGIN
DROP TABLE #Test
END
    
CREATE TABLE #Test 
(Id INT PRIMARY KEY, Col1 VARCHAR(20))
    
BEGIN TRAN
INSERT INTO #Test VALUES(1,'Value1')
INSERT INTO #Test VALUES(2,'Value1')
INSERT INTO #Test VALUES(3,'Value1')
INSERT INTO #Test VALUES(4,'Value1')
INSERT INTO #Test VALUES(4,'Value1') -- duplicate (it will not insert) but successfully insert all remaining data
COMMIT TRAN
GO
SELECT * FROM #Test

----------------------------

EXEC SP_SUJITHTEST 
@ROLLNO = 'AB/VS/0023/20-21',
@ROLLID = '23ABCDEFGH/4/4',
@ITEMSDESC = 'CHENNAI,BANGALORE,MYSORE',
@ITEMID = '3,4,6',
@ITEMQTY = '23,46,56',
@USERS = 'USER',
--@CURRENTDATE = NU,
@ENTRYDATE = '2021-01-12'

ALTER PROCEDURE SP_SUJITHTEST
@ROLLNO VARCHAR(30) = NULL,
@ROLLID VARCHAR(30) = NULL,
@ITEMSDESC VARCHAR(40) = NULL,
@ITEMID VARCHAR(30),
@ITEMQTY VARCHAR(30) = NULL,
@USERS VARCHAR(20) = NULL,
@CURRENTDATE DATETIME = NULL,
@ENTRYDATE DATE
AS
BEGIN
	CREATE TABLE #TEMPITEM(ID INT IDENTITY(1,1),ITEMID INT)
	INSERT INTO #TEMPITEM
	SELECT value FROM  STRING_SPLIT(@ITEMID,',') --2016

	CREATE TABLE #TEMPITEMDESC(ID INT IDENTITY(1,1),ITEMDESC VARCHAR(40))
	INSERT INTO #TEMPITEMDESC
	SELECT value FROM  STRING_SPLIT(@ITEMSDESC,',') --2016
	
	CREATE TABLE #TEMPITEMQTY(ID INT IDENTITY(1,1),ITEMQTY INT)
	INSERT INTO #TEMPITEMQTY
	SELECT value FROM  STRING_SPLIT(@ITEMQTY,',') --2016

	DECLARE @MAXID VARCHAR(30)
	DECLARE @MAX VARCHAR(30)
	SELECT @MAXID = ID FROM SUJITHTEST

	SELECT @MAX = REPLICATE('0',4-LEN(@MAXID)) + @MAXID
	--SELECT @MAX

	/*
	DROP TABLE SUJITHTEST
	CREATE TABLE SUJITHTEST
		(ID INT IDENTITY(1,1), ROLLNO VARCHAR(30), ROLLID VARCHAR(30),
		ITEMDESC VARCHAR(50), ITEMID INT, ITEMQTY NUMERIC, 
		USERS VARCHAR(30), CURRENTDATE DATETIME, ENTRYDATE DATE)*/
	
	INSERT INTO SUJITHTEST
	SELECT 'AB/VS/'+ @MAX + '/20-21', @ROLLID,
		D.ITEMDESC, I.ITEMID, Q.ITEMQTY, 
		@USERS , GETDATE(), @ENTRYDATE
	FROM #TEMPITEM I
	JOIN #TEMPITEMDESC D ON I.ID = D.ID
	JOIN #TEMPITEMQTY Q ON D.ID = Q.ID

	SELECT * FROM SUJITHTEST
END

-- MERGE ----------------------------------
--Delete the records whose marks are more than 250.
--Update marks and add 25 to each as internals if records exist.
--Insert the records if record does not exists.

CREATE TABLE StudentDetails_sujith
(
StudentID INTEGER PRIMARY KEY,
StudentName VARCHAR(15)
)
INSERT INTO StudentDetails_sujith VALUES(1,'SMITH')
INSERT INTO StudentDetails_sujith VALUES(2,'ALLEN')
INSERT INTO StudentDetails_sujith VALUES(3,'JONES')
INSERT INTO StudentDetails_sujith VALUES(4,'MARTIN')
INSERT INTO StudentDetails_sujith VALUES(5,'JAMES')

CREATE TABLE StudentTotalMarks_sujith
(
FOREIGN KEY (StudentID) REFERENCES StudentDetails_sujith(StudentID),
StudentID INTEGER,
StudentMarks INTEGER,
)
INSERT INTO StudentTotalMarks_sujith VALUES(1,230)
INSERT INTO StudentTotalMarks_sujith VALUES(2,255)
INSERT INTO StudentTotalMarks_sujith VALUES(3,200)

MERGE StudentTotalMarks_sujith T 
USING StudentDetails_sujith S ON T.StudentID = S.StudentID
WHEN MATCHED AND T.StudentMarks > 250 THEN DELETE
WHEN MATCHED THEN UPDATE SET T.StudentMarks = T.StudentMarks + 25
WHEN NOT MATCHED THEN INSERT (StudentID, StudentMarks) VALUES(S.StudentID,25);
-- OR
MERGE GMSMatReturnsMaterialsRegister Trg 
USING #InPutBuffer Src ON Src.Id=Trg.MatReturnsMatsRegID AND MatReturnRegID=@MatRegId
WHEN NOT MATCHED BY TARGET AND Src.Id=0 THEN INSERT (MatReturnRegID,MatRetMatsRegID,MatName,DepartmentID,MatRefNo,UOMID,RetQty,CreatedBy,CreatedOn,ModifiedBy,ModifiedOn,Enabled)
	VALUES (@MatRegId,Src.MatRetMatsRegID,Src.Name,Src.DepartmentID,Src.RefNo,Src.UomId,Src.Qty,@UserId,GETDATE(),NULL,NULL,1)
WHEN NOT MATCHED BY SOURCE AND MatReturnRegID=@MatRegId THEN UPDATE SET ENABLED=0, ModifiedBy=@UserId, ModifiedOn=GETDATE()
WHEN MATCHED THEN UPDATE 
	SET MatName=Src.Name, DepartmentID=Src.DepartmentID, MatRefNo=Src.RefNo, UOMID=Src.UomId, RetQty=Src.Qty, ModifiedBy=@UserId, ModifiedOn=GETDATE(), Enabled=1;

-- Checking the actions by MERGE statement
OUTPUT $action, 
DELETED.ProductID AS TargetProductID,
INSERTED.ProductID AS SourceProductID;

SELECT * FROM StudentTotalMarks_sujith
SELECT * FROM StudentDetails_sujith

drop table StudentDetails_sujith
drop table StudentTotalMarks_sujith

--- FUNCTION ---------------------------------------------------
/* 
Function types
1.Scalar Functions (Returns A Single Value)
2.Inline Table Valued Functions (Contains a single TSQL statement and returns a Table Set)
3.Multi-Statement Table Valued Functions (Contains multiple TSQL statements and returns Table Set)

1.non-deterministic functions like GETDATE() cannot be directly used inside a deterministic function, 
	but you can pass them as parameters to the function.
2.the schema name is mandatory to invoke a function:
3.Cannot call a function from a stored procedure. 
4.inline function must retrun select statement 
5.Cannot perform alter FOR multiple STATEMENT TABLE VALUE FUNION on 'DBO.TESTSUJITH1' (SCALR FUNTION) because it is an incompatible object type.
6.we can't insert values in permanent table in function 
*/

--- Scalar Functions

-- select dbo.TESTSUJITH1(2,4)
CREATE FUNCTION DBO.TESTSUJITH1
(
	@A INT,
	@B INT
)
RETURNS INT
AS
BEGIN 
	DECLARE @C INT
	SET @C = @A + @B
	RETURN @C -- Scalar fucntion to return single value 
END

-- SELECT DBO.TESTSUJITH3(2,1)
alter FUNCTION DBO.TESTSUJITH3
(
	@A INT,
	@B INT
)
RETURNS INT
AS
BEGIN 
	DECLARE @C INT
	SET @C = (SELECT (A + B) FROM TMPSUJITH where a= 3)
	RETURN @C
END

-- SELECT DBO.TESTSUJITH3(2,1)
create FUNCTION DBO.TESTSUJITH3
(
	@A INT,
	@B INT
)
RETURNS INT
AS
BEGIN 
	DECLARE @C INT
	RETURN (SELECT (A + B) FROM TMPSUJITH where a= 13)
END

-------
CREATE FUNCTION  priceinpesos(@dollar real)
RETURNS real
AS 
BEGIN
	RETURN  @dollar*20.33
END

SELECT CONCAT(dbo.helloworldfunction(),', welcome to sqlshack') Regards

------
CREATE FUNCTION dbo.helloworldfunction()
RETURNS varchar(20)
AS 
BEGIN
	 RETURN 'Hello world'
END

CREATE FUNCTION dbo.functioninsidefunction()
RETURNS varchar(50)
AS 
BEGIN
	RETURN  dbo.helloworldfunction()
END
-----

CREATE FUNCTION getFormattedDate
(
 @DateValue AS DATETIME
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	RETURN
	  DATENAME(DW, @DateValue)+ ', '+
	  DATENAME(DAY, @DateValue)+ ' '+
	  DATENAME(MONTH, @DateValue) +', '+
	  DATENAME(YEAR, @DateValue)
 
END

SELECT	name, [dbo].[getFormattedDate](DOB) FROM student
SELECT [dbo].[getFormattedDate](getdate())

-- Inline Table Valued

CREATE FUNCTION dbo.testsujith()
RETURNS TABLE
AS
RETURN  ( SELECT 2 + 4  as aa,3 as bb )  -- COLUMN Alasis must specify EX. AA

CREATE FUNCTION dbo.functiontable( )   
RETURNS TABLE    
AS   
RETURN 
(
	select [AddressID],[AddressLine1],[AddressLine2],City from [Person].[Address] 
)

SELECT * from dbo.functiontable()
DROP FUNCTION dbo.functiontable -- When we drop function,we must not use () ,when use function name with () it shows error   
SELECT AddressID from dbo.functiontable() 
SELECT AddressID from dbo.functiontable() WHERE AddressID=502
SELECT * INTO mytable FROM dbo.functiontable()
 
--- Multi-Statement Table Valued Functions

ALTER function dbo.fun_test
(
	@i as int, 
	@J as varchar(100)
)
REturns @tmp table 
( 
	id  int,  --- No @ here 
	jj  varchar(100)
)
AS 
BEGIN 
	insert into @tmp values( @i, @j)  -- DML in Function using Table Variable
	update @tmp set jj='suijth'
	REturn
END 

Select * from dbo.fun_test (1,'sankar')
drop function dbo.fun_test

----- Stored Procedure -----------------------------------------------------

CREATE PROCEDURE outputparam
@paramout varchar(20) out
as
select @paramout='Hello world'

declare @message varchar(20)
EXEC outputparam @paramout=@message out
select @message as regards
select CONCAT(@message,', welcome to sqlshack')

--it will work
insert into Person.Address2
exec tablexample  -- addrss1 select statment
-- it will not work
exec tablexample into
Person.Address3

-- Stored Procedure can retrun only INt

create PROCEDURE testsujith
AS
BEGIN 
	RETURN 0
END 

DECLARE @b bit
EXEC @b = testsujith 
SELECT @b  

ALTER PROCEDURE testsujith
AS
BEGIN 
	RETURN 9
END 

DECLARE @b bit
EXEC @b = testsujith 
SELECT @b 

create PROCEDURE testsujith
AS
BEGIN 
	RETURN 
END 

DECLARE @b VARCHAR(10)
EXEC @b = testsujith 
SELECT @b 

DECLARE @b int
EXEC @b = testsujith 
SELECT @b 

ALTER PROCEDURE testsujith
AS
BEGIN 
	RETURN 9.56
END 

DECLARE @b decimal(18,2) -- decimal not work it will return 9.00 insted of 9.56
EXEC @b = testsujith 
SELECT @b 

ALTER PROCEDURE testsujith
AS
BEGIN 
	RETURN 'hi'
END 

DECLARE @b VARCHAR(10)
EXEC @b = testsujith 
SELECT @b  -- Conversion failed when converting the varchar value 'hi' to data type int.

drop procedure testsujith

--Using Return keyword in Stored Procedure
/*
It checks whether an Employee with the supplied EmployeeId exists in the Employees table of the Northwind database.
Note: A Stored Procedure can return only INTEGER values. You cannot use it for returning values of any other data types.
If the Employee exists it returns value 1 and if the EmployeeId is not valid then it returns 0. */

CREATE PROCEDURE CheckEmployeeId
	@EmployeeId INT
AS
BEGIN
		SET NOCOUNT ON;
		DECLARE @Exists INT
		IF EXISTS(SELECT EmployeeId
						FROM Employees
						WHERE EmployeeId = @EmployeeId)
		BEGIN
			SET @Exists = 1
		END
		ELSE
		BEGIN
			SET @Exists = 0
		END
		RETURN @Exists
END

DECLARE @ReturnValue INT
EXEC @ReturnValue = CheckEmployeeId 1
SELECT @ReturnValue

---- Cursor ----------------------------

select * from msdb..sysmail_profile

CREATE TABLE dbo.EmailNotification
  (
     EmailID        INT IDENTITY(1, 1),
     EmailAddress   VARCHAR(100),
     EmailSubject   VARCHAR(200),
     Body           NVARCHAR(MAX),
     EmailStatusFlg BIT
  )
GO
INSERT INTO dbo.EmailNotification
VALUES     ( 'ssujith22@gmail.com',
             'TestEmail Subject',
             ' This is test email to users',
             0)

DECLARE @Mail_Profile_Name VARCHAR(100)
SET @Mail_Profile_Name='MailProfileName'

DECLARE @MessageBody NVARCHAR(1000)
DECLARE @RecipientsList NVARCHAR(500)
DECLARE @MailSubject NVARCHAR(500)
DECLARE @EmailID INT
    
DECLARE Email_cursor CURSOR FOR
SELECT Emailid,EmailAddress,EmailSubject,Body 
FROM dbo.EmailNotification WHERE EmailStatusFlg=0
OPEN Email_cursor 
FETCH NEXT FROM Email_cursor  INTO @EmailID,@RecipientsList,@MailSubject,@MessageBody
WHILE @@FETCH_STATUS = 0
  BEGIN
 
  EXEC msdb.dbo.sp_send_dbmail
    @profile_name = @Mail_Profile_Name,
    @recipients = @RecipientsList,
    @body = @MessageBody,
    @subject = @MailSubject;
    
    UPDATE dbo.EmailNotification
    SET EmailStatusFlg=1
    WHERE EmailID=@EmailID
 FETCH NEXT FROM Email_cursor  INTO @EmailID,@RecipientsList,@MailSubject,@MessageBody
  END
CLOSE Email_cursor
DEALLOCATE Email_cursor

-- Linked Server ---------------------------------------------------------------------------------
-- using Microsoft OLE Db Provider
-- LinkedServer.Database.Schema.ObjectName

select * from [172.25.11.11].icms.icmsdb.CMssections where divisionID=154

-- VIEW -----------------------------------------------------------
	-- We can't use BEGIN END in View
	-- We can't update view when we use both table
	-- We can update view only single table is used in view
	-- we can use View only in instead of trigger not in AFTER Trigger.
	--Regular and index views (do not automatically refresh when changes are made to the underlying tables' schema.)

drop view vw_Employee
drop table Employee

CREATE TABLE dbo.Employee
(id INT IDENTITY(1,1), 
FName VARCHAR(50),
LName VARCHAR(50))

INSERT INTO dbo.Employee VALUES('Aamir','Shahzad')
INSERT INTO dbo.Employee VALUES ('Bob','Ladson')

CREATE VIEW dbo.vw_Employee --Create view
AS
SELECT * FROM dbo.Employee

SELECT * FROM dbo.vw_Employee --See data from dbo.vw_Employee View

ALTER TABLE dbo.Employee ADD StreetAddress VARCHAR(100) --Alter the base table that we used in the view

SELECT * FROM dbo.vw_Employee --Check if we are getting StreetAddress column in dbo.vw_Employee

EXEC sp_refreshview 'vw_Employee' --Refresh the View Definition

SELECT * FROM dbo.vw_Employee --Check if column is appearing in view correctly

ALTER TABLE dbo.Employee DROP COLUMN StreetAddress   --drop column from base table

SELECT * FROM dbo.vw_Employee --Run the Select statement on view to get data after dropping column from base table

EXEC sp_refreshview 'dbo.vw_Employee' --Refresh the View Definition

SELECT * FROM dbo.vw_Employee --Check if column is removed and view is working correctly

-------- INDEX View -------------------

create view viewname_sujith
with schemabinding
as
select id from dbo.table_sujith4

/*
Note:
1.select '*' is not allowed
2.Names must be in two-part format ex.dbo.table
3.Cannot DROP TABLE 'DBO.TABLE_SUJITH4' because it is being referenced by object 'VIEWNAME_SUJITH'. */

DROP VIEW VIEWNAME_SUJITH

CREATE VIEW VIEWNAME_SUJITH
WITH ENCRYPTION  -- can not able to take view script
AS
SELECT * FROM DBO.TABLE_SUJITH4

SP_HELPTEXT VIEWNAME_SUJITH

 --Page Life Expectancy -----------------------------------------------------------------------
 PLE is a measure of, on average, how long (in seconds) will a page remain in memory without being accessed, 
	after which point it is removed. 

------------------ Dynamic SQL ----------------------------------------------------------------

Dynamic SQL is the SQL statement that is constructed and executed at runtime based on input parameters passed
Executing dynamic SQL using EXEC/ EXECUTE command

--EXEC command does not re-use the compiled plan stored in the plan cache. 
DECLARE @SQL nvarchar(1000)
declare @Pid varchar(50)
set @pid = '680'  --possibility of SQL injection when you construct the SQL statement by concatenating strings from user input values.
SET @SQL = 'SELECT ProductID,Name,ProductNumber FROM SalesLT.Product where ProductID = '+ @Pid
EXEC (@SQL)

--two separate plans( @CONDITION = 'WHERE price > 5000', reason = SQL Server treats each distinct query as a new query)
DECLARE @CONDITION NVARCHAR(128)
DECLARE @SQL_QUERY NVARCHAR (MAX)
SET @CONDITION = 'WHERE price > 5000'
SET @SQL_QUERY =N'SELECT id, name, price FROM Books '+ @CONDITION
EXECUTE sp_executesql @SQL_QUERY

--same plan (now reuse the execution plan, because the query string doesn't change.)
DECLARE @CONDITION NVARCHAR(128)
DECLARE @SQL_QUERY NVARCHAR(MAX)
DECLARE @PriceThreshold INT
SET @PriceThreshold = 5000
SET @CONDITION = 'WHERE price > @PriceThreshold'
-- Parameterized dynamic SQL
SET @SQL_QUERY = N'SELECT id, name, price FROM Books ' + @CONDITION
-- Execute using sp_executesql with parameters
EXEC sp_executesql @SQL_QUERY, N'@PriceThreshold INT', @PriceThreshold;

--sp_executesql extended SP, reuses the compiled plan when the statement is executed for different parameters.

DECLARE @ProdNumber nvarchar(50)
EXECUTE sp_executesql N' 
		  SELECT  @ProdNumberOUT= ProductNumber
          FROM SalesLT.Product where ProductID = @Pid'
	,N'@Pid varchar(50) ,@ProdNumberOUT nvarchar(25) OUTPUT'
	,@pid = '680'
	, @ProdNumberOUT = @ProdNumber OUTPUT 
SELECT @ProdNumber as ProductNumber

--Temp tables in dynamic SQL
The local temp table created by executing dynamic SQL cannot be accessed outside the execution of dynamic SQL.
It throws invalid object error 

--sp_executesql	`				EXEC Command
Reuses the cached plan		\	Generates multiple plans when executed with different parameters
Less prone to SQL Injection	\	Prone to SQL injection
Supports parameterization	\	Does not support parameterization 
Supports output variable	\	Output variable is not supported
 
----------------------- SQL injection --------------------------------------------

--SQL injection can be executed by concatenating 1 = 1 using the OR clause in a search query
--ex. OR 1 = 1 this query will retrieve all the records from the Books table

DECLARE @BookName NVARCHAR(128)
DECLARE @SQL_QUERY NVARCHAR (MAX)
SET @BookName = '''Book6'' OR 1 = 1'  -- or '''Book6'' OR '''' = '''''  
SET @SQL_QUERY =N'SELECT id, name, price FROM Books WHERE name = '+ @BookName
EXECUTE sp_executesql @SQL_QUERY 

--Preventing SQL injection
The best way to prevent a SQL injection is to use parameterized queries rather than directly embedding 
the user input in a query string.

DECLARE @BookNameValue NVARCHAR(128)
DECLARE @SQL_QUERY NVARCHAR (MAX)
DECLARE @PARAMS NVARCHAR (1000)
SET @BookNameValue = = 'Book6 OR 1 = 1'  -- sql injection testing (no records will be returned[expects a single string value])
SET @PARAMS = '@BookName NVARCHAR(128)'
SET @SQL_QUERY =N'SELECT id, name, price FROM Books WHERE name = @BookName'  
EXECUTE sp_executesql @SQL_QUERY ,@PARAMS, @BookName = @BookNameValue

--------- Identifying long-running or deadlocked queries ----------------------------------------------

-- Step 1: Identify Active Sessions and Blocked Queries
/*
SPID (Session ID) of the active sessions.
Status (e.g., Running, Sleeping, etc.).
Login Name and Host Name.
Blocked (SPID of the session that is blocking the current session). */

EXEC sp_who2; 

--- 
/*
The blocked session ID (i.e., the session being blocked).
The blocking session ID (i.e., the session causing the block).
The waiting type (e.g., LCK_M_X for a lock). Wait types that could point to issues like locking, I/O waits, or memory pressure.
Query text: The exact SQL causing the block.
Session start time and percent complete (for long-running queries)
*/
SELECT qs.session_id, 
       qs.blocking_session_id,
       qs.status,
       qs.start_time,
       qs.percent_complete,
       qs.wait_type,
       qs.wait_time,
       qss.login_name,
       qss.host_name,
       qt.text AS query_text
FROM sys.dm_exec_requests qs
JOIN sys.dm_exec_sessions qss
    ON qs.session_id = qss.session_id
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE qs.blocking_session_id <> 0;

--3
/*
Use this command to view the last executed query for a specific session (SPID).
This is especially helpful for finding the exact SQL query that caused the issue, especially in long-running queries or when blocking occurs. */

DBCC INPUTBUFFER(SPID); --used to retrieve the last executed query not current one

--4
--SET STATISTICS IO provides insight into the logical reads (memory), physical reads (disk), and the number of reads required.
--SET STATISTICS TIME shows how long the query took to execute (CPU and total time).
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

--Step 5: Review and Optimize Execution Plans
/*
Table Scans: Indicate a lack of useful indexes or outdated statistics.
Key Lookups: Can be replaced with covering indexes.
Missing Index Warnings: Look for recommendations to add indexes based on the query pattern.
*/
--Step 6: Optimize Query Logic
/*
CTEs (Common Table Expressions): Simplify complex queries and improve readability.
Temp Tables: Use for intermediate results instead of recalculating in subqueries.
Avoid Cursors: Replace row-by-row logic with set-based operations.
Use Indexed Columns for Joins/Where Clauses: Ensure that queries filter or join on indexed columns to speed up execution.
*/
--Step 7: Index Optimization

SELECT 
    OBJECT_NAME(IXOS.OBJECT_ID) AS TableName,
    IX.name AS IndexName,
    IXOS.avg_fragmentation_in_percent AS Fragmentation
FROM SYS.DM_DB_INDEX_OPERATIONAL_STATS(NULL, NULL, NULL, NULL) AS IXOS
INNER JOIN SYS.INDEXES AS IX
    ON IX.OBJECT_ID = IXOS.OBJECT_ID
    AND IX.INDEX_ID = IXOS.INDEX_ID
WHERE OBJECTPROPERTY(IX.OBJECT_ID, 'IsUserTable') = 1;

-- Rebuild
ALTER INDEX IndexName ON TableName REBUILD;
-- Reorganize
ALTER INDEX IndexName ON TableName REORGANIZE;

--Step 8: Partitioning for Large Tables
-- Create Partition Function
CREATE PARTITION FUNCTION DateRangePF (DATETIME)
AS RANGE RIGHT FOR VALUES ('2020-01-01', '2021-01-01', '2022-01-01');

-- Create Partition Scheme
CREATE PARTITION SCHEME DateRangePS
AS PARTITION DateRangePF
TO (PRIMARY, FG2020, FG2021, FG2022);
--Step 9: Address Parameter Sniffing & Recompilation

--- creating dead loack--------------------------------------------

DROP TABLE IF EXISTS Table_A
CREATE TABLE Table_A (Id INT PRIMARY KEY, FruitName VARCHAR(100))
GO
INSERT INTO Table_A VALUES(1,'Lemon')
INSERT INTO Table_A VALUES(2,'Apple')
GO
DROP TABLE  IF EXISTS Table_B
CREATE TABLE Table_B (Id INT PRIMARY KEY, FruitName VARCHAR(100))
GO
INSERT INTO  Table_B VALUES(1,'Banana')
INSERT INTO Table_B VALUES(2,'Orange')

select db_name(qs.database_id), qs.status, start_time, getdate() as current__time,    
percent_complete, wait_type, wait_resource, wait_time, sql_handle, plan_handle, text,    
qs.session_id, qs.blocking_session_id,     qss.login_name, qss.host_name,        
substring(qt.text, qs.statement_start_offset/2+1,     
(qs.statement_Start_offset + case when qs.statement_end_offset = -1       
						then len(convert(nvarchar(max),qt.text + ' ')) *2       
						else qs.statement_end_offset end)/2) as query_text,    
qt.dbid,qt.objectid, qp.query_plan  
from sys.dm_exec_requests qs  
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt  
cross apply sys.dm_exec_query_plan(qs.plan_handle) as qp  
join sys.dm_exec_sessions qss on qs.session_id = qss.session_id
where qs.session_id <> 68

-- One window
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRAN
UPDATE Table_A SET FruitName ='Mango' WHERE Id=1
WAITFOR DELAY '00:00:59'
UPDATE Table_B SET FruitName ='Avacado' WHERE Id=1
COMMIT TRAN

--Another window run this query
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRAN
UPDATE Table_B SET FruitName ='Papaya' WHERE Id=1
WAITFOR DELAY '00:00:59'
UPDATE Table_A SET FruitName ='Kiwi' WHERE Id=1
COMMIT TRAN

--Error
(1 row affected)
Msg 1205, Level 13, State 51, Line 9
Transaction (Process ID 52) was deadlocked on lock resources with another process and has been chosen 
	as the deadlock victim. Rerun the transaction.

---- Question -------------------------------------------------------------------

--Write a query to find the row IDs for which at least one of the three columns Col1, Col2 or Col3 contains the color “Red”, but without using OR.?

create table colors_tbl(id int,col1 varchar(5),col2 varchar(5), col3 varchar(5))

insert into colors_tbl
select 1	,'Red',	'Yellow',	'Blue'
union all
select 2	,NULL	,'Red',	'Green'
union all
select 3	,'Yellow',	NULL,	'Violet'

Select id from colors_tbl where col1 = 'Red'
Union 
Select id from colors_tbl where col2 = 'Red'
Union 
Select id from colors_tbl where col3 = 'Red'

--Find all documents filed by Rockomax that are of formType “Marketing Materials” and not formType “Spec Sheet”. 
--Return the documentId, creationDate, and formType . 

create table AttributeType_tbl ( attributeTypeId int,attributeName varchar(20))
insert into AttributeType_tbl
select 1	,'filingDate'
union all
select 2	,'formType'
union all
select 3	,'filingCompany'

create table Document_tbl(documentid int,creationDate date)
insert into Document_tbl
select 2	,'2013-03-30'
union all
select 6	,'1987-06-03'
union all
select 11	,'2012-01-20'

create table File_tbl(fileid int,documentid int,filename varchar(40))
insert into File_tbl
select 1,	2,	'OKTO2.pdf'
union all
select 4,	6,	'"Mainsail" Liquid Engine.xlsx'
union all
select 10,	11,	'"Poodle" Liquid Engine.docx'

create table Attribute_tbl(attributeId int,documentId int,attributeTypeId int,attributeValue varchar(30))
insert into Attribute_tbl
select 1,	6	,2	,'Marketing Materials' union all
select 2,	6	,2	,'Spec Sheet' union all
select 3,	6	,1	,'3/31/1987' union all
select 4,	6	,3	,'Rockomax' union all
select 5,	2	,1	,'1/1/2013' union all
select 6,	2	,2	,'Marketing Materials' union all
select 7,	2	,3	,'Probodobodyne' union all
select 8,	11	,2	,'Marketing Materials' union all
select 9,	11	,1	,'1/2/2012' union all
select 10,	11	,3	,'Rockomax'


Find all documents filed by Rockomax that are of formType “Marketing Materials” and not formType “Spec Sheet”.
Return the documentId, creationDate, and formType . 

Select a.documentid, d.creationdate, a.attributevalue as formtype
From attribute_tbl a
Join attributetype_tbl at on a.attributetypeid = at.attributetypeid
Join document_tbl d on a.documentid = d.documentid
Where a.attributetypeid = 3 
	and a.attributevalue = 'rockomax'
	and a.documentid not in (
						select distinct a.documentid --at.attributeName 
						from AttributeType_tbl at
						join Attribute_tbl a on at.attributeTypeId = a.attributeTypeId 
						where at.attributeTypeId = 2 and a.attributeValue = 'Spec Sheet' 
							)

--Delete the Records in Small Chunks from SQL Server Table -------------------------------

DECLARE @DeleteRowCnt INT
DECLARE @DeleteBatchSize INT
SET @DeleteRowCnt = 1
SET @DeleteBatchSize=100000
WHILE (@DeleteRowCnt > 0)
	BEGIN
		DELETE TOP (@DeleteBatchSize) [dbo].[Customer]  
		WHERE RegionCD='NA'
	SET @DeleteRowCnt = @@ROWCOUNT;
	END

---Create Computed Columns Full Name and IsSenior depending upon our criteria.---------

drop table Customer
CREATE TABLE Customer (
    CustomerId INT Identity(1, 1)
    ,FirstName VARCHAR(50)
    ,LastName VARCHAR(50)
    ,Age SMALLINT
    ,PhoneNumber CHAR(9)
    ,DOB DATE
    ,Gender CHAR(1)
    ,FullName AS FirstName + ' ' + LastName
    ,IsSenior AS CASE 
        WHEN Age > 65
            THEN 1
        ELSE 0
        END
    )

insert into dbo.Customer(FirstName,LastName,Age)
Values('Aamir','Shahzad',66),('Raza','M',44)

select * from dbo.Customer
Alter table dbo.Customer Add FullName AS FirstName+' '+LastName
Alter table dbo.Customer drop column FullName

--*****  Get the highest earning salesman in each department *************
	
CREATE table #Orders(OrderId int,Deptno int,Amount int)
CREATE table #sales (orderId int, salesmanId int )

INSERT INTO #Orders
SELECT 1,11,4000
union all
SELECT 2,11,2500
UNION ALL
SELECT 3,12,2500
UNION ALL
SELECT 4,12,6000
UNION ALL
SELECT 5,13,3000

INSERT INTO #sales
SELECT 1,55
UNION ALL
SELECT 2,55
UNION ALL
SELECT 3,57
UNION ALL
SELECT 4,58
UNION ALL
SELECT 5,59

drop TABLE #Orders
drop TABLE #sales

SELECT * FROM  #Orders
SELECT * FROM  #sales

SELECT  C.salesmanId, TEMP.DeptNO, TEMP.Amount 
FROM (
	SELECT B.OrderId ,A.DeptNO, A.Amount
	FROM (Select   DeptNO , max(Amount) Amount  
			FROM Orders GRoup BY DeptNO ) A
	JOIN Orders B ON A.DeptNo = B.DeptNo 
		AND A.Amount= B.Amount) TEMP
Join Sales C On TEMP.OrderID= C.OrderID

-- (OR)
SELECT C.OrderId,C.salesmanId,C.Deptno, C.Amount  
FROM (
	SELECT O.OrderId,S.salesmanId,O.Deptno, O.Amount,DENSE_RANK() OVER(PARTITION BY O.Deptno ORDER BY O.AMOUNT DESC) AS DeptSalRank
	FROM Orders O JOIN Sales S ON O.orderId = S.orderId 
	) AS C
WHERE C.DeptSalRank = 1

---***** To insert a row by row from a word ******************************************
ex:hello
h
e
l
l
o

DECLARE @name varchar(10)
DECLARE @c int
SET @c=1
SET @name ='Akhilesh'
WHILE @c<=len(@name)
BEGIN
	SELECT substring(@name,@c,1) -- 1.101
	SET @c=@c+1
	-- or
	--SELECT substring(@len,1,1)
	--SET @len = substring(@len,2,len(@len))
END

-- 1.101
SELECT substring(@name,@c,len(@name))
water
ater
ter
er
r 

--******* To Update row by row(iterate) Using Cursor & While Loop ****************

drop table #temp
create table #temp(idd int identity(1,1),id int,name varchar(20),tax int)

insert into #temp
select 1,'a',0
union all
select 2,'b',1
union all
select 3,'c',0

select * from #temp

-- Using Cursor Loop
DECLARE @idd int
DECLARE @a int
set @a = 1
DECLARE cursorname cursor for
select idd from #temp
open cursorname
fetch next from cursorname INTO @idd 
WHILE @@fetch_status = 0
BEGIN 
	update #temp set tax = 1 WHERE tax = 0 and idd = @a
	set @a = @a + 1
	fetch next from cursorname into @idd
end
close cursorname
DEALLOCATE cursorname

-- Using While Loop
DECLARE @max int
set @max = 0
DECLARE @a int
set @a = 1
select @max = count(*) from #temp
WHILE @a <= @max
BEGIN 
	update #temp set tax = 1 WHERE tax = 0 and idd = @a
	set @a = @a + 1
END

--**** Insert--************* ( print - message, select - result ) ************************

CREATE TABLE temp_sujith2(id int)

-- error ( running continuously)
DECLARE @count int
set @count  =1
while @count < = 10
begin 
	insert into temp_sujith2
	select @count
END

-- insert 1 to 10  with loop(it will insert 10 row continue's ly )
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	INSERT into temp_sujith2(id) values(@A)
	PRINT @A
	select @a
	SET @A = @A + 1
END

-- it will insert divided values : O/P 3,6,9
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	IF @A %3 = 0
	BEGIN 
		insert into temp_sujith2(id) values(@A)
		print @A
	END
	SET @A = @A + 1
END
		
--(it will insert 1 to 10 and print 3,6,9)
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	insert into temp_sujith2(id) values(@A)
	IF @A %3 = 0
		PRINT @A
	SET @A = @A + 1
END

--(it will insert first 3 rows )
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	insert into temp_sujith2(id) values(@A)
	IF @A %3 = 0
	begin
		PRINT @A
		BREAK
	end
	SET @A = @A + 1
END

--(it will insert 1 row only )
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	insert into temp_sujith2(id) values(@A)
	IF @A %3 = 0
	begin
		PRINT @A
	end
	BREAK
	SET @A = @A + 1
END

--(it will insert 1 to 10 and print 3,6,9) [Using Begin Commit] )
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	BEGIN TRAN 
		insert into temp_sujith2(id) values(@A)
		IF @A %3 = 0
		BEGIN 
			PRINT @A
		END
	COMMIT TRAN
	SET @A = @A + 1
END

--(it will insert 1st 3 row ly [Using Begin Commit] )
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	BEGIN TRAN 
		insert into temp_sujith2(id) values(@A)
		IF @A %3 = 0
		BEGIN 
			PRINT @A
			BREAK
		END
	COMMIT TRAN
	SET @A = @A + 1
END

--(it will insert 1 row only ) using BEGIN TRANS
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	BEGIN TRAN 
		insert into temp_sujith2(id) values(@A)
		IF @A %3 = 0
		BEGIN 
			PRINT @A		
		END
	COMMIT TRAN
	BREAK
	SET @A = @A + 1
END
												
SELECT * FROM TEMP_SUJITH
TRUNCATE TABLE TEMP_SUJITH2
DROP TABLE TEMP_SUJITH2

-- print 1 to 10  with loop(it will insert 10 row continue's ly )
DECLARE @A INT
SET @A = 1
WHILE @A <=10
BEGIN
	PRINT @A
	SET @A = @A + 1
END

-- print 1 to 10  without loop ( The maximum recursion 100 only allowd)

; WITH cte as  
(  
	SELECT 1 number  
	union all
	select number +1 from cte where number<=10  -- The maximum recursion 100  ex. number<=100
)  
select *from cte

---data representing an organizational hierarchy: using recursive CTE ( to find level of all employee)

;WITH EmployeeHierarchy AS
(
    -- Base Case: Select the top-level employees (those who have no manager, i.e., ManagerID is NULL)
    SELECT EmployeeID, EmployeeName, ManagerID, 0 AS Level
    FROM Employees
    WHERE ManagerID IS NULL
    
    UNION ALL
    
    -- Recursive Case: Select employees who report to the previous level of employees
    SELECT e.EmployeeID, e.EmployeeName, e.ManagerID, eh.Level + 1 AS Level
    FROM Employees e
    INNER JOIN EmployeeHierarchy eh ON e.ManagerID = eh.EmployeeID
)
-- Select the results from the CTE (this will return the hierarchy)
SELECT EmployeeID, EmployeeName, ManagerID, Level
FROM EmployeeHierarchy
ORDER BY Level, ManagerID, EmployeeName;

----------------------------------------------------------------------

SELECT TOP 1 1 FROM temp_sujith2 -- 1(having data) else empty(blank) 
SELECT 1 FROM temp_sujith2 --1(having data) else empty(blank)
	
SELECT SUM(1) from temp_sujith2 -- null (if table dont have data)
SELECT COUNT(*) FROM temp_sujith2 -- 0 (if table dont have data)

SELECT 1  temp_sujith2 -- 1
SELECT SUM(1) temp_sujith2 --  1 
SELECT TOP 1 1  temp_sujith2 -- 1
		
SELECT * INTO A_SUIJTH FROM B WHERE 1 = 1   -- copy table structure & data 
SELECT * INTO B FROM CNFSTATE WHERE 1 = 2   -- copy only table structure

SELECT * FROM CNFCONTAINERMASTER 1, CNFSTATE 2 -- error (Numbers are not allowed as table aliases. In many databases)
SELECT * FROM CNFCONTAINERMASTER "1", CNFSTATE "2"  -- works like Cross Join 
SELECT * FROM CNFCONTAINERMASTER CROSS JOIN CNFSTATE
SELECT * FROM CNFCONTAINERMASTER, CNFSTATE -- CROSSS JOIN
SELECT * FROM CNFCONTAINERMASTER A JOIN CNFSTATE B ON 1=1  -- works like Cross Join   

--------------------------------------------------------------------
-- it will allow duplicate value in index

CREATE TABLE table_suji7( id INT)
INSERT INTO table_suji7
SELECT 2
union all
SELECT 2

CREATE CLUSTERED INDEX index_sujith ON table_suji7(id)

SELECT * FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS -- to find Constraints in table
SELECT * FROM sys.index_columns 
SP_HELPINDEX index_sujith
SELECT * FROM sys.indexes WHERE name like '%sujith%' -- to find inde in table
/*
object_id	name							index_id	type	type_desc

245575913	PK__CNFAccou__780802054973B490	1			1		CLUSTERED
245575913	UQ__CNFAccou__9FAD835D28F95DA4	2			2		NONCLUSTERED
245575913	UQ__CNFAccou__01ED93F79CD55962	3			2		NONCLUSTERED
297768118	NULL							0			0		HEAP -- no index in table */

drop index index_sujith ON table_suji7
drop table table_suji7
	
--------------------- COLUMN STORE INDEX ----------------------------------------------

https://www.sqlservercentral.com/Forums/1852220/RE-How-to-choose-between-Clustered-Columnstore-NonClustered-Columnstore-index
it possible to create a column store index on a table in sql which already has a clustered index & non clustered index over it ?

CREATE TABLE SimpleTable
(ProductKey [int] NOT NULL, 
OrderDateKey [int] NOT NULL, 
DueDateKey [int] NOT NULL, 
ShipDateKey [int] NOT NULL);

CREATE CLUSTERED INDEX cl_simple ON SimpleTable (ProductKey);

CREATE NONCLUSTERED INDEX noncl_simple ON SimpleTable(OrderDateKey);

CREATE NONCLUSTERED COLUMNSTORE INDEX csindx_simple
ON SimpleTable(OrderDateKey, DueDateKey, ShipDateKey);

-- we can create unique with foreign key -----------------------

CREATE TABLE Countries (
    CountryID INT PRIMARY KEY,
    CountryName NVARCHAR(100)
);

CREATE TABLE Cities (
    CityID INT PRIMARY KEY,
    CityName NVARCHAR(100),
    CountryID INT UNIQUE,  -- Unique constraint ensures only one city per country
    FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)  -- Foreign key constraint
);

-- set rowcount(deprecated) ---------------
SET ROWCOUNT 2
select * from table_sujith6
SET ROWCOUNT 0

---Retrun vs OUTPUT CLAUSE vs OUTPUT PARAMETER--------------

--RETURN is used for simple status codes or exit codes.
--OUTPUT CLAUSE is used for capturing affected rows in DML statements.(we can use in sp , but can not call back like output parameter, )
--OUTPUT PARAMETER is used to return values from a stored procedure or function to the caller.

--output clause

DECLARE @InsertedValues TABLE (EmployeeID INT, EmployeeName NVARCHAR(100));

INSERT INTO Employees (EmployeeName) -- Insert a new employee and capture the inserted values
OUTPUT INSERTED.EmployeeID, INSERTED.EmployeeName INTO @InsertedValues
VALUES ('John Doe');

SELECT * FROM @InsertedValues;

	DELETE FROM Employees
	OUTPUT DELETED.EmployeeID, DELETED.EmployeeName INTO @DeletedValues
	WHERE EmployeeName = 'Jane Doe';

	UPDATE Employees 	-- Update employee name and capture both old and new values
	SET EmployeeName = 'Jane Doe'
	OUTPUT DELETED.EmployeeID, DELETED.EmployeeName AS OldName, INSERTED.EmployeeName AS NewName
	INTO @UpdatedValues
	WHERE EmployeeName = 'John Doe';

--return

CREATE PROCEDURE GetEmployeeCount
AS
BEGIN
    DECLARE @EmployeeCount INT;
    SELECT @EmployeeCount = COUNT(*) FROM Employees;
    
    RETURN @EmployeeCount;     -- Return the employee count as an integer
END

DECLARE @ReturnValue INT;
EXEC @ReturnValue = GetEmployeeCount;
PRINT @ReturnValue;

--output parameter

CREATE PROCEDURE GetEmployeeDetails
    @EmployeeID INT,
    @EmployeeName NVARCHAR(100) OUTPUT
AS
BEGIN
    SELECT @EmployeeName = EmployeeName
    FROM Employees
    WHERE EmployeeID = @EmployeeID;
END;
DECLARE @Name NVARCHAR(100);
EXEC GetEmployeeDetails @EmployeeID = 1, @EmployeeName = @Name OUTPUT;
SELECT @Name AS EmployeeName;

--3 Max sal--------------------------------

 SELECT HRPartnerEmpID from CMSSAPEmployee 
 where HRPartnerEmpID <  (SELECT max(HRPartnerEmpID) FROm  CMSSAPEmployee 
							where HRPartnerEmpID < (SELECT max(HRPartnerEmpID) FROm  CMSSAPEmployee))

---- Derived Table -------------------

DELETE cc FROM 
(
	SELECT cityid,cityname FROM aa 
) AS cc

DELETE CC FROM 
(
	SELECT *,ROW_NUMBER() OVER(ORDER BY CITYID ASC) AS AA FROM aa_table 
) CC 
WHERE CC.AA > 100

update cc 
SET cityname = 'sss' 
FROM (
		SELECT cityid,cityname FROM aa 
	  ) AS cc

--- UPDATE ROWS IN LOOP 10 BY 10-------------

CREATE TABLE AA_B(ID INT,DD INT)

DECLARE @A INT
DECLARE @AA INT
DECLARE @B INT
SET @B = 1
SELECT @A = MIN(CITYID) FROM aa_table
SELECT @AA = MAX(CITYID) FROM aa_table
WHILE @A < = @AA
BEGIN 
	INSERT INTO AA_B(ID,DD)
	SELECT CITYID, @B FROM aa_table WHERE CITYID BETWEEN @A AND @A + 9 -- OR WHERE CITYID >= @A AND CITYID < = @A + 9

	-- OR 
	--UPDATE aa_table SET CITYNAME = @B
	--WHERE CITYID BETWEEN @A AND @A + 9  -- OR WHERE CITYID >= @A AND CITYID < = @A + 9

	SET @A = @A + 10
	SET @B = @B + 1
END

TRUNCATE TABLE AA_B
DROP TABLE AA_B,aa_table

-- TRANSACTION -----

CREATE TABLE DDD_TABLE(ID INT)

BEGIN TRAN
	INSERT INTO DDD_TABLE
	SELECT 1
SAVE TRAN A
	INSERT INTO DDD_TABLE
	SELECT 2
SAVE TRAN B
	INSERT INTO DDD_TABLE
	SELECT 3
SAVE TRAN C 

ROLLBACK TRAN C --1,2
ROLLBACK TRAN B --1

COMMIT TRAN

TRUNCATE TABLE DDD_TABLE
SELECT * from DDD_TABLE

-- SELECT DUPLICATE VALUE -----------

SELECT CITYNAME FROM RR_TABLE
GROUP BY CITYNAME
HAVING COUNT(CITYNAME) >1
-- or
SELECT CITYNAME,COUNT(CITYNAME) AS CNT FROM RR_TABLE
GROUP BY CITYNAME
HAVING COUNT(CITYNAME) >1

WITH CTE AS
(
SELECT *,ROW_NUMBER() OVER(PARTITION BY CITYNAME ORDER BY CITYNAME) AS DD FROM RR_TABLE
)
SELECT * FROM CTE WHERE DD >1 
-- DELETE FROM CTE WHERE DD >1

SELECT * FROM 
--DELETE CC FROM 
(
SELECT *,ROW_NUMBER() OVER(PARTITION BY CITYNAME ORDER BY CITYNAME) AS DD FROM RR_TABLE
) CC
WHERE CC.DD>1

-- SELECT ORIGINAL & DUPLICATE VALUE-----

--Only one expression can be specified in the select list when the subquery is not introduced with EXISTS.
SELECT * FROM RR_TABLE 
WHERE CITYNAME IN (SELECT CITYNAME FROM RR_TABLE GROUP BY CITYNAME HAVING COUNT(*) >1) 

SELECT * FROM RR_TABLE A
WHERE EXISTS (SELECT * FROM RR_TABLE WHERE A.CITYNAME = CITYNAME GROUP BY CITYNAME HAVING COUNT(*) >1) -- corelated subquery to find

SELECT * 
FROM RR_TABLE T 
INNER JOIN (SELECT CityName,ROW_NUMBER() OVER(PARTITION BY CITYNAME ORDER BY CITYNAME) AS DD FROM RR_TABLE ) R	
	ON T.CityName = R.CityName
WHERE R.DD >1

-- ERROR Derived table 'cc' is not updatable because it contains aggregates, or a DISTINCT or GROUP BY clause, or PIVOT or UNPIVOT operator.
delete cc from (
	select cityname from  aa_table
	GROUP BY CITYNAME
	HAVING COUNT(CITYNAME) >1
	) cc 

-- (OR ) select original & duplicate value
Create Table #tmptest
(
ID INT,
NM VARCHAR(50)
)
INSERT INTO #tmptest Values(1,'san')
INSERT INTO #tmptest Values(2,'sank')
INSERT INTO #tmptest Values(3,'sanka')
INSERT INTO #tmptest Values(3,'sankar')
INSERT INTO #tmptest Values(4,'sant')
INSERT INTO #tmptest Values(5,'santh')
INSERT INTO #tmptest Values(5,'santho')

select * from #tmptest

WITH CTES AS
(
Select ID FROM #tmptest
GROUP BY ID
HAVING COUNT(*) >1
)
SELECT * FROM CTES A 
JOIN #TMPtest B On A.ID= B.Id 

-- or
with cte as 
(
select *,row_number() over(partition by cityname order by cityname) as cc from aa_table
)
select * from cte 
where a.cc>1

DROP TABLE #tmptest

-- Instead of Trigger --------------------------------------------------------

-- WHEN WE DROP All the table, trigger automatically droped 
CREATE TRIGGER DBSP_Trigger_Insertsujith
	ON RR_TABLE
INSTEAD OF DELETE
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @CityID  INT
	DECLARE @CityName VARCHAR(11)

	SET @CityID= 0
	SET @CityName=''

	SELECT @CityID = ISNULL(CityID,''), @CityName = ISNULL(CityName,'')
	FROM DELETED 
	-- The logical tables INSERTED and DELETED cannot be updated.
	DELETE FROM RR_TABLE WHERE CITYID = @CityID -- VALUE WILL BE DELETED
	--ROLLBACK -- VALUE WILL BE REVERT,SO IT NOT DELETED

	-- if no rows deleted then uu_table value will not be inserted
	if	@@rowcount = 0
			return

	INSERT INTO UU_TABLE
	SELECT @CityID

	SET NOCOUNT OFF
END

-- sql server has only ONE LOOP that is While loop--

DECLARE @LoopCounter INT = 0
WHILE ( @LoopCounter <= 3)
BEGIN
	SET @LoopCounter  = @LoopCounter  + 1 

	IF(@LoopCounter = 2)
		CONTINUE 
	PRINT @LoopCounter 
END
PRINT 'Statement after while loop'


DECLARE @intFlag INT
SET @intFlag = 1
WHILE (@intFlag <=5)
BEGIN
	PRINT @intFlag
	SET @intFlag = @intFlag + 1
	CONTINUE;
	IF @intFlag = 4 -- This will never executed
	BREAK;
END

-- DO While
DECLARE @I INT=1;
WHILE (1=1)              -- DO
BEGIN
  PRINT @I;
  SET @I=@I +1;--@I+=1;
  IF NOT (@I<=10) BREAK; -- WHILE @I<=10
END

DECLARE @LoopCounter INT = 1
WHILE(1=1)
BEGIN
   PRINT @LoopCounter
   SET @LoopCounter  = @LoopCounter  + 1    
   IF(@LoopCounter > 4)
	BREAK;         
END

-- onther way of do While
DECLARE @X INT=1;
res:  --> Here the  DO statement
  PRINT @X;
  SET @X += 1;
IF @X<=10 GOTO res; --> Here the WHILE @X<=1 

-- the loop would terminate once the @@FETCH_STATUS no longer equals 0, as specified by: -----

WHILE @@FETCH_STATUS = 0

-------------------------
select * from sys.schemas -- to see list of schema
select * from sys.sql_modules where object_id = 1182627256 -- to see sp,view,trigger function CODE IN TEXT
select * from sys.objects where type = 'v'

SET STATISTICS IO ON
SET STATISTICS IO OFF

select * from cnfcity as rows
for xml auto, elements,root('rows')

DROP TABLE IF EXISTS sales2;

-- GROUP BY -----------------------------

SELECT SUM(QUOTID),DEPTID,
	'' AS FinYearID  --always return an empty string for every row, since it's just a constant and not a column in the table.(query will work)
from  CNFDOCKET
GROUP BY DEPTID

---  WHERE -----------------------------
DECLARE @A INT
SET @A = 3
DECLARE @B INT
SET @B = 10
SELECT CASE WHEN @A = 1 THEN 0
			WHEN @A = 2 THEN 10
			WHEN @A = 3 THEN CASE WHEN @B = 10 THEN 999 ELSE 555 END 
			ELSE '' END 

----------BASIC CURSOR-----------------

DECLARE @NAME VARCHAR(40)
DECLARE @COUNT INT
SET @COUNT = 1
DECLARE CURNAME CURSOR FOR 
SELECT TOP 10 CityName FROM CNFCITY WHERE STATEID = 32
OPEN CURNAME
FETCH FROM CURNAME INTO @NAME
WHILE @@FETCH_sTATUS = 0
BEGIN 
	SELECT @NAME + ' - ' + CAST(@COUNT AS VARCHAR)
	FETCH FROM CURNAME INTO @NAME
	SET @COUNT = @COUNT + 1
END
CLOSE CURNAME
DEALLOCATE CURNAME

-- In UNION ALL not necessary to give column name to every line ----------------

SELECT 'VendorID' AS ColumnHeader,'0'  AS ColumnWidth,'VendorID' AS DataField 
UNION ALL 
SELECT 'VendorName','20', 'VendorName' 
UNION ALL 
SELECT 'AssetCatgID','0', 'AssetCatgID' 

------UNPivot----------------------------------------
-- if any one column in other type datatype then we have to convert all the field into same datatype. ex varchar
-- when we display column it shows error insteaded of ColumnName.

CREATE TABLE #CNFState(StateID INT,StateName VARCHAR(100),StateCode VARCHAR(10))

INSERT INTO #CNFState
SELECT 1,'ANDHRA PRADESH','23'
UNION ALL
SELECT 1,'BIHAR','66'
UNION ALL
SELECT 1,'DELHI','11'
UNION ALL
SELECT 1,'KERALA','02'

SELECT ColumnName, ColumnValue FROM 
( 
	SELECT CAST(StateID AS VARCHAR(50)) AS StateID ,
		StateName, 
		StateCode 
	FROM #CNFState
) AS X 
unPIVOT 
( 
	ColumnValue 
	FOR ColumnName IN (StateName,StateCode)
) AS Z

-- SELECT DISTINCT TYPE,TYPE_DESC  FROM SYS.OBJECTS ------------

type	type_desc

FN		SQL_SCALAR_FUNCTION
UQ		UNIQUE_CONSTRAINT
SQ		SERVICE_QUEUE
F 		FOREIGN_KEY_CONSTRAINT
U 		USER_TABLE
D 		DEFAULT_CONSTRAINT
PK		PRIMARY_KEY_CONSTRAINT
V 		VIEW
S 		SYSTEM_TABLE
IT		INTERNAL_TABLE
P 		SQL_STORED_PROCEDURE
TF		SQL_TABLE_VALUED_FUNCTION

------------------------------------------------------------------------
--Q. Table having duplicate values how to update first non duplicate id in all duplicates ?
--Q. Create id,dupid as column name( set id column as identity(1,1) )
--Q. update first non duplicate values id in duplicate column
	/*ex:
		firstName LastName    id  dupid
		sankar	  arumugam	  1	   NULL
		sankar1	  arumugam1	  2	   NULL
		sankar	  arumugam	  3	   1 */ -- sankar has two values

CREATE TABLE tbl_Test(firstName varchar(25),LastName varchar(25))
INSERT INTO tbl_Test
SELECT 'sankar','arumugam'
UNION ALL
SELECT 'sankar1','arumugam1'
UNION ALL
SELECT 'sankar','arumugam'
	
SELECT * FROM tbl_Test
	
ALTER TABLE tbl_Test ADD tid INT IDENTITY(1,1)
ALTER TABLE tbl_Test ADD dupid INT 

SELECT *,ROW_NUMBER() OVER(PARTITION BY FirstName,lastname ORDER BY TID ) as pgid FROM tbl_Test

Update TT SET Tt.dupID=Tmp.grp
--select tt.tid, tt.FirstName, tt.LastName, Tmp.Pgrp
FROM tbl_Test tt
JOIN (
		SELECT tid, FirstName, LastName ,
			Row_Number() OVER(PARTITION BY firstName,lastname ORDER BY TID)Pgrp
			,Dense_Rank() OVER(ORDER BY FirstName,lastname)grp 
		FROM tbl_test
		) Tmp  ON
	tt.TID = tmp.TID
WHERE Tmp.Pgrp >1

DROP TABLE tbl_Test

-- to insert 1 by 1 ---------------------------

Declare @Cnt INT
Declare @Init INT

CREATE TABLE #TmpCompanies (
	RowId		INT Identity(1,1),
	CompId	INT )

CREATE TABLE #TmpResult (
	Col1	varchar(50) )

Select @Cnt = Count(*) From #TmpCompanies
Set @Init = 1

WHILE @Init <= @Cnt
BEGIN
	DECLARE @CompId	INT
	SELECT @CompId = CompId FROM #TmpCompanies WHERE RowId = @Init
	Insert Into #TmpResult
	EXEC SP_NAME @CompId

	SET @Init = @Init + 1
END

----------------------------------------

Create table #tmp_test
(
	Rid INT IDENTITY(1,1),
	RNo INT,
	Alhpa CHAR(1)
)

INSERT INTO #tmp_test Values(4,'A')
INSERT INTO #tmp_test Values(NULL,'B')
INSERT INTO #tmp_test Values(1,'C')
INSERT INTO #tmp_test Values(NULL,'D')
INSERT INTO #tmp_test Values(6,'E')
INSERT INTO #tmp_test Values(NULL,'F')

SELECT * From #tmp_test

-- want outut like this from above table
SELEct d.Alhpa,a.alhpa
FROM #tmp_test D 
left JOIN #tmp_test A on d.rno = a.rid

DROP TABLE #tmp_test

-- joining NUll with NULL ----------------------------------------------------------------
--INNER JOIN: NULL values from both sides will not match (no result).
--FULL JOIN: NULL values from both sides will match (you get two rows with NULL values).

create table #temp1(id int)
insert into #temp1
select null

create table #temp2(id int)
insert into #temp2
select null

select a.id,b.id
from #temp1 a join #temp2 b on a.id  = b.id

select a.id,b.id
from #temp1 a full join #temp2 b on a.id  = b.id

update #temp1 set id = 4
truncate table #temp1

select * from #temp1
select * from #temp2

---------- Constaint ---------------------------------------
-- Table Level constaint 

CREATE TABLE #temp1
(
	FULLNAME VARCHAR(100),
	[ADDRESS] VARCHAR(100),
	DOB DATE,
	MOBILENO BIGINT,  --(up to 19 digits) // INT column is 2,147,483,647
	CONSTRAINT CONS_MOBILELENTH CHECK ( len(mobileno) = 10 ), -- it created as  CONS_MOBILELENTH 
	CHECK ( dob < getdate()) -- default it created as  CK__#temp1_____dob__AF901981
)

-- Column Level constaint
CREATE TABLE #temp1
(
	FULLNAME VARCHAR(100),
	[ADDRESS] VARCHAR(100),
	DOB DATE,
	MOBILENO BIGINT 
)

ALTER TABLE #TEMP1 ADD CONSTRAINT CONS_MOBILELENTH1 CHECK ( len(mobileno) = 10 )
ALTER TABLE #TEMP1 ADD CONSTRAINT CONS_DOB CHECK ( dob < getdate() )

INSERT INTO #temp1 
SELECT 'Ajay Kumar','#7,abc street,meeyan,chepauk,chennai-600005','2017-01-28','9600660312' 
union all
SELECT 'rajan','  7 neru street,anna square,triplicane,chennai-600005','2017-01-28','9600660312' 

select * from #temp1
drop table #temp1
drop table #temp2

CREATE TABLE #temp2
(
	firstname VARCHAR(100),
	lastname VARCHAR(100),
	doorno int,
	streetname varchar(100),
	locality varchar(100),
	pincode int,
)

select * from #temp1

select SUBSTRING([ADDRESS],Patindex('%[0-9]%',[ADDRESS]),LEN([ADDRESS])) as doorno from #temp1
SELECT [ADDRESS], 
		SUBSTRING([ADDRESS],PatINdex('%[0-9]%',[ADDRESS]),
					PATINDEX('%[^0-9]%',SUBSTRING([ADDRESS],PatINdex('%[0-9]%',[ADDRESS]),LEN([ADDRESS]))
							) - 1
					)	
FROM #temp1 

SELECT fullName,
	(CASE WHEN 0 = CHARINDEX(' ', fullName) 
		then  fullName 
		ELSE SUBSTRING(fullName, 1, CHARINDEX(' ', fullName)) end) as first_name,  
	(CASE WHEN 0 = CHARINDEX(' ', fullName) 
		THEN ''  
		ELSE SUBSTRING(fullName,CHARINDEX(' ', fullName)+1, LEN(fullName) )end) last_name
FROM #temp1

SELECT RIGHT([ADDRESS],6) FROM #temp1 
------------------------------------------------------
	
DECLARE @dt DATETIME2 = SYSDATETIME();
select @dt 
DECLARE @dt2 DATETIME = SYSDATETIME();
select @dt2 
DECLARE @dt3 smallDATETIME = SYSDATETIME();
select @dt3 
DECLARE @dt4 DATe = SYSDATETIME();
select @dt4 
DECLARE @dt5 Time = SYSDATETIME();
select @dt5 
	
-----------------------

SELECT CONVERT(VARCHAR,GETDATE(),108)--	11:16:42
SELECT CONVERT(VARCHAR,GETDATE(),114) as HHMMSSNS -- 11:20:07:487

SELECT CONVERT(VARCHAR,GETDATE(),120) as YYYYMMDD -- 2018-01-08 11:20:51
SELECT CONVERT(VARCHAR,GETDATE(),121) AS YYYYMMDD --  2018-01-08 11:20:58.300
SELECT CONVERT(VARCHAR(11),DATEADD(dd,1,GETDATE()),121) --2018-01-09 

SELECT CONVERT(VARCHAR,GETDATE(),102) AS YYYYMMDD --  2018.01.08
SELECT CONVERT(VARCHAR,GETDATE(),111) AS YYYYMMDD --  2018/01/08
SELECT REPLACE(CONVERT(VARCHAR(10),GETDATE(),111), '/','-')--2018-01-08 or we can use 121 using varchar(10)
SELECT CONVERT(VARCHAR,GETDATE(),112) AS YYYYMMDD -- 20180108

SELECT CONVERT(VARCHAR,GETDATE(),103) as DDMMYYYY --08/01/2018
select CONVERT(VARCHAR,GETDATE(),104) as DDMMYYYY -- 08.01.2018
SELECT CONVERT(VARCHAR,GETDATE(),105) as DDMMYYYY -- 08-01-2018

select CONVERT(VARCHAR,GETDATE(),101) as MMDDYYYY -- 01/08/2018
SELECT CONVERT(VARCHAR,GETDATE(),110) as MMDDYYYY -- 01-08-2018

SELECT CONVERT(VARCHAR,GETDATE(),106) as DDMMYYYY --08 Jan 2018
select CONVERT(VARCHAR,GETDATE(),107) as MMDDYYYY -- Jan 08, 2018

SELECT CONVERT(VARCHAR,GETDATE(),100) as MMDDYYYY --Jan  8 2018 11:13AM
SELECT CONVERT(VARCHAR,GETDATE(),113) as DDMMYYYY -- 08 Jan 2018 11:17:38:800
SELECT CONVERT(VARCHAR,GETDATE(),109) as MMDDYYYY -- Jan  8 2018 11:17:38:800AM
--************
SELECT (Day(GETDATE())-1)*(-1)  -- Total current month days

SELECT DATEADD(s,-1,GETDATE())--2018-01-08 12:24:31.643
SELECT DATEADD(mm ,-1,GETDATE())--2017-12-08 12:24:32.643
SELECT DATEADD(DAY,-DAY(GETDATE()),GETDATE())-- END DATE OF PREVIOUS MONTH
SELECT DATEADD(DAY,-DAY(GETDATE()-1),GETDATE()) -- START DATE OF CURRENT MONTH

SELECT DATEDIFF(dd,'2016-08-01',GETDATE())--29

SELECT DATEPART(day,GETDATE()) -- 8
or
select month(getdate())
SELECT DATEPART(MM,GETDATE()) -- 1
	
select datename(week,getdate()) -- 39 th week
SELECT DATENAME(WEEKDAY,GETDATE()) -- Monday
SELECT DATENAME(dd,GETDATE()) -- 8
SELECT DATENAME(Mm,GETDATE()) -- January
SELECT DATENAME(M,CAST(DATEADD(M,-1,GETDATE()) AS VARCHAR)) -- December
SELECT LEFT(DATENAME(mm,GetDate()),3) +'-'+ CAST(YEAR(GetDate()) AS VARCHAR) --Jan-2018( cast for int into varchar)

--************
-- 2 nd parameter for total lenth of output
-- 3 rd parameter for to dispaly decimal
select str(67.023453453,15,5)

SELECT ROUND(4,0)
SELECT ROUND(4,1)
SELECT ROUND(24.445,1)
SELECT ROUND(24.455,1)
SELECT ROUND(24.425,2)
SELECT ROUND(324.425,2)
SELECT ROUND(4,-0)
SELECT ROUND(4,-1)
SELECT ROUND(4,-2)
SELECT ROUND(4.0,-1)
SELECT ROUND(24,-1)
SELECT ROUND(24,-2)
SELECT ROUND(24.4,-1)
SELECT ROUND(24.4,-2)
SELECT ROUND(324.4,-2)

-- any thing above 5.0 in minus then it shows error
SELECT ROUND(5,0) -- 5
SELECT ROUND(5,1) -- 5
SELECT ROUND(5,-1)
SELECT ROUND(5,-2)
SELECT ROUND(55,-1)
SELECT ROUND(55,-2)
SELECT ROUND(65,-2)
SELECT ROUND(5.1,0) 
SELECT ROUND(5.1,1) 
SELECT ROUND(5.0,-1)
SELECT ROUND(5.5,0) 
SELECT ROUND(5.5,1) 
SELECT ROUND(5.5,-1)

SELECT ROUND(5.51,0) -- 6.00
SELECT ROUND(5.51,1) -- 5.50

SELECT ROUND(10.0,-1) -- 10.0
SELECT ROUND(11.0,-1) -- 10.0
SELECT ROUND(15.0,-1) -- 20.0

SELECT ROUND(10.0,-2) -- 0.0
SELECT ROUND(49.0,-2) -- 0.0
SELECT ROUND(50.0,-2) -- Arithmetic overflow error converting expression to data type numeric.

SELECT ROUND(10.0,-1) -- 10.0
SELECT ROUND(49.0,-1) -- 50.0
SELECT ROUND(50.0,-1) -- 50.0

SELECT ROUND(65.0,0)
SELECT ROUND(65.0,1)
SELECT ROUND(65.0,-1)
SELECT ROUND(65.0,-2)  -- when does't carry a no to left side(error)
SELECT ROUND(65.15,0)
SELECT ROUND(65.15,1)
SELECT ROUND(45.15,-1)
SELECT ROUND(45.15,-2)
SELECT ROUND(55.15,-2)

SELECT CONVERT(INT,12.036)
	
SELECT RAND(-8)
SELECT RAND(8) -- 0.713778322925506 (it will come same no every time it execute)
SELECT RAND() -- 0.928038620073639(it will come random no every time it execute)

SELECT ABS(-236)  --236

------------ Local table,global table ----------------------------------------------------

-- Local table,global table created in memory
-- local table generate sequence no(12 digit), while golobal table not generate sequence no

------------- ISNULL & NULLIF & COALESCE(ANSI Standard) -------------

SELECT IIF('r'='R','R','A')

SELECT NULLIF(45, 45); NULL	
SELECT NULLIF(40, 45);-- 40
SELECT NULLIF(NULL, 45);-- error(first argument to NULLIF cannot be the NULL constant because the type of the first argument has to be known.)
SELECT NULLIF(NULL, null);-- error(first argument to NULLIF cannot be the NULL constant because the type of the first argument has to be known.)

SELECT ISNULL(NULL, 45);-- 45
SELECT ISNULL(null,null)--null
SELECT ISNULL(12, 45);-- 12
SELECT ISNULL(45, 45); -- 45

SELECT COALESCE(null,null)-- error (At least one of the arguments to COALESCE must be an expression that is not the NULL constant.)
SELECT COALESCE(null,2) --2
SELECT COALESCE(4,2) --4
SELECT COALESCE(2,2) -- 2

2.The data type of the output returned by COALESCE will be the data type with highest precedence,
		whereas data type of the ISNULL output will be the data type of the first input.
4.As far as the performance of the query is concerned, ISNULL is the preferable choice in subqueries

ex: declare @x varchar(3)=null
	declare @y varchar(10) ='1234567890'
	select COALESCE(@x,@y) aS A, COALESCE(@Y,@X) aS A1,ISNULL(@x,@y) aS A2,COALESCE(@Y,@X) aS A3
	--O/P -1234567890	1234567890	123	1234567890

--************ date(th,nd,rd) -----------------------------------------------
SELECT CONVERT(VARCHAR(30),GETDATE(),106)

DECLARE @date varchar(20)
	set @date =  GETDATE()
SELECT CAST(DAY(@date) AS VARCHAR(10)) +
				CASE
					WHEN DAY(@date) % 100 IN (11, 12, 13) THEN 'th'
					WHEN DAY(@date) % 10 = 1 THEN 'st'
					WHEN DAY(@date) % 10 = 2 THEN 'nd'
					WHEN DAY(@date) % 10 = 3 THEN 'rd'
				ELSE 'th' END + 
		SPACE(1) + DATENAME(MONTH, @date) + SPACE(1) + CAST(YEAR(@date) AS VARCHAR(4)) AS Dt

SELECT 5%2
SELECT 5%3
SELECT 5%4
SELECT 5%5
SELECT 5%6
	
SELECT 11%100
SELECT 1%10
SELECT 22%20
SELECT 3%30
SELECT 3%3
		
--************ find out financial year------------------------------------

select IIF(	MONTH(GETDATE()) < 4,
				RIGHT(YEAR(GETDATE())-1,2)+RIGHT(YEAR(GETDATE()),2),
				RIGHT(YEAR(GETDATE()),2)+RIGHT(YEAR(GETDATE())+1,2)
		)
		  
-- Global Variable **************************************	

@@CONNECTIONS
@@MAX_CONNECTIONS
@@CPU_BUSY
@@ERROR  
@@IDENTITY
@@IDLE
@@IO_BUSY
@@LANGID  
@@LANGUAGE
@@MAXCHARLEN
@@PACK_RECEIVED  
@@PACK_SENT
@@PACKET_ERRORS
@@ROWCOUNT  
@@SERVERNAME 
@@SPID
@@TEXTSIZE 
@@TIMETICKS
@@TOTAL_ERRORS
@@TOTAL_READ / @@TOTAL_WRITE
@@TRANCOUNT
@@VERSION  

---cumulative sum -----------------------------------------------

SELECT date,partysize,sum(partysize) over(order by date) as total
FROM Reservations 
WHERE Reservations.Date >= '2022-01-01';

-- MIN , MAX ,SUM ------

WITH cte AS (
    SELECT id, SUM(revenue) AS total_revenue  -- Summing revenue for each id
    FROM your_table  -- Replace with the actual table name
    GROUP BY id     -- Grouping by id to calculate sum for each group
)
SELECT 
    id,
    MIN(total_revenue) AS min_sum,    -- Minimum sum of revenue for each id
    MAX(total_revenue) AS max_sum,    -- Maximum sum of revenue for each id
    COUNT(*) AS count_sum             -- Count of records (rows) for each id
FROM cte
GROUP BY id;

--or
SELECT 
    id,
    SUM(revenue) AS total_revenue,  -- Calculate the sum of revenue per id
    MIN(SUM(revenue)) OVER (PARTITION BY id) AS min_sum,  -- Minimum sum for each id
    MAX(SUM(revenue)) OVER (PARTITION BY id) AS max_sum,  -- Maximum sum for each id
    COUNT(*) OVER (PARTITION BY id) AS count_sum  -- Count of rows for each id
FROM your_table
WHERE Date >= '2022-01-01'
GROUP BY id;

--sum of prices for each order and the previous order's sum.g

SELECT o.orderid,
	sum(d.price) as vvv
	,sum(d.price)- LAG(sum(d.price),1) over(order by o.orderid) as sdfavcc
FROM Orders o
inner join ordersdishes od on o.orderid = od.orderid
inner join dishes d on d.dishid = od.dishid
WHERE OrderDate >= '2022-01-01'
group by o.orderid

------------------------------------------------------------------