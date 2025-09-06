/*
===============================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
===============================================================================
Script Purpose:
    This stored procedure loads data into the 'bronze' schema from external CSV files. 
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `BULK INSERT` command to load data from csv Files to bronze tables.

Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC bronze.load_bronze;
===============================================================================
*/
CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	BEGIN TRY
	
		
		PRINT '================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		PRINT '>> Truncating Table: bronze.crm_cust_info';
		TRUNCATE TABLE bronze.crm_cust_info;
		PRINT '>> Inserting Data Into: bronze.crm_cust_info';  --empty the table--
		BULK INSERT bronze.crm_cust_info
		FROM 'C:\sim_project\SQL Data WareHouse Project\datasets\source_crm\cust_info.csv'
		WITH  ( 
			FIRSTROW=2,
			FIELDTERMINATOR = ',',
			TABLOCK
		);
		PRINT '>> -------------';

		--SELECT* FROM bronze.crm_cust_info
		--SElECT COUNT(*) FROM bronze.crm_cust_info



		PRINT '>> Truncating Table: bronze.crm_pred_info';
		TRUNCATE TABLE bronze.crm_pred_info;
		PRINT '>> Inserting Data Into: bronze.crm_pred_info';
		BULK INSERT bronze.crm_pred_info
		FROM 'C:\sim_project\SQL Data WareHouse Project\datasets\source_crm\prd_info.csv'
		WITH(
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		PRINT '>> -------------';
		--SELECT* FROM bronze.crm_pred_info
		--SELECT COUNT(*) FROM bronze.crm_pred_info


		PRINT '>> Truncating Table: bronze.crm_sales_details';
		TRUNCATE TABLE bronze.crm_sales_details;
		PRINT '>> Inserting Data Into: bronze.crm_sales_details';
		BULK INSERT bronze.crm_sales_details
		FROM 'C:\sim_project\SQL Data WareHouse Project\datasets\source_crm\sales_details.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		PRINT '>> -------------';
		--SELECT*FROM bronze.crm_sales_details
		--SELECT COUNT(*) FROM bronze.crm_sales_details

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';
		PRINT '>> Truncating Table: bronze.erp_cust_AZ12';
		TRUNCATE TABLE bronze.erp_cust_AZ12;
		PRINT '>> Inserting Data Into: bronze.erp_cust_AZ12';
		BULK INSERT bronze.erp_cust_AZ12
		FROM 'C:\sim_project\SQL Data WareHouse Project\datasets\source_erp\CUST_AZ12.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		PRINT '>> -------------';
		--SELECT*FROM bronze.erp_cust_AZ12
		--SELECT COUNT(*) FROM bronze.erp_cust_AZ12


		PRINT '>> Truncating Table: bronze.erp_loc_A101';
		TRUNCATE TABLE bronze.erp_loc_A101;
		PRINT '>> Inserting Data Into: bronze.erp_loc_A101';
		BULK INSERT bronze.erp_loc_A101
		FROM 'C:\sim_project\SQL Data WareHouse Project\datasets\source_erp\LOC_A101.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
		TABLOCK
		);
		PRINT '>> -------------';
		--SELECT*FROM bronze.erp_loc_A101
		--SELECT COUNT(*) FROM bronze.erp_loc_A101

	
		PRINT '>> Truncating Table: bronze.erp_px_cat_GV2';
		TRUNCATE TABLE bronze.erp_px_cat_G1V2;
		PRINT '>> Inserting Data Into: bronze.erp_px_cat_G1V2';
		BULK INSERT bronze.erp_px_cat_G1V2
		FROM 'C:\sim_project\SQL Data WareHouse Project\datasets\source_erp\PX_CAT_G1V2.csv'
		WITH (
			FIRSTROW=2,
			FIELDTERMINATOR=',',
			TABLOCK
		);
		PRINT '>> -------------';
		--SELECT*FROM bronze.erp_px_cat_G1V2
		--SELECT COUNT(*) FROM bronze.erp_px_cat_G1V2

	END TRY
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING BRONZE LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
	
END


EXEC bronze.load_bronze
