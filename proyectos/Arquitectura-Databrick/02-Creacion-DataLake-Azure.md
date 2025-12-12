# Laboratorio 02: Creación de Azure Data Lake Storage y Configuración de Capas para Databricks

## Introducción

En este laboratorio, aprenderemos a crear un Azure Data Lake Storage Gen2 (ADLS Gen2) en Azure. Configuraremos las capas típicas de un Data Lake (Bronze, Silver y Gold) para organizar los datos. Además, crearemos un contenedor específico para exportar datos desde Unity Catalog en Databricks, donde guardaremos modelos entrenados de Machine Learning. Finalmente, configuraremos la conexión segura usando **Access Connector for Azure Databricks** con **Azure Managed Identity**, creando un conector dedicado por cada contenedor para maximizar la seguridad y el aislamiento.

## Requisitos Previos

- Una suscripción de Azure activa.
- Azure CLI instalado y configurado (del Laboratorio 01).
- Acceso a Azure Portal.
- Un workspace de Databricks (opcional para pruebas posteriores).Conector de acceso para Azure Databricks

## Paso 1: Creación de Azure Data Lake Storage Gen2

Azure Data Lake Storage Gen2 combina las capacidades de Azure Blob Storage y Azure Data Lake Storage Gen1.

### Prerequisito: Crear el Grupo de Recursos

Antes de crear la cuenta de almacenamiento, necesitas crear un grupo de recursos.

#### Usando Azure CLI (Linux/Bash):

```bash
az group create \
  --name rg-datalake-lab \
  --location eastus
```

#### Usando Azure CLI (PowerShell):

```powershell
az group create `
  --name rg-datalake-lab `
  --location eastus
```

Verifica la creación:
```bash
az group show --name rg-datalake-lab
```

### Usando Azure Portal:

1. Ve a [Azure Portal](https://portal.azure.com).
2. Busca "Storage accounts" y haz clic en "Create".
3. Selecciona tu suscripción y resource group (crea uno nuevo si es necesario, ej. "rg-datalake-lab").
4. Nombre de la cuenta de almacenamiento: Debe ser único globalmente, ej. "datalakemylab2025".
5. Región: Selecciona una cercana, ej. "East US".
6. Performance: Standard.
7. Redundancy: Locally-redundant storage (LRS) para pruebas.
8. En "Advanced", habilita "Hierarchical namespace" (esto hace que sea ADLS Gen2).
9. Revisa y crea la cuenta.

### Usando Azure CLI (Linux/Bash):

```bash
az storage account create \
  --name datalakemylab2025 \
  --resource-group rg-datalake-lab \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --enable-hierarchical-namespace true
```

### Usando Azure CLI (PowerShell):

```powershell
az storage account create `
  --name datalakemylab2025 `
  --resource-group rg-datalake-lab `
  --location eastus `
  --sku Standard_LRS `
  --kind StorageV2 `
  --enable-hierarchical-namespace true
```

Verifica la creación:

**Linux/Bash:**
```bash
az storage account show --name datalakemylab2025 --resource-group rg-datalake-lab
```

**PowerShell:**
```powershell
az storage account show --name datalakemylab2025 --resource-group rg-datalake-lab
```

## Paso 2: Configuración de las Capas del Data Lake

Un Data Lake típico tiene capas para organizar los datos:

- **Bronze (Raw)**: Datos crudos, sin procesar.
- **Silver (Processed)**: Datos limpios y transformados.
- **Gold (Curated)**: Datos agregados y listos para análisis/consumo.

### Creación de Contenedores para las Capas:

**Linux/Bash:**
```bash
# Contenedor Bronze
az storage container create \
  --account-name datalakemylab2025 \
  --name bronze \
  --auth-mode login

# Contenedor Silver
az storage container create \
  --account-name datalakemylab2025 \
  --name silver \
  --auth-mode login

# Contenedor Gold
az storage container create \
  --account-name datalakemylab2025 \
  --name gold \
  --auth-mode login
```

**PowerShell:**
```powershell
# Contenedor Bronze
az storage container create `
  --account-name datalakemylab2025 `
  --name bronze `
  --auth-mode login

# Contenedor Silver
az storage container create `
  --account-name datalakemylab2025 `
  --name silver `
  --auth-mode login

# Contenedor Gold
az storage container create `
  --account-name datalakemylab2025 `
  --name gold `
  --auth-mode login
```

### Usando Azure Portal:

1. Ve a tu cuenta de almacenamiento.
2. En "Containers", haz clic en "+ Container" para cada capa.
3. Nombres: bronze, silver, gold.
4. Nivel de acceso público: Private.

## Paso 3: Creación de Contenedor para Modelos de Machine Learning

Crearemos un contenedor específico para exportar datos desde Unity Catalog en Databricks, donde guardaremos modelos entrenados.

### Creación del Contenedor:

**Linux/Bash:**
```bash
az storage container create \
  --account-name datalakemylab2025 \
  --name models-ml \
  --auth-mode login
```

**PowerShell:**
```powershell
az storage container create `
  --account-name datalakemylab2025 `
  --name models-ml `
  --auth-mode login
```

Este contenedor se usará para almacenar modelos exportados desde Databricks, aprovechando Unity Catalog para gestionar metadatos.

## Paso 4: Configuración de Conexión con Access Connector para Azure Databricks

Usaremos **Access Connector for Azure Databricks** con **Azure Managed Identity**, el método recomendado por Microsoft que elimina la necesidad de gestionar secrets manualmente. Crearemos un Access Connector dedicado para cada contenedor, proporcionando aislamiento y seguridad granular.

### Creación de Access Connectors

Crearemos 4 Access Connectors, uno para cada contenedor del Data Lake:

#### 1. Access Connector para Bronze

**Usando Azure Portal:**
1. Busca "Databricks Access Connectors" y haz clic en **Create**.
2. Configura:
   - **Name**: `databricks-connector-bronze`
   - **Resource Group**: `rg-datalake-lab`
   - **Region**: `East US` (la misma de tu storage)
3. Haz clic en **Review + Create** y luego **Create**.
4. Una vez creado, copia el **Resource ID** (formato: `/subscriptions/.../resourceGroups/.../providers/Microsoft.Databricks/accessConnectors/databricks-connector-bronze`).

**Usando Azure CLI (Linux/Bash):**
```bash
az databricks access-connector create \
  --name databricks-connector-bronze \
  --resource-group rg-datalake-lab \
  --location eastus \
  --identity-type SystemAssigned
```

**Usando Azure CLI (PowerShell):**
```powershell
az databricks access-connector create `
  --name databricks-connector-bronze `
  --resource-group rg-datalake-lab `
  --location eastus `
  --identity-type SystemAssigned
```

#### 2. Access Connector para Silver

**Usando Azure Portal:**
- Repite el proceso anterior con **Name**: `databricks-connector-silver`

**Usando Azure CLI (Linux/Bash):**
```bash
az databricks access-connector create \
  --name databricks-connector-silver \
  --resource-group rg-datalake-lab \
  --location eastus \
  --identity-type SystemAssigned
```

**Usando Azure CLI (PowerShell):**
```powershell
az databricks access-connector create `
  --name databricks-connector-silver `
  --resource-group rg-datalake-lab `
  --location eastus `
  --identity-type SystemAssigned
```

#### 3. Access Connector para Gold

**Usando Azure Portal:**
- Repite el proceso anterior con **Name**: `databricks-connector-gold`

**Usando Azure CLI (Linux/Bash):**
```bash
az databricks access-connector create \
  --name databricks-connector-gold \
  --resource-group rg-datalake-lab \
  --location eastus \
  --identity-type SystemAssigned
```

**Usando Azure CLI (PowerShell):**
```powershell
az databricks access-connector create `
  --name databricks-connector-gold `
  --resource-group rg-datalake-lab `
  --location eastus `
  --identity-type SystemAssigned
```

#### 4. Access Connector para Models-ML

**Usando Azure Portal:**
- Repite el proceso anterior con **Name**: `databricks-connector-models-ml`

**Usando Azure CLI (Linux/Bash):**
```bash
az databricks access-connector create \
  --name databricks-connector-models-ml \
  --resource-group rg-datalake-lab \
  --location eastus \
  --identity-type SystemAssigned
```

**Usando Azure CLI (PowerShell):**
```powershell
az databricks access-connector create `
  --name databricks-connector-models-ml `
  --resource-group rg-datalake-lab `
  --location eastus `
  --identity-type SystemAssigned
```

### Asignar Permisos a cada Access Connector

Cada Access Connector necesita permisos sobre su contenedor correspondiente:

#### Permisos para Bronze

**Usando Azure Portal:**
1. Ve a tu cuenta de almacenamiento `datalakemylab2025`.
2. En el menú lateral, selecciona **Access Control (IAM)**.
3. Haz clic en **+ Add** → **Add role assignment**.
4. Selecciona el rol **Storage Blob Data Contributor**.
5. En la pestaña **Members**, selecciona **Managed identity**.
6. Haz clic en **+ Select members** y busca `databricks-connector-bronze`.
7. Haz clic en **Review + assign**.

**Usando Azure CLI (Linux/Bash):**
```bash
# Obtener el Subscription ID actual
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Obtener el principal ID del Access Connector
BRONZE_PRINCIPAL_ID=$(az databricks access-connector show \
  --name databricks-connector-bronze \
  --resource-group rg-datalake-lab \
  --query identity.principalId -o tsv)

# Asignar permisos al contenedor bronze
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $BRONZE_PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-datalake-lab/providers/Microsoft.Storage/storageAccounts/datalakemylab2025/blobServices/default/containers/bronze"
```

**Usando Azure CLI (PowerShell):**
```powershell
# Obtener el Subscription ID actual
$SUBSCRIPTION_ID = az account show --query id -o tsv

# Obtener el principal ID del Access Connector
$BRONZE_PRINCIPAL_ID = az databricks access-connector show `
  --name databricks-connector-bronze `
  --resource-group rg-datalake-lab `
  --query identity.principalId -o tsv

# Asignar permisos al contenedor bronze
az role assignment create `
  --role "Storage Blob Data Contributor" `
  --assignee $BRONZE_PRINCIPAL_ID `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-datalake-lab/providers/Microsoft.Storage/storageAccounts/datalakemylab2025/blobServices/default/containers/bronze"
```

#### Permisos para Silver, Gold y Models-ML

Repite el proceso anterior para cada contenedor, reemplazando `bronze` y `databricks-connector-bronze` por:
- **Silver**: `silver` y `databricks-connector-silver`
- **Gold**: `gold` y `databricks-connector-gold`
- **Models-ML**: `models-ml` y `databricks-connector-models-ml`

### Configuración en Unity Catalog

#### Paso 1: Crear Storage Credentials (uno por Access Connector)

**Para Bronze:**
1. En tu workspace de Databricks, navega a:
   - **Catalog** → **External Data** → **Storage Credentials**
2. Haz clic en **Create Credential**
3. Configura:
   - **Credential Name**: `credential-bronze`
   - **Type**: Azure Managed Identity
   - **Access Connector ID**: Pega el Resource ID de `databricks-connector-bronze`
4. Haz clic en **Create**

**Para Silver:**
- Repite con **Credential Name**: `credential-silver`
- **Access Connector ID**: Resource ID de `databricks-connector-silver`

**Para Gold:**
- Repite con **Credential Name**: `credential-gold`
- **Access Connector ID**: Resource ID de `databricks-connector-gold`

**Para Models-ML:**
- Repite con **Credential Name**: `credential-models-ml`
- **Access Connector ID**: Resource ID de `databricks-connector-models-ml`

#### Paso 2: Crear External Locations

**Para Bronze:**
1. Navega a: **Catalog** → **External Data** → **External Locations**
2. Haz clic en **Create Location**
3. Configura:
   - **Location Name**: `external-bronze`
   - **URL**: `abfss://bronze@datalakemylab2025.dfs.core.windows.net/`
   - **Storage Credential**: `credential-bronze`
4. Haz clic en **Create**

**Para Silver:**
   - **Location Name**: `external-silver`
   - **URL**: `abfss://silver@datalakemylab2025.dfs.core.windows.net/`
   - **Storage Credential**: `credential-silver`

**Para Gold:**
   - **Location Name**: `external-gold`
   - **URL**: `abfss://gold@datalakemylab2025.dfs.core.windows.net/`
   - **Storage Credential**: `credential-gold`

**Para Models-ML:**
   - **Location Name**: `external-models-ml`
   - **URL**: `abfss://models-ml@datalakemylab2025.dfs.core.windows.net/`
   - **Storage Credential**: `credential-models-ml`

#### Paso 3: Crear Catálogos, Schemas y Volúmenes en Unity Catalog

**IMPORTANTE**: En Unity Catalog 100%, el acceso directo vía `abfss://` está obsoleto (legacy). Debemos usar la estructura de tres niveles: **Catalog → Schema → Volume/Table**.

##### 3.1. Crear External Location para el Catálogo raíz (opcional)

Si tu workspace requiere especificar ubicación en el catálogo, crea primero una External Location base:

1. Navega a: **Catalog** → **External Data** → **External Locations**
2. Haz clic en **Create Location**
3. Configura:
   - **Location Name**: `datalake-root`
   - **URL**: `abfss://bronze@datalakemylab2025.dfs.core.windows.net/`
   - **Storage Credential**: `credential-bronze`
4. Haz clic en **Create**

##### 3.2. Crear Catálogo para Data Lake

**Usando SQL en notebook de Databricks:**

```sql
-- Opción 1: Crear catálogo CON ubicación específica (recomendado si tu workspace lo requiere)
CREATE CATALOG IF NOT EXISTS datalake_catalog
MANAGED LOCATION 'abfss://bronze@datalakemylab2025.dfs.core.windows.net/catalogs/datalake'
COMMENT 'Catálogo principal para Data Lake con capas Bronze, Silver y Gold';

-- Opción 2: Crear catálogo SIN ubicación (usa la ubicación predeterminada del metastore)
-- Solo usar si tu workspace NO requiere especificar ubicación
-- CREATE CATALOG IF NOT EXISTS datalake_catalog
-- COMMENT 'Catálogo principal para Data Lake con capas Bronze, Silver y Gold';

-- Usar el catálogo
USE CATALOG datalake_catalog;
```

##### 3.3. Crear Schemas para cada capa

```sql
-- Schema para capa Bronze (datos crudos)
-- MANAGED LOCATION usa el nombre de la External Location creada anteriormente
CREATE SCHEMA IF NOT EXISTS datalake_catalog.bronze
MANAGED LOCATION 'abfss://bronze@datalakemylab2025.dfs.core.windows.net/bronze'
COMMENT 'Capa Bronze: Datos crudos sin procesar';

-- Schema para capa Silver (datos procesados)
CREATE SCHEMA IF NOT EXISTS datalake_catalog.silver
MANAGED LOCATION 'abfss://silver@datalakemylab2025.dfs.core.windows.net/silver'
COMMENT 'Capa Silver: Datos limpios y transformados';

-- Schema para capa Gold (datos agregados)
CREATE SCHEMA IF NOT EXISTS datalake_catalog.gold
MANAGED LOCATION 'abfss://gold@datalakemylab2025.dfs.core.windows.net/gold'
COMMENT 'Capa Gold: Datos agregados y listos para análisis';
```

##### 3.4. Crear Catálogo y Schema para Modelos ML

```sql
-- Crear catálogo para modelos de Machine Learning
CREATE CATALOG IF NOT EXISTS ml_catalog
MANAGED LOCATION 'abfss://models-ml@datalakemylab2025.dfs.core.windows.net/catalogs/ml'
COMMENT 'Catálogo para modelos y artefactos de Machine Learning';

USE CATALOG ml_catalog;

-- Schema para modelos
CREATE SCHEMA IF NOT EXISTS ml_catalog.models
MANAGED LOCATION 'abfss://models-ml@datalakemylab2025.dfs.core.windows.net/models'
COMMENT 'Schema para almacenar modelos entrenados';
```

##### 3.4. Crear Volúmenes (opcional, para archivos no estructurados)

Los volúmenes son útiles para almacenar archivos como CSVs, JSONs o artefactos de modelos:

```sql
-- Volumen para archivos raw en Bronze
USE CATALOG datalake_catalog;
USE SCHEMA bronze;

CREATE VOLUME IF NOT EXISTS raw_files
COMMENT 'Volumen para archivos CSV/JSON sin procesar';

-- Volumen para artefactos de modelos
USE CATALOG ml_catalog;
USE SCHEMA models;

CREATE VOLUME IF NOT EXISTS model_artifacts
COMMENT 'Volumen para artefactos de modelos (checkpoints, logs, etc.)';
```

#### Paso 4: Acceso desde notebooks (Unity Catalog 100%)

**⚠️ IMPORTANTE**: El acceso directo vía `abfss://` es **legacy** y no está permitido en Unity Catalog 100%. Usa la sintaxis de tres niveles.

##### Acceso correcto (Unity Catalog 100%):

```python
# ✅ CORRECTO: Usar notación de tres niveles (catalog.schema.table)

# Leer datos desde Bronze
df_bronze = spark.read.table("datalake_catalog.bronze.raw_data")

# Leer datos desde Silver
df_silver = spark.read.table("datalake_catalog.silver.cleaned_data")

# Leer datos desde Gold
df_gold = spark.read.table("datalake_catalog.gold.aggregated_data")

# Crear tabla en Bronze desde CSV (usando volumen)
spark.sql("""
CREATE TABLE IF NOT EXISTS datalake_catalog.bronze.raw_sales
USING CSV
OPTIONS (header 'true', inferSchema 'true')
LOCATION 'dbfs:/Volumes/datalake_catalog/bronze/raw_files/sales.csv'
""")

# Escribir DataFrame a Silver
df_cleaned = df_bronze.dropna()
df_cleaned.write.mode("overwrite").saveAsTable("datalake_catalog.silver.cleaned_sales")

# Consultar con SQL
spark.sql("""
SELECT * 
FROM datalake_catalog.gold.sales_summary
WHERE revenue > 10000
""").display()
```

##### Acceso a volúmenes para archivos:

```python
# Listar archivos en volumen de Bronze
dbutils.fs.ls("/Volumes/datalake_catalog/bronze/raw_files")

# Leer CSV desde volumen
df = spark.read.csv(
    "/Volumes/datalake_catalog/bronze/raw_files/data.csv",
    header=True,
    inferSchema=True
)

# Guardar artefactos de modelo en volumen
import mlflow

model_path = "/Volumes/ml_catalog/models/model_artifacts/my_model_v1"
mlflow.sklearn.save_model(model, model_path)
```

##### Trabajar con modelos en Unity Catalog:

```python
import mlflow

# Configurar MLflow para usar Unity Catalog
mlflow.set_registry_uri("databricks-uc")

# Registrar modelo en Unity Catalog
model_uri = "runs:/<run_id>/model"
mlflow.register_model(
    model_uri=model_uri,
    name="ml_catalog.models.taxi_fare_predictor"
)

# Cargar modelo desde Unity Catalog
loaded_model = mlflow.pyfunc.load_model("models:/ml_catalog.models.taxi_fare_predictor/1")

# Hacer predicciones
predictions = loaded_model.predict(test_data)
```

##### ⛔ LEGACY (NO usar en Unity Catalog 100%):

```python
# ❌ OBSOLETO: Acceso directo vía abfss:// (solo funciona en clusters sin Unity Catalog)
# NO USAR en entornos Unity Catalog 100%

# df_bronze = spark.read.format("delta").load("abfss://bronze@...")  # ❌ LEGACY
# dbutils.fs.ls("abfss://bronze@...")  # ❌ LEGACY
```

### Ventajas de este enfoque

✅ **Seguridad granular**: Cada contenedor tiene su propio Access Connector con permisos específicos  
✅ **Sin secrets**: No hay credenciales que rotar o gestionar manualmente  
✅ **Aislamiento**: Un compromiso en un Access Connector no afecta a otros contenedores  
✅ **Auditoría clara**: Seguimiento preciso de qué identidad accede a qué contenedor  
✅ **Compliance**: Cumple con las mejores prácticas de Azure para identidades administradas

## Paso 5: Exportación de Modelos desde Unity Catalog

En Databricks, usa Unity Catalog para gestionar modelos:

1. Registra el modelo en Unity Catalog.
2. Exporta el modelo al contenedor "models-ml":
   ```python
   import mlflow
   mlflow.set_registry_uri("databricks-uc")
   model_uri = "models:/tu-modelo/1"
   mlflow.register_model(model_uri, "models-ml")
   # Luego, guarda en ADLS si es necesario
   ```

## Conclusión

Ahora tienes un Data Lake configurado con capas y un contenedor para modelos ML. Las conexiones permiten acceso seguro desde Databricks. En el próximo laboratorio, exploraremos la integración con Databricks.

## Referencias

- [Documentación de Azure Data Lake Storage](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
- [Conexión de Databricks a ADLS](https://docs.databricks.com/storage/azure-storage.html)
- [Unity Catalog](https://docs.databricks.com/sql/language-manual/sql-ref-syntax-ddl-create-catalog-using.html)