USE gold;
GO
DROP PROCEDURE IF EXISTS create_silver_views;
GO
CREATE PROCEDURE create_silver_views  @silverns varchar(50), @location varchar(200) 
AS
BEGIN
    DECLARE @sqlcmd nvarchar(MAX)
    EXEC sp_executesql N'DROP VIEW  IF EXISTS products'
    SET @sqlcmd = N'CREATE OR ALTER VIEW products AS SELECT * FROM openrowset(
	                BULK '''  + '/' + @silverns +'/sales/products/'',  data_source = ''trainingds'',
                    FORMAT = ''delta'') AS rows';
	EXEC sp_executesql @sqlcmd
	
	EXEC sp_executesql N'DROP VIEW IF EXISTS customers'
	SET @sqlcmd = N'CREATE OR ALTER VIEW customers AS
	                SELECT customer_id, customer_name, address, city, postalcode, country, phone, email,credit_card, updated_at FROM openrowset(
					BULK '''  + '/' + @silverns +'/sales/store_customers/'', data_source = ''trainingds'',FORMAT = ''delta'') AS rows
	                
	EXEC sp_executesql @sqlcmd
    
    EXEC sp_executesql N'DROP VIEW IF EXISTS store_orders'
	SET @sqlcmd = N'CREATE OR ALTER VIEW store_orders AS
                    SELECT * FROM openrowset(
                    BULK ''' +  '/' + @silverns +'/sales/store_orders/'', data_source = ''trainingds'', FORMAT = ''delta'')   
                    AS rows'	
	EXEC sp_executesql @sqlcmd
	
	EXEC sp_executesql N'DROP VIEW IF EXISTS ecomm_orders'
	SET @sqlcmd = N' CREATE OR ALTER VIEW ecomm_orders AS 
	                 SELECT order_number, email, product_name, order_date, order_mode, sale_price, sale_price_usd, updated_at
					 FROM openrowset(
						BULK ''' +  '/' + @silverns +'/sales/store_orders/'', data_source = ''trainingds'', FORMAT = ''delta'')   
						WITH ( order_number INT, product_name NVARCHAR(MAX), order_date DATE, order_mode NVARCHAR(MAX),
							   email NVARCHAR(MAX), sale_price FLOAT, sale_price_usd FLOAT, updated_at DATETIME
							 ) AS rows'	
	EXEC sp_executesql @sqlcmd
	
	EXEC sp_executesql N'DROP VIEW IF EXISTS orders'
	SET @sqlcmd = N' CREATE OR ALTER VIEW orders AS 
	                 SELECT order_number, email, product_name, order_date, units, sale_price,
					        order_mode, sale_price_usd, dbo.store_orders.updated_at
					 FROM dbo.store_orders 
					 JOIN dbo.customers ON dbo.customers.customer_id = dbo.store_orders.customer_id
					 JOIN dbo.products ON dbo.products.product_id = dbo.store_orders.product_id
					 UNION
					 SELECT order_number, email, product_name, order_date, 1 AS units, sale_price,
					        order_mode, sale_price_usd, updated_at
					 FROM dbo.ecomm_orders'	
	EXEC sp_executesql @sqlcmd

    EXEC sp_executesql N'DROP VIEW IF EXISTS geolocation'
	SET @sqlcmd = N'CREATE OR ALTER VIEW geolocation AS
                    SELECT * FROM openrowset(
                    BULK ''' +  '/' + @silverns +'/geolocation/'', data_source = ''trainingds'', FORMAT = ''delta'')   
                    AS rows'	
	EXEC sp_executesql @sqlcmd

    EXEC sp_executesql N'DROP VIEW IF EXISTS logs'
	SET @sqlcmd = N'CREATE OR ALTER VIEW logs AS
                    SELECT * FROM openrowset(
                    BULK ''' +  '/' + @silverns +'/logs/'', data_source = ''trainingds'', FORMAT = ''delta'')   
                    AS rows'	
	EXEC sp_executesql @sqlcmd
END;
GO

