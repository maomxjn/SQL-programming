
--1--Create a database
Create database [db_MINGXIANG];
go


--2--Create Customer table
use [db_MINGXIANG]
go
drop table if exists [dbo].[Customer]
go
create table  [dbo].[Customer] (
ID INT identity NOT NULL,
CustomerID INT NOT NULL Primary Key,
FirstName Nvarchar(50 ) NOT NULL,
LastName Nvarchar(50) NOT NULL)
go


--3--Create Orders table
drop table if exists [dbo].[Orders]
go
create table [dbo].[Orders](
OrderID INT Not NULL identity,
CustomerID INT NOT NULL,
OrderDate datetime Not NULL)
go

insert into  [dbo].[Customer] values (1,'F1','L1')
insert into  [dbo].[Customer] values(2,'F2','L2')
insert into  [dbo].[Customer] values (3,'F3','L3')
insert into  [dbo].[Customer] values(4,'F4','L4')

insert into  [dbo].[Orders] values(1,'2023-06-01')
insert into  [dbo].[Orders] values(2,'2023-07-01')
go

select * from [dbo].[Customer]
select * from [dbo].[Orders]



--4(a-b£© Use triggers---A Customer with Orders cannot be deleted from Customer tablesp_addmessage @msgnum=50001, @severity=16, @msgtext=N'Cannot delete a customer with orders!',@lang='us_english',@replace='replace'
drop trigger if exists TRa
go
create trigger TRa on [dbo].[Customer]
instead of delete
as
begin
	SET NOCOUNT ON;
	if exists (select 1 from [dbo].[Orders] O inner join deleted D on O.CustomerID=D.CustomerID)
	begin
		Raiserror (50001,-1,-1,'TRa')
	end
	else
		delete from [dbo].[Customer] where CustomerID in (select CustomerID from deleted);
end
go

--test4(a-b) data

select * from [dbo].[Customer]
select * from [dbo].[Orders]
go
delete from  [dbo].[Customer] where customerID='1'
go
select * from [dbo].[Customer]


--4(c) Use triggers--- Orders'CustomerID  must be updated accordingly
drop trigger if exists TRc
go
create trigger TRc on [dbo].[Customer]
after update
as
begin
SET NOCOUNT ON;
	update [dbo].[Orders]    set [dbo].[Orders].CustomerID=(select CustomerID from inserted)
	where [dbo].[Orders].CustomerID in (select CustomerID from deleted)
end
go


--test4(c) data

select * from [dbo].[Customer]
go
update  [dbo].[Customer] set CustomerID='9' where CustomerID='1'
go
select * from [dbo].[Customer]
go
select * from [dbo].[Orders]
go



--4(d) Use triggers

exec sp_addmessage @msgnum=50002,@severity=16,@msgtext='CustomerID must exists in Customer table!!',@lang='us_english',@replace=replace
go

drop trigger if exists TRd
go
create trigger TRd on [dbo].[Orders]
instead of insert,update
as
begin
SET NOCOUNT ON;
	if  not exists (select 1 from [dbo].[Customer] C  inner join inserted  I on C.CustomerID=I.CustomerID)
			RAISERROR(50002,-1,-1)		
	ELSE
	begin
		insert into [dbo].[Orders] select  CustomerID,OrderDate from inserted
		
	end	
END
go

--test4(d) data
select * from [dbo].[Customer]
go
insert into [dbo].[Orders] values('90','2023-10-21')
go
select * from [dbo].[Orders]
select * from [dbo].[Customer]
go


insert into [dbo].[Orders] values('9','2023-10-21')
go
select * from [dbo].[Orders]
go



update [dbo].[Orders] set orderDate='2023-10-21' where CustomerId='900'
go
select * from [dbo].[Orders]



update [dbo].[Orders] set orderDate='2023-09-01' where CustomerId='9'
go
select * from [dbo].[Orders]
go


--5--Create a scalar function
drop function if exists dbo.fn_CheckName
go
create function dbo.fn_CheckName
(
		 @FirstName varchar(50),
		 @LastName varchar(50)
)
returns int
with SchemaBinding
as
begin
	declare @result int
	if @FirstName = @LastName 
	set @result = 1
	else 
	set @result = 0
	return( @result)
end
go




--6-- Create a stored procedure

exec sp_addmessage @msgnum='50003',@severity='16',@msgtext='FirstName is identical with LastName!Please check again.',@lang='us_english',@replace=replace
go


drop procedure if exists sp_InsertCustomer
go

create procedure sp_InsertCustomer 
@CustomerID int=0,
@FirstName varchar(50),
@LastName varchar(50)
as
begin
	set nocount on
	if @CustomerID = 0 
			set @CustomerID =(select max([CustomerID])+1 from [dbo].[Customer])
	if db_MINGXIANG.dbo.fn_CheckName(@FirstName,@LastName)=0
			begin			
			insert into Customer values(@CustomerID,@FirstName,@LastName)
			end
			else
		raiserror(50003,-1,-1)

end


--test5-6 data

	exec sp_InsertCustomer @FirstName='F5' ,@LastName='L5'
	go
    select * from Customer
	go

	exec sp_InsertCustomer @FirstName='F6' ,@LastName='F6'
	go
    select * from Customer
	go

	exec sp_InsertCustomer @FirstName='F6' ,@LastName='L6',@CustomerID='100'
	go
    select * from Customer
	go


	--7--create log

	drop table if exists [dbo].[CusAudit]
	Create table [dbo].[CusAudit](
	ID int identity,
	CustomerID int not null,
	Old_FirstName varchar(50) not null,
	Old_LastName varchar(50) not null,
	New_FirstName varchar(50) not null,
	New_LastName varchar(50) not null,
	OP_date datetime ,
	OP_time datetime ,
	OP_person varchar(50) 
	)

	drop trigger if exists TR7 
	go
create trigger TR7 on [dbo].[Customer]
after update
as
BEGIN
	SET NOCOUNT ON;
  insert into [dbo].[CusAudit] 
  select deleted.CustomerID,deleted.FirstName,deleted.LastName,inserted.FirstName,inserted.LastName,convert(date,getdate()),current_timestamp,system_user
   from deleted inner join inserted on deleted.CustomerID=inserted.CustomerID
end
go

--test7 data

update [dbo].[Customer] set FirstName='Mingg',lastName='Mao' where CustomerID ='9'
go
select * from CusAudit
go
select * from Customer
go