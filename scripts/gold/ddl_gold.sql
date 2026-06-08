
/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.
===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================

CREATE OR REPLACE VIEW gold.dim_products as 
select
	row_number() over(order by pi.prd_start_dt, pi.prd_key) as product_key,
	pi.prd_id as product_id,
	pi.prd_key as product_number,
	pi.prd_nm as product_name,
	pi.cat_id as category_id,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintainence,
	pi.prd_cost as cost,
	pi.prd_line as product_line,
	pi.prd_start_dt as product_start_date
from silver.crm_prd_info pi
left join silver.erp_px_cat_g1v2 pc
on pi.cat_id = pc.id
where pi.prd_end_dt is null; --filter out historical data, we need current data


-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================


CREATE OR REPLACE VIEW gold.dim_customers as
select
	row_number() over(order by cst_id) AS customer_key,
	ci.cst_id as customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname as first_name,
	ci.cst_lastname as lsat_name,
	cl.cntry as country,
	ci.cst_marital_status as marital_status,

	case when ci.cst_gndr != 'n/a' then ci.cst_gndr --crm is the master
	else coalesce(ca.gen, 'n/a')
	end as gender,
	
	ca.bdate as birth_date,
	ci.cst_create_date as create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
on ci.cst_key = ca.cid
left join silver.erp_loc_a101 cl
on ci.cst_key = cl.cid;



-- =============================================================================
-- Create Dimension: gold.fact_sales
-- =============================================================================

CREATE OR REPLACE VIEW gold.fact_sales as  
select
	sd.sls_ord_num as order_number,
	gdp.product_key,
	gdc.customer_key,
	sd.sls_order_dt as order_date,
	sd.sls_ship_dt as shipping_date,
	sd.sls_due_dt as due_date,
	sd.sls_sales as sales_amount ,
	sd.sls_quantity as quantity,
	sd.sls_price as price
from silver.crm_sales_details sd
left join gold.dim_products gdp 
on sd.sls_prd_key = gdp.product_number
left join gold.dim_customers gdc
on sd.sls_cust_id = gdc.customer_id


select * from gold.dim_customers
select * from gold.dim_products
select * from gold.fact_sales

select * 
from gold.fact_sales fs
left join gold.dim_products dp
on fs.product_key = dp.product_key
left join gold.dim_customers dc
on fs.customer_key = dc.customer_key






















