/*
===============================================================================
Stored Procedure: Load Silver Layer (Bronze -> Silver)
===============================================================================
Script Purpose:
    This stored procedure performs the ETL (Extract, Transform, Load) process to 
    populate the 'silver' schema tables from the 'bronze' schema.
	Actions Performed:
		- Truncates Silver tables.
		- Inserts transformed and cleansed data from Bronze into Silver tables.
		
Parameters:
    None. 
	  This stored procedure does not accept any parameters or return any values.

Usage Example:
    EXEC Silver.load_silver;
===============================================================================
*/


CREATE OR ALTER PROCEDURE silver.load_silver AS

BEGIN
	BEGIN TRY 
		
		
		PRINT '================================================';
		PRINT 'Loading Bronze Layer';
		PRINT '================================================';

		PRINT '------------------------------------------------';
		PRINT 'Loading CRM Tables';
		PRINT '------------------------------------------------';

		-------  crm table 1--------

		PRINT '>> Truncating table: silver.crm_cust_info';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting data into : slver.crm_cust_info';

		INSERT INTO silver.crm_cust_info(
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_material_status,
			cst_gndr,
			cst_create_date)
		-- Removing nulls and duplicates from the primary key
		-- Removing unwanted spaces 

		SELECT 
		cst_id,
		cst_key,
		-- removing unnecessary spaces to esure data consistency, and uniformity across all records.
		TRIM(cst_firstname) AS cst_firstname,
		TRIM(cst_lastname)AS cst_lastname,
		-- data normalization and standardization (normalize value to readable format)
		CASE WHEN UPPER (TRIM(cst_material_status)) ='S' then 'Single'
			 WHEN UPPER (TRIM(cst_material_status))='M' then 'Married'
			 ELSE 'n/a'
		END cst_material_status,
		CASE WHEN UPPER (TRIM(cst_gndr)) ='F' then 'Female'
			 WHEN UPPER (TRIM(cst_gndr))='M' then 'Male'
			 ELSE 'n/a'
		END cst_gndr,
		cst_create_date
		--removing duplicates
		FROM (
		SELECT 
		* , ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) as flag_last
		from bronze.crm_cust_info
		WHERE cst_id IS NOT NULL 
		)t WHERE flag_last =1  -- data filtering



		--------- crm table 2 ---------

		PRINT '>> Truncating table: silver.crm_pred_info';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting data into : slver.crm_pred_info';

		INSERT INTO silver.crm_pred_info ( 
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
		)
		SELECT
		prd_id,
		REPLACE(SUBSTRING(prd_key, 1,5),'-','_') AS cat_id,  -- extra category id
		SUBSTRING(prd_key,7, LEN(prd_key)) AS prd_key,       -- extra product key
		prd_nm,
		ISNULL(prd_cost,0) AS prd_cost,     ----null to 0
		CASE WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
			 WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
			 WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
			 WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
			 ELSE 'n/a'
		END AS prd_line,  ------map product line codes to discriptive values 
		CAST (prd_start_dt AS DATE ) AS prd_start_dt,
		CAST(LEAD(prd_start_dt) OVER (PARTITION BY prd_key ORDER BY prd_start_dt)-1 AS DATE) prd_end_dt      ----calculate end date as one day before the next start date
		FROM bronze.crm_pred_info

		--WHERE REPLACE(SUBSTRING(prd_key, 1,5),'-','_') NOT IN
		--(SELECT DISTINCT id from bronze.erp_px_cat_G1V2)

		--WHERE SUBSTRING(prd_key,7, LEN(prd_key)) IN
		--(SELECT sla_prd_key from bronze.crm_sales_details )



		--------- crm table 3 ---------

		PRINT '>> Truncating table: silver.crm_sales_details';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting data into : slver.crm_sales_details';

		INSERT INTO silver.crm_sales_details(
		sls_ord_num,
		sla_prd_key,
		sls_clust_id,
		sls_order_dt,sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
		)
		SELECT
		sls_ord_num,
		sla_prd_key,
		sls_clust_id,
		CASE WHEN sls_order_dt = 0 OR LEN(sls_order_dt)!=8 THEN NULL
			ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE)
		END sls_order_dt,
		CASE WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt)!=8 THEN NULL
			ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE)
		END sls_ship_dt,
		CASE WHEN sls_due_dt = 0 OR LEN(sls_due_dt)!=8 THEN NULL
			ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE)
		END sls_due_dt,
		CASE WHEN sls_sales IS NULL OR sls_sales <=0 OR sls_sales!= sls_quantity*ABS(sls_price)
				THEN sls_quantity*ABS(sls_price)
			ELSE sls_sales   ---recalculate sales if original value is missing or incorrect
		END as sls_sales,
		sls_quantity,
		CASE WHEN sls_price IS NULL OR sls_price <=0 
				THEN sls_sales / NULLIF(sls_quantity,0)
			ELSE sls_price   ---derive price if original value is invalid
		END as sls_price
		from bronze.crm_sales_details
		where sls_clust_id NOT IN (SELECT cst_id from silver.crm_cust_info)

		PRINT '------------------------------------------------';
		PRINT 'Loading ERP Tables';
		PRINT '------------------------------------------------';

		--------erp table 1---------------

		PRINT '>> Truncating table: silver.erp_cust_az12';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting data into : slver.erp_cust_az12';

		INSERT INTO silver.erp_cust_az12(cid,bdate,gen)
		SELECT 
		CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid,4,LEN(cid))
			 ELSE cid
		END AS cid,
		CASE WHEN bdate > GETDATE() THEN NULL
			ELSE bdate
		END AS bdate,
		CASE WHEN UPPER(TRIM(gen)) IN ('F','FEMALE') THEN 'Female'
			 WHEN UPPER(TRIM(gen)) IN ('M','MALE') THEN 'Male'
			 ELSE 'n/a'
		END AS gen
		FROM bronze.erp_cust_AZ12



		--------- erp table 2 ----------

		PRINT '>> Truncating table: silver.erp_loc_A101';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting data into : slver.erp_loc_A101';

		insert into silver.erp_loc_A101
		(cid,cntry)
		select replace(cid,'-','') cid,
		case when trim(cntry)= 'DE' then 'Germany'
			 when trim(cntry) in ('US','USA') then 'United States'
			 when trim(cntry)= '' or cntry is null then 'n/a'
			 else trim (cntry)
		end as cntry
		from bronze.erp_loc_A101



		--------- erp table 3 ----------

		PRINT '>> Truncating table: silver.erp_px_cat_G1V2';
		TRUNCATE TABLE silver.crm_cust_info
		PRINT '>> Inserting data into : slver.erp_px_cat_G1V2';

		insert into silver.erp_px_cat_G1V2
		(id,
		cat,
		subcat,
		maintenance)

		Select 
		id,
		cat,
		subcat,
		maintenance
		from bronze.erp_px_cat_G1V2
	END TRY 
	BEGIN CATCH
		PRINT '=========================================='
		PRINT 'ERROR OCCURED DURING LOADING SILVER LAYER'
		PRINT 'Error Message' + ERROR_MESSAGE();
		PRINT 'Error Message' + CAST (ERROR_NUMBER() AS NVARCHAR);
		PRINT 'Error Message' + CAST (ERROR_STATE() AS NVARCHAR);
		PRINT '=========================================='
	END CATCH
	
END


EXECUTE silver.load_silver
