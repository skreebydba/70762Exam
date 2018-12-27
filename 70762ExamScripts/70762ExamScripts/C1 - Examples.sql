USE master;

CREATE DATABASE ExamBook762Ch1;
GO

USE ExamBook762Ch1;
GO
CREATE SCHEMA Examples;

CREATE TABLE Examples.Widget
(WidgetCode VARCHAR(10) NOT NULL CONSTRAINT PKWidget PRIMARY KEY
,WidgetName VARCHAR(100) NULL);

DROP TABLE IF EXISTS Examples.ComputedColumn;

CREATE TABLE Examples.ComputedColumn
(FirstName NVARCHAR(50) NULL
,LastName NVARCHAR(50) NOT NULL
,FullName AS CONCAT(LastName, ',' + FirstName) PERSISTED);

INSERT INTO Examples.ComputedColumn
(FirstName
,LastName)
VALUES
(NULL, N'Harris'),
(N'Waleed', N'Heloo');

SELECT * FROM Examples.ComputedColumn;

CREATE TABLE Examples.DataMasking
(FirstName NVARCHAR(50) NULL
,LastName NVARCHAR(50) NOT NULL
,PersonNumber CHAR(10) NOT NULL
,[Status] VARCHAR(10)
,EmailAddress NVARCHAR(50) NULL
,BirthDate DATE NOT NULL
,CarCount TINYINT NOT NULL);

INSERT INTO Examples.DataMasking
(FirstName
,LastName
,PersonNumber
,[Status]
,EmailAddress
,BirthDate
,CarCount)
VALUES
(N'Jay'
,N'Hamlin'
,'0000000014'
,'Active'
,N'jay@litwareinc.com'
,'1979-01-12'
,0);

CREATE USER MaskedView WITHOUT LOGIN;
GRANT SELECT ON Examples.DataMasking TO MaskedView;

ALTER TABLE Examples.DataMasking
ALTER COLUMN FirstName
ADD MASKED WITH (FUNCTION = 'default()');
ALTER TABLE Examples.DataMasking
ALTER COLUMN BirthDate
ADD MASKED WITH (FUNCTION = 'default()');

SELECT * FROM Examples.DataMasking;

ALTER TABLE Examples.DataMasking
ALTER COLUMN EmailAddress
ADD MASKED WITH (FUNCTION = 'email()');

ALTER TABLE Examples.DataMasking
ALTER COLUMN PersonNumber
ADD MASKED WITH (FUNCTION = 'partial(2,"*******",1)');

ALTER TABLE Examples.DataMasking
ALTER COLUMN LastName
ADD MASKED WITH (FUNCTION = 'partial(3,"_____",2)');

ALTER TABLE Examples.DataMasking
ALTER COLUMN [Status]
ADD MASKED WITH (FUNCTION = 'partial(0,"Unknown",0)');

ALTER TABLE Examples.DataMasking
ALTER COLUMN CarCount
ADD MASKED WITH (FUNCTION = 'random(1,3)');

EXECUTE AS USER = 'MaskedView';
SELECT * FROM Examples.DataMasking;

REVERT;

SELECT SUSER_SNAME(), USER_NAME();

SELECT * FROM Examples.DataMasking;

CREATE TABLE Examples.UniquenessConstraint
(PrimaryUniqueValue INT NOT NULL
,AlternateUniqueValue1 INT NULL
,AlternateUniqueValue2 INT NULL);

ALTER TABLE Examples.UniquenessConstraint
ADD CONSTRAINT PKUniquenessConstraint PRIMARY KEY(PrimaryUniqueValue);

ALTER TABLE Examples.UniquenessConstraint
ADD CONSTRAINT AKUniquenessConstraint UNIQUE (AlternateUniqueValue1, AlternateUniqueValue2);

SELECT name
,type_desc, 
is_primary_key,
is_unique,
is_unique_constraint
FROM sys.indexes
WHERE OBJECT_ID('Examples.UniquenessConstraint') = object_id;

USE WideWorldImporters;

SELECT PaymentMethodId, COUNT(*) AS NumRows
FROM Sales.CustomerTransactions
GROUP BY PaymentMethodID;

SELECT *
FROM sales.CustomerTransactions
WHERE PaymentMethodID = 4;

SET STATISTICS TIME ON;
SET STATISTICS IO ON;

SELECT CustomerID,
OrderID,
OrderDate,
ExpectedDeliveryDate
FROM Sales.Orders
WHERE CustomerPurchaseOrderNumber = '16374';

CREATE INDEX CustomerPurchaseOrderNumber
ON Sales.Orders(CustomerPurchaseOrderNumber);

SELECT name
,type_desc, 
is_primary_key,
is_unique,
is_unique_constraint
FROM sys.indexes
WHERE OBJECT_ID('Sales.Orders') = object_id;

SELECT CONCAT(OBJECT_SCHEMA_NAME(object_id), '.', OBJECT_NAME(object_id)) AS TableName,
[name] AS ColumnName,
COLUMNPROPERTY(object_id, name, 'IsIndexTable') AS Indexable
FROM sys.columns
WHERE is_computed = 1;

DROP INDEX FK_Sales_Orders_ContactPersonId
ON Sales.Orders;

SELECT OrderID,
OrderDate,
ExpectedDeliveryDate,
People.FullName
FROM Sales.Orders
INNER JOIN [Application].People
ON People.PersonID = Orders.ContactPersonID
WHERE People.PreferredName = 'Aakriti';

CREATE INDEX PreferredName
ON Application.People(PreferredName)
ON USERDATA;

SELECT SalespersonPersonID,
OrderDate
FROM Sales.Orders
ORDER BY SalespersonPersonID ASC, OrderDate ASC;

CREATE INDEX SalespersonPersonID_OrderDate
ON Sales.Orders(SalespersonPersonID ASC, OrderDate ASC);

SELECT SalespersonPersonID,
OrderDate
FROM Sales.Orders
ORDER BY SalespersonPersonID DESC, OrderDate ASC;

SELECT Orders.ContactPersonID, People.PersonID
FROM Sales.Orders
INNER JOIN Application.People
ON Orders.ContactPersonID = People.PersonID;

SELECT OrderID,
OrderDate,
ExpectedDeliveryDate,
People.FullName
FROM Sales.Orders
INNER JOIN [Application].People
ON People.PersonID = Orders.ContactPersonID
WHERE People.PreferredName = 'Aakriti';

CREATE NONCLUSTERED INDEX ContactPersonID_Include_OrderDate_ExpectedDeliveryDate
ON Sales.Orders(ContactPersonId)
INCLUDE(OrderDate, ExpectedDeliveryDate)
ON USERDATA;

DROP INDEX PreferredName
ON Application.People;

CREATE NONCLUSTERED INDEX PreferredName_Include_FullName
ON Application.People(PreferredName)
INCLUDE(FullName)
ON USERDATA;

SELECT *
FROM sales.CustomerTransactions
WHERE PaymentMethodID = 4;

SELECT OrderDate, ExpectedDeliveryDate
FROM Sales.Orders
WHERE OrderDate = '2015-01-01';

CREATE SCHEMA Examples AUTHORIZATION dbo;

SELECT * 
INTO Examples.PurchaseOrders
FROM WideWorldImporters.Purchasing.PurchaseOrders;

ALTER TABLE Examples.PurchaseOrders
ADD CONSTRAINT PKPurchaseOrders PRIMARY KEY(PurchaseOrderId);

SELECT * 
INTO Examples.PurchaseOrderLines
FROM WideWorldImporters.Purchasing.PurchaseOrderLines;

ALTER TABLE Examples.PurchaseOrderLines
ADD CONSTRAINT PKPurchaseOrderLines_Ref_Examples_PurchaseOrderLines
FOREIGN KEY(PurchaseOrderId)
REFERENCES Examples.PurchaseOrders(PurchaseOrderID);

SELECT * 
FROM Examples.PurchaseOrders
WHERE PurchaseOrders.OrderDate BETWEEN '2016-03-10' AND '2016-03-14';

SELECT PurchaseOrderId, ExpectedDeliveryDate
FROM Examples.PurchaseOrders
WHERE EXISTS(SELECT *
FROM Examples.PurchaseOrderLines
WHERE PurchaseOrderLines.PurchaseOrderID = PurchaseOrders.PurchaseOrderID)
AND PurchaseOrders.OrderDate BETWEEN '2016-03-10' AND '2016-03-14';

CREATE INDEX OrderDate ON Examples.PurchaseOrders(OrderDate);

CREATE INDEX OrderDate_Include_ExpectedDeliveryDate
ON Examples.PurchaseOrders(OrderDate)
INCLUDE (ExpectedDeliveryDate);
GO
--Skill 1.3

DROP VIEW IF EXISTS Sales.Orders12MonthsMultipleItems;
GO

CREATE VIEW Sales.Orders12MonthsMultipleItems
AS
SELECT OrderID, 
CustomerID, 
SalespersonPersonID,
OrderDate,
ExpectedDeliveryDate
FROM Sales.Orders
WHERE OrderDate >= DATEADD(MONTH,-36,SYSDATETIME())
AND (SELECT COUNT(*)
	FROM Sales.OrderLines
	WHERE OrderLines.OrderID = Orders.OrderID) > 1;

SELECT TOP 5 *
FROM Sales.Orders12MonthsMultipleItems
ORDER BY ExpectedDeliveryDate DESC;

SELECT PersonID, IsPermittedToLogon, IsEmployee, IsSalesperson
FROM Application.People;
GO

CREATE VIEW [Application].PeopleEmployeeStatus
AS
SELECT PersonId, 
FullName,
IsEmployee,
IsSalesPerson,
CASE 
	WHEN IsPermittedToLogon = 1 THEN 'Can logon'
	ELSE 'Can''t logon'
END AS LogonRights,
CASE 
	WHEN IsEmployee = 1 AND IsSalesPerson = 1 THEN 'Salesperson'
	WHEN IsEmployee = 1  THEN 'Employee'
	ELSE 'Not employee'
END AS EmployeeType
FROM [Application].People;

SELECT PersonID, FullName, LogonRights, EmployeeType
FROM [Application].PeopleEmployeeStatus;

