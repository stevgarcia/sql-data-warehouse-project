===============================================================================
Script Purpose:
    This script creates views for the Gold layer with a start schema

    Each view performs transformations and combines data from the Silver layer 
    to produce a clean, enriched, and business-ready dataset.

Usage:
    - These views can be queried directly for analytics and reporting.

===============================================================================
CREATE VIEW gold.dim_customers AS

SELECT 

	ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key as customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	la.cntry as country,
	ci.cst_marital_status AS marital_status,
	CASE WHEN ci.cst_gndr!='n/a' then cst_gndr 
		 ELSE COALESCE(ca.gen,'n/a')
	END as gender,
	ca.bdate as birthdate,
	ci.cst_create_date as create_date
	
	
	FROM silver.crm_cust_info ci
	LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key=ca.cid
	LEFT JOIN silver.erp_loc_a101 la
	ON la.cid=ci.cst_key


CREATE VIEW gold.dim_products AS

SELECT 
	ROW_NUMBER() OVER(ORDER BY PN.[prd_start_dt],PN.[prd_key]) AS product_key,
	pn.[prd_id] as product_id, 
	pn.[prd_key] as product_number,
	pn.[prd_nm] as product_name,
	pn.[cat_id] as category_id ,
	pc.cat as category,
	pc.subcat as subcategory,
	pc.maintenance ,
	pn.[prd_cost] as cost, 
	pn.[prd_line] as product_line ,
	pn.[prd_start_dt] as start_date


FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
ON pn.cat_id=pc.id
WHERE prd_end_dt IS NULL --FILTER OUT ALL HISTORICAL DATA


CREATE VIEW gold.fact_sales AS

SELECT   
sls_ord_num,
pr.product_key,
cu.customer_key,
sls_order_dt order_date, 
sls_ship_dt shipping_date,
sls_due_dt due_date,
sls_sales sales_amount,
sls_quantity quantity,
sls_price price

FROM  
silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
ON pr.product_number=sd.sls_prd_key
LEFT JOIN gold.dim_customers cu
ON cu.customer_id=sd.sls_cust_id


---VALIDATE RELATIONSHIPS IN THE NEW MODEL--

SELECT * FROM gold.fact_sales f
LEFT JOIN  gold.dim_customers c
ON f.customer_key=c.customer_key
LEFT JOIN gold.dim_products P
ON P.product_key=f.product_key
WHERE c.customer_key is null or P.product_key is null