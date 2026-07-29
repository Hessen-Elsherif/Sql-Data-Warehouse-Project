/*
**********************************************************************
stored procedure: Load Silver Layer (bronze -> silver)
**********************************************************************
script Purpose:
  this stored procedure performs the ETL ( Extract, Transform , Load) process to populate 
  the 'silver' schema tables from the 'bronze' schema 
  actions required:
    -Truncate silver tables.
    -Inserts transformed and cleansed data from bronze into silver tables.

Parameters:
  none.
  this stored procedure does not accept any parameters or return any values.

Usage Example:
  Exec Silver.Load_silver;
***********************************************************************
*/


create or alter procedure silver.load_silver as
Begin
	declare @starttime DATETIME, @endtime DATETIME,@batch_start_time datetime, @batch_end_time datetime;
	begin try 
			set @batch_start_time = getdate();
			print'=============================================================='
			print 'loading bronze layer' ;
			print'=============================================================='

			print'--------------------------------------------------------------'
			print 'loading CRM tables';
			print'--------------------------------------------------------------'

			set @starttime = getdate();
		print '>> Truncating Table: silver.crm_cust_info';
		truncate table silver.crm_cust_info;
		print '>> Inserting Data Into: silver.crm_cust_info';
		insert into silver.crm_cust_info(
		cst_id,				 
		cst_key,				
		cst_firstname,		 
		cst_lastname,		
		cst_marital_status,  
		cst_gndr,			 
		cst_create_date     
		)
		-- the select part 
		select 
		cst_id,
		cst_key,
		trim(cst_firstname) as cst_firstname,
		trim(cst_lastname) as cst_lastname,
		case when upper(trim(cst_marital_status)) = 'S' then 'SINGLE'
			 when upper(trim(cst_marital_status)) = 'M' then 'MARRIED'
			 ELSE 'n/a'
		end  cst_marital_status,
		case when upper(trim(cst_gndr)) = 'F' then 'FEMALE'
			 when upper(trim(cst_gndr)) = 'M' then 'MALE'
			 ELSE 'n/a'
		end cst_gndr,
		cst_create_date

		-- the from part 
		from(
			select
			*,
			row_number() over (partition by cst_id order by cst_create_date DESC) as flag_last
			from bronze.crm_cust_info
			where cst_id is not null
		)t where flag_last = 1
		set @endtime = getdate();
			print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
			print'>>----------------------------------';
		-------------------------------------------------------------------------------------------------------
			set @starttime = getdate();
		print '>> Truncating Table: silver.crm_prd_info';
		truncate table silver.crm_prd_info;
		print '>> Inserting Data Into: silver.crm_prd_info';
		insert into silver.crm_prd_info (
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
		replace(substring(prd_key,1,5), '-','_') as cat_id,
		substring(prd_key,7,len(prd_key)) as prd_key,
		prd_nm,
		isnull(prd_cost,0) as prd_cost,
		case when upper(trim(prd_line)) = 'M' THEN 'MOUNTAIN'
			 when upper(trim(prd_line)) = 'R' THEN 'Road'
			 when upper(trim(prd_line)) = 'S' THEN 'Other sales'
			 when upper(trim(prd_line)) = 'T' THEN 'touring'
			 ELSE 'n/a'
		end as prd_line,
		cast(prd_start_dt as date) as prd_start_dt,
		cast(lead(prd_start_dt) over (partition by prd_key order by prd_start_dt)-1 as date) as prd_end_dt
		from bronze.crm_prd_info
		set @endtime = getdate();
			print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
			print'>>----------------------------------';
		-----------------------------------------------------------------------------------------
			set @starttime = getdate();
		print '>> Truncating Table: silver.crm_sales_details';
		truncate table silver.crm_sales_details;
		print '>> Inserting Data Into: silver.crm_sales_details';
		insert into  silver.crm_sales_details (
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
		case when sls_order_dt = 0 or len(sls_order_dt) != 8 then NULL
			 else cast(cast(sls_order_dt as VARCHAR) as date) -- this is how we convert integer to date (double cast needed)
		end as sls_order_dt,
		case when sls_ship_dt = 0 or len(sls_ship_dt) != 8 then NULL
			 else cast(cast(sls_ship_dt as VARCHAR) as date) 
		end as sls_ship_dt, 
		case when sls_due_dt = 0 or len(sls_due_dt) != 8 then NULL
			 else cast(cast(sls_due_dt as VARCHAR) as date) 
		end as sls_due_dt,
		sls_quantity,
		case  when sls_sales is null or sls_sales <= 0 or sls_sales != sls_quantity * ABS(sls_price)
				THEN sls_quantity * abs(sls_price)
			  else sls_sales
		end as sls_sales,
		case when sls_price is null or sls_price <= 0 
				then sls_sales / nullif(sls_quantity,0) -- the nullif function here ensures that if we divide by 0 , answer is null
				else sls_price
		end as sls_price
		from bronze.crm_sales_details
		set @endtime = getdate();
			print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
			print'>>----------------------------------';
		-------------------------------------------------------------------------------------------------------------
		print'--------------------------------------------------------------'
		print 'loading ERP tables';
		print'--------------------------------------------------------------'

			set @starttime = getdate();
		print '>> Truncating Table: silver.erp_cust_az12';
		truncate table silver.erp_cust_az12;
		print '>> Inserting Data Into: silver.erp_cust_az12';
		insert into silver.erp_cust_az12(
		cid,
		bdate,
		gen
		)
		select
		case when cid like 'NAS%' THEN substring (cid,4,len(cid))
			 else cid 
		end cid,
		case when bdate > getdate() then null 
			 else bdate
		end as bdate,
		case when upper(trim(gen)) in ('F','FEMALE') THEN 'FEMALE'
			 when upper(trim(gen)) in ('M','MALE') THEN 'MALE'
			 else 'n/a'
		end as gen 
		from bronze.erp_cust_az12
		set @endtime = getdate();
			print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
			print'>>----------------------------------';
		---------------------------------------------------------------------------------------------------------------
			set @starttime = getdate();
		print '>> Truncating Table: silver.erp_loc_a101';
		truncate table silver.erp_loc_a101;
		print '>> Inserting Data Into: silver.erp_loc_a101';
		insert into silver.erp_loc_a101
		(cid,
		cntry
		)
		select 
		replace(cid,'-','') cid,
		case when trim(cntry) = 'DE' THEN 'GERMANY'
			 when trim(cntry) in ('US','USA') THEN 'UNITED STATES'
			 when trim(cntry) = '' or cntry is null then 'n/a'
			 else trim(cntry)
		end as cntry
		from bronze.erp_loc_a101 
		set @endtime = getdate();
			print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
			print'>>----------------------------------';
		-----------------------------------------------------------------------------------------
			set @starttime = getdate();
		print '>> Truncating Table: silver.erp_px_cat_g1v2';
		truncate table silver.erp_px_cat_g1v2;
		print '>> Inserting Data Into: silver.erp_px_cat_g1v2';
		insert into silver.erp_px_cat_g1v2(
			id,
			cat,
			subcat,
			maintenance
		)

		select 
		id,
		cat,
		subcat,
		maintenance
		from bronze.erp_px_cat_g1v2

	set @endtime = getdate();
		print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
		print'>>----------------------------------';
		set @batch_end_time = getdate();
		print '=================================='
		print 'loading bronze layer is completed ';
		print ' - total load duration: ' + cast(DATEDIFF(second, @batch_start_time , @batch_end_time) AS NVARCHAR) + 'seconds' ;

	end try
	begin catch 
		print '======================================================='
		print ' error occured during loading bronze layer '
		print ' error message ' + ERROR_MESSAGE();
		print ' error message ' + cast (ERROR_NUMBER() AS NVARCHAR);
		print ' error message ' + cast (ERROR_STATE() AS NVARCHAR);
		print '======================================================='
	end catch 
end
