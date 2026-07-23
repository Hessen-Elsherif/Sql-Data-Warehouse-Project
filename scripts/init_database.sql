/*
script purpose:
      this script creates a newdatabase named 'datawarehouse' after checking if it already exists,
      if the database exists , it is dropped and recreated. additionally, the script sets up three schemas within
      the database: 'bronze' , 'silver' , and 'gold' 

WARNING:
      running this script will drop the entire 'datawarehouse' database if it exists.
      all data in the database will be permanently deleted. proceed with caution 
      and ensure you have proper backups before running this script.

-- create database 'datawarehouse'
*/

USE master;
go

-- Drop and recreate the ' Datawarehouse ' database
If EXISTS (select 1 from sys.databases where name = 'datawarehouse')
BEGIN
	alter DATABASE datawarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE datawarehouse;
end;
GO


CREATE DATABASE datawarehouse;

use datawarehouse;

CREATE SCHEMA bronze;
GO
create Schema silver;
GO
Create schema gold;
GO
