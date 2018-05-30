/* ---------------------------------------------------------------------------
  SQL CURSORs are widely used for database administration, but sometimes they 
  are not the best technical option to complete a task. In this example we'll
  first get the most recent order date for a customer using CURSORs and a 
  procedural approach. Then we’ll complete the same task using a set-based 
  approach. 
  ---------------------------------------------------------------------------- */

-- Procedural approach using CURSORs (UPDATE CustCopy1)

USE Northwind
GO

--Create demo tables
If Exists(Select * from Sys.objects where Name = 'CustCopy1')
   Drop TABLE CustCopy1;
go

If Exists(Select * from Sys.objects where Name = 'CustCopy2')
   Drop TABLE CustCopy2;
go

CREATE TABLE [dbo].[CustCopy1](
[CustomerID] [nchar](5) NOT NULL PRIMARY KEY,
[CompanyName] [nvarchar](40) NOT NULL,
[ContactName] [nvarchar](30) NULL,
[ContactTitle] [nvarchar](30) NULL,
[Address] [nvarchar](60) NULL,
[City] [nvarchar](15) NULL,
[Region] [nvarchar](15) NULL,
[PostalCode] [nvarchar](10) NULL,
[Country] [nvarchar](15) NULL,
[Phone] [nvarchar](24) NULL,
[Fax] [nvarchar](24) NULL,
LastOrder datetime NULL,
)

insert into CustCopy1
select *,NULL as LastOrder
from dbo.customers

select * into dbo.CustCopy2
from dbo.CustCopy1

--Declare customer cursor

DECLARE CustomerCur CURSOR
FORWARD_ONLY
KEYSET
FOR
select customerid, lastorder
from custcopy1;

--Declare holding vars

declare @customerid nchar (5);
declare @lastorder datetime;
declare @orderdate datetime

--Get the most recent order date for each customer using CURSORs

OPEN CustomerCur;
FETCH NEXT FROM CustomerCur into @customerid, @lastorder

While @@FETCH_STATUS = 0

BEGIN

DECLARE OrderCur CURSOR

READ_ONLY FOR
select orderdate
from orders
where customerID = @customerid;

OPEN OrderCur
FETCH NEXT FROM OrderCur into @orderdate

--loop through a customer's orders

While @@FETCH_STATUS = 0
BEGIN
	IF (@lastorder is null) or (@orderdate > @lastorder)
	SET @lastorder = @orderdate
FETCH NEXT FROM OrderCur into @orderdate
END

CLOSE OrderCur
DEALLOCATE OrderCur

UPDATE CustCopy1

SET LastOrder = @lastorder
WHERE CURRENT OF CustomerCur;
FETCH NEXT FROM CustomerCur into @customerid, @lastorder

END

CLOSE CustomerCur
DEALLOCATE CustomerCur
GO

SELECT * FROM CustCopy1

-- Procedural approach using SET (UPDATE CustCopy2)
-- Get the most recent order date for each customer using SET Oriented Operation (UPDATE CustCopy2)
-- NOTE: This could also be done using a cursor (for each customerID, SET the LastOrder equal to CustCopy1 LastOrder)

UPDATE CustCopy2
SET LastOrder = (SELECT 
					LastOrder 
				FROM CustCopy1 
				WHERE CustCopy1.CustomerID = CustCopy2.CustomerID
				)

SELECT * FROM CustCopy2
