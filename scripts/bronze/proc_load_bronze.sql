/*
#######################################################
stored procedure: load bronze layer (source -> bronze)
########################################################
script purpose:
  this stored procedure loads data into the 'bronze' schema from external CSV files.
  it performs the following actions:
  - truncates the bronze tables before loading data
  - uses 'bulk insert' command to load data from csv files to bronze tables

parameters:
  none:
 this stored procedure does not accept any parameters or return any values.


usage example:
  exec bronze.load_bronze;
############################################################################################
*/

create or alter procedure bronze.load_bronze as
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
		print'>> truncating table: bronze.crm_cust_info'
		truncate table bronze.crm_cust_info;
		print'>> inserting data into: bronze.crm_cust_info'
		bulk insert bronze.crm_cust_info
		from 'C:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm/cust_info.csv'
		with(
			firstrow = 2,
			fieldterminator = ',' , 
			tablock
		);
		set @endtime = getdate();
		print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
		print'>>----------------------------------';


		set @starttime = getdate();
		print'>> truncating table: bronze.crm_sales_details'
		truncate table bronze.crm_sales_details;

		print'>> inserting data into: bronze.crm_sales_details'
		bulk insert bronze.crm_sales_details
		from 'C:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm/sales_details.csv'
		with(
			firstrow = 2,
			fieldterminator = ',' , 
			tablock
		);
		set @endtime = getdate();
		print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
		print'>>----------------------------------';

		set @starttime = getdate();
		print'>> truncating table: bronze.crm_prd_info'
		truncate table bronze.crm_prd_info;

		print'>> inserting data into: bronze.crm_prd_info'
		bulk insert bronze.crm_prd_info
		from 'C:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_crm/prd_info.csv'
		with(
			firstrow = 2,
			fieldterminator = ',' , 
			tablock
		);
		set @endtime = getdate();
		print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
		print'>>----------------------------------';
	
		print'--------------------------------------------------------------'
		print 'loading CRM tables';
		print'--------------------------------------------------------------'

		set @starttime = getdate();
		print'>> truncating table: bronze.erp_loc_a101'
		truncate table bronze.erp_loc_a101;

		print'>> inserting data into: bronze.erp_loc_a101'
		bulk insert bronze.erp_loc_a101
		from 'C:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp/loc_a101.csv'
		with(
			firstrow = 2,
			fieldterminator = ',' , 
			tablock
		);
		set @endtime = getdate();
		print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
		print'>>----------------------------------';

		set @starttime = getdate();
		print'>> truncating table: bronze.erp_cust_az12'
		truncate table bronze.erp_cust_az12;

		print'>> inserting data into: bronze.erp_cust_az12'
		bulk insert bronze.erp_cust_az12
		from 'C:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp/cust_az12.csv'
		with(
			firstrow = 2,
			fieldterminator = ',' , 
			tablock
		);
		set @endtime = getdate();
		print '>> Load duration:' + cast(datediff(second,@starttime ,@endtime) AS NVARCHAR) + 'seconds';
		print'>>----------------------------------';

		set @starttime = getdate();
		print'>> truncating table: bronze.erp_px_cat_g1v2'
		truncate table bronze.erp_px_cat_g1v2;

		print'>> truncating table: bronze.erp_px_cat_g1v2'
		bulk insert bronze.erp_px_cat_g1v2
		from 'C:\SQL\sql-data-warehouse-project\sql-data-warehouse-project\datasets\source_erp/px_cat_g1v2.csv'
		with(
			firstrow = 2,
			fieldterminator = ',' , 
			tablock
		);
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
END
