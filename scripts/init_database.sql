/*

====================================================
Create Database and Schemas
==================================================== 

Script Purpose:
  This script creates a new database named "DataWarehouse" after checking if it already exists.
  If the database exists it is dropped and recreated. Additionally, the script set up three schemas 
  within the database: "bronze", "Silver", "gold".

WARNING:
  Running this script will drop the entire "DataWarehouse" database if it exists.
  All data in the database will be permanently deleted.Proceed with caution
  and ensure you have proper backups before running this script.

*/
    
use master;
Go

--Drop and recreate the "DataWarehouse" database
if exists(select 1 from sys.databases where name="DataWarehouse")
Begin
  Alter DATABASE dataWarehouse set single_user with rollback immediate;
  drop DATABASE DataWarehouse;
end;
GO

-- Create database "DataWarehouse"--
create database DataWarehouse;

use DataWarehouse;

--Create Schemas
GO
create schema bronze;
GO
create schema silver;
GO 
create schema gold;
GO
