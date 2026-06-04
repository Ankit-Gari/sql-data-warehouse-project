/*
=============================================================
Create Database and Schemas
=============================================================

Script Purpose:

    This script creates a new database named 'DataWarehouse'.
    Also, the script sets up three schemas within the database: 'bronze', 'silver', and 'gold'.
 */


-- run create statement individually
-- CREATE DATABASE DataWarehouse;

CREATE SCHEMA bronze;
CREATE SCHEMA silver;
CREATE SCHEMA gold;
