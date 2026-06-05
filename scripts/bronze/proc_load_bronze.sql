/*
================================================================================
Stored Procedure: Load Bronze Layer (Source -> Bronze)
================================================================================
Script Purpose:
    This stored procedure loads data into the 'Bronze' schema from external CSV files.
    It performs the following actions:
    - Truncates the bronze tables before loading data.
    - Uses the `COPY` command to load data from csv Files to bronze tables.

Parameters:
    None.
    This stored procedure does not accept any parameters or return any values.

Usage Example:
    CALL bronze.load_bronze;
================================================================================
*/


create or replace procedure bronze.load_bronze()
language plpgsql
as $$
declare
	start_time timestamp;
	end_time timestamp;
	batch_start_time timestamp;
	batch_end_time timestamp;
begin
	batch_start_time := clock_timestamp();
	raise notice '=========================';
	raise notice 'Loading Bronze Layer';
	raise notice '=========================';

	raise notice '=========================';
	raise notice 'Loading CRM Tables';
	raise notice '=========================';

	start_time := clock_timestamp();
	raise notice '>> Truncating table: crm_cust_info';
	truncate table bronze.crm_cust_info;
	raise notice '>> Inserting into table: crm_cust_info';
	copy bronze.crm_cust_info
	from '/Users/ankitgari/SQL/sql-data-warehouse-project/datasets/source_crm/cust_info.csv'
	delimiter ','
	csv header;
	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';


	start_time := clock_timestamp();
	raise notice '>> Truncating table: crm_prd_info';
	truncate table bronze.crm_prd_info;
	raise notice '>> Inserting into table: crm_prd_info';
	copy bronze.crm_prd_info
	from '/Users/ankitgari/SQL/sql-data-warehouse-project/datasets/source_crm/prd_info.csv'
	delimiter ','
	csv header;
	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';
	

	start_time := clock_timestamp();
	raise notice '>> Truncating table: crm_sales_details';
	truncate table bronze.crm_sales_details;
	raise notice '>> Inserting into table: crm_sales_details';
	copy bronze.crm_sales_details
	from '/Users/ankitgari/SQL/sql-data-warehouse-project/datasets/source_crm/sales_details.csv'
	delimiter ','
	csv header;
	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';

	
	raise notice '=========================';
	raise notice 'Loading ERP Tables';
	raise notice '=========================';


	start_time := clock_timestamp();
	raise notice '>> Truncating table: erp_cust_az12';
	truncate table bronze.erp_cust_az12;
	raise notice '>> Inserting into table: erp_cust_az12';
	copy bronze.erp_cust_az12
	from '/Users/ankitgari/SQL/sql-data-warehouse-project/datasets/source_erp/CUST_AZ12.csv'
	delimiter ','
	csv header;
	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';
	

	start_time := clock_timestamp();
	raise notice '>> Truncating table: erp_loc_a101';
	truncate table bronze.erp_loc_a101;
	raise notice '>> Inserting into table: erp_loc_a101';
	copy bronze.erp_loc_a101
	from '/Users/ankitgari/SQL/sql-data-warehouse-project/datasets/source_erp/loc_a101.csv'
	delimiter ','
	csv header;
	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';

	
	start_time := clock_timestamp();
	raise notice '>> Truncating table: erp_px_cat_g1v2';
	truncate table bronze.erp_px_cat_g1v2;
	raise notice '>> Inserting into table: erp_px_cat_g1v2';
	copy bronze.erp_px_cat_g1v2
	from '/Users/ankitgari/SQL/sql-data-warehouse-project/datasets/source_erp/px_cat_g1v2.csv'
	delimiter ',' 
	csv header;
	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';

	batch_end_time := clock_timestamp();

	raise notice '=========================';
	raise notice 'Loading Bronze Layer Completed';
	raise notice '>> Batch Duration: % seconds', round(extract(epoch from(batch_end_time - batch_start_time)),2);
	raise notice '=========================';
	
	exception
		when others then
			raise notice '========================================';
			raise notice 'Error Occured while loading Bronze Layer';
			raise notice '========================================';
			raise notice 'Error: %', SQLERRM;

	
end;
$$;
