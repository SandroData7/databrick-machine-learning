--------------------------------------------------------------
-- VARIABLES (modifica solo estas)
--------------------------------------------------------------
-- Nombre del storage account
SET storage_account = 'datadatabrick';

-- Nombre del contenedor ADLS
SET container = 'dev';

-- Nombre del Storage Credential en UC
SET storage_credential = 'cred_datadatabrick';

-- Nombre del Access Connector asociado
SET access_connector_name = 'ac-databricks-ibme';

-- Nombre de la External Location
SET external_location = 'extloc_datadatabrick_dev';

-- Esquema UC donde almacenarás tablas
SET schema_name = 'main.dev_schema';

--------------------------------------------------------------
-- 1. CREAR STORAGE CREDENTIAL USANDO ACCESS CONNECTOR
--------------------------------------------------------------
CREATE STORAGE CREDENTIAL ${storage_credential}
WITH AZURE_MANAGED_IDENTITY
  AZURE_MANAGED_IDENTITY = '${access_connector_name}';

--------------------------------------------------------------
-- 2. CREAR EXTERNAL LOCATION
--------------------------------------------------------------
CREATE EXTERNAL LOCATION ${external_location}
URL 'abfss://${container}@${storage_account}.dfs.core.windows.net/'
WITH (STORAGE CREDENTIAL ${storage_credential});

--------------------------------------------------------------
-- 3. PROBAR LA CONEXIÓN A LA LOCATION
--------------------------------------------------------------
DESCRIBE EXTERNAL LOCATION ${external_location};

--------------------------------------------------------------
-- 4. CREAR EL SCHEMA EN UC APOYADO EN ESTA LOCATION
--------------------------------------------------------------
CREATE SCHEMA IF NOT EXISTS ${schema_name}
LOCATION 'abfss://${container}@${storage_account}.dfs.core.windows.net/';

--------------------------------------------------------------
-- 5. CREAR UNA TABLA EXTERNA DE EJEMPLO
--------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ${schema_name}.sample_external_table (
    id INT,
    name STRING
)
LOCATION 'abfss://${container}@${storage_account}.dfs.core.windows.net/sample_external_table/';
