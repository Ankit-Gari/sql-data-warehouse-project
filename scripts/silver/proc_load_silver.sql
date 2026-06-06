create or replace procedure silver.load_silver()
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
	raise notice 'Loading Silver Layer';
	raise notice '=========================';

	raise notice '=========================';
	raise notice 'Loading CRM Tables';
	raise notice '=========================';

	start_time := clock_timestamp();
	
	RAISE NOTICE 'TRUNCATING TABLE silver.crm_cust_info';
	TRUNCATE TABLE silver.crm_cust_info;
	RAISE NOTICE 'INSERTING INTO TABLE silver.crm_cust_info';
	insert into silver.crm_cust_info(
		cst_id,
		cst_key,
		cst_firstname,
		cst_lastname,
		cst_marital_status,
		cst_gndr,
		cst_create_date
	)
	select
		cst_id,
		cst_key,
		trim(cst_firstname) cst_firstname,
		trim(cst_lastname) cst_lastname,
	
		case when upper(trim(cst_marital_status)) = 'M' then 'Married'
			when upper(trim(cst_marital_status)) = 'S' then 'Single'
			else 'n/a'
		end cst_marital_status,
		
		case when upper(trim(cst_gndr)) = 'M' then 'Male'
			when upper(trim(cst_gndr)) = 'F' then 'Female'
			else 'n/a'
		end cst_gndr,
		
		cst_create_date
	from(
		select
		*,
		row_number() over(partition by cst_id order by cst_create_date desc) flag
		from bronze.crm_cust_info
		where cst_id is not null
	)t where flag = 1;

	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';
	

	
	start_time := clock_timestamp();
	
	RAISE NOTICE 'TRUNCATING TABLE silver.crm_prd_info';
	TRUNCATE TABLE silver.crm_prd_info;
	RAISE NOTICE 'INSERTING INTO TABLE silver.crm_prd_info';
	insert into silver.crm_prd_info(
		prd_id,
		cat_id,
		prd_key,
		prd_nm,
		prd_cost,
		prd_line,
		prd_start_dt,
		prd_end_dt
	)
	select
		prd_id,
		replace(substring(prd_key, 1, 5), '-', '_') as cat_id, --column to join with erp_px_cat_g1v2
		substring(prd_key, 7, length(prd_key)) as prd_key, --columns to join with crm_sales_details
		prd_nm,
		COALESCE(prd_cost, 0) as prd_cost,
	
		case upper(trim(prd_line))
			when 'M' then 'Mountain'
			when 'R' then 'Road'
			when 'S' then 'Other Sales'
			when 'T' then 'Touring'
			else 'n/a'
		end prd_line,
		
		prd_start_dt,
		lead(prd_start_dt) over(partition by prd_key order by prd_start_dt)-1 as prd_end_dt
	from bronze.crm_prd_info;

	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';
	


	start_time := clock_timestamp();
	
	RAISE NOTICE 'TRUNCATING TABLE silver.crm_sales_details';
	TRUNCATE TABLE silver.crm_sales_details;
	RAISE NOTICE 'INSERTING INTO TABLE silver.crm_sales_details';
	insert into silver.crm_sales_details(
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		sls_order_dt,
		sls_ship_dt,
		sls_due_dt,
		sls_sales,
		sls_quantity,
		sls_price
	)
	select
		sls_ord_num,
		sls_prd_key,
		sls_cust_id,
		
		case when sls_order_dt = 0 or length(sls_order_dt::text) != 8 then NULL
			else cast(cast(sls_order_dt as varchar) as date)
		end as sls_order_dt,
	
		case when sls_ship_dt = 0 or length(sls_ship_dt::text) != 8 then NULL
			else cast(cast(sls_ship_dt as varchar) as date)
		end as sls_ship_dt,
	
		case when sls_due_dt = 0 or length(sls_due_dt::text) != 8 then NULL
			else cast(cast(sls_due_dt as varchar) as date)
		end as sls_due_dt,
		
		case when sls_sales is null or sls_sales<=0 or sls_sales != sls_quantity * ABS(sls_price)
				then sls_quantity * ABS(sls_price)
			else sls_sales
		end as sls_sales,
	
		sls_quantity,
	
		case when sls_price is null or sls_price<=0
				then sls_sales/nullif(sls_quantity, 0)
			else sls_price
		end as sls_price
	from bronze.crm_sales_details;

	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';
	

	raise notice '=========================';
	raise notice 'Loading ERP Tables';
	raise notice '=========================';


	start_time := clock_timestamp();
	
	RAISE NOTICE 'TRUNCATING TABLE silver.erp_cust_az12';
	TRUNCATE TABLE silver.erp_cust_az12;
	RAISE NOTICE 'INSERTING INTO TABLE silver.erp_cust_az12';
	insert into silver.erp_cust_az12
	(
	select
		case when cid like 'NAS%' then
			substring(cid, 4, length(cid))
			else cid
		end cid,
	
		case when bdate > now() then null
			else bdate
		end bdate,
	
		case when upper(trim(gen)) in ('F', 'FEMALE') then 'Female'
			when upper(trim(gen)) in ('M', 'MALE') then 'Male'
			else 'n/a'
		end gen
	from bronze.erp_cust_az12
	);

	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';
	
	

	start_time := clock_timestamp();
	
	RAISE NOTICE 'TRUNCATING TABLE silver.erp_loc_a101';
	TRUNCATE TABLE silver.erp_loc_a101;
	RAISE NOTICE 'INSERTING INTO TABLE silver.erp_loc_a101';
	insert into silver.erp_loc_a101(cid, cntry)
	select
		replace(cid, '-', '') cid,
	
		case when trim(cntry) in ('US', 'USA', 'United States') then 'United States' 
			when trim(cntry) = 'DE' then 'Germany'
			when trim(cntry) = '' or cntry is null then 'n/a' 
			else trim(cntry)
		end as cntry
	from bronze.erp_loc_a101;

	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';
	
	

	start_time := clock_timestamp();
	
	RAISE NOTICE 'TRUNCATING TABLE silver.erp_px_cat_g1v2';
	TRUNCATE TABLE silver.erp_px_cat_g1v2;
	RAISE NOTICE 'INSERTING INTO TABLE silver.erp_px_cat_g1v2';
	insert into silver.erp_px_cat_g1v2(id, cat, subcat, maintainence)
	select
		id,
		cat,
		subcat, 
		maintainence
	from bronze.erp_px_cat_g1v2;

	end_time := clock_timestamp();
	raise notice '>> Load Duration: % seconds', round(extract(epoch from (end_time - start_time)),2);
	raise notice '-----------------------------';

	batch_end_time := clock_timestamp();
	raise notice '=========================';
	raise notice 'Loading Silver Layer Completed';
	raise notice '>> Batch Duration: % seconds', round(extract(epoch from(batch_end_time - batch_start_time)),2);
	raise notice '=========================';
	
end;
$$;

-- use this call function to run the procedure
-- call silver.load_silver();

