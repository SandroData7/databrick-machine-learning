# Laboratorio 03: Poblado de la Capa Bronze del Data Lake

## Introducción

En este laboratorio, aprenderemos a poblar la capa Bronze del Azure Data Lake Storage Gen2 con datos crudos. Organizaremos los datos en subcarpetas específicas por cada dataset, siguiendo las mejores prácticas de organización de Data Lakes. Trabajaremos con tres datasets: **customers**, **products** y **sales**, creando una estructura jerárquica que facilite el acceso y gestión de datos en Unity Catalog.

## Requisitos Previos

- Laboratorio 02 completado (Data Lake Storage y Unity Catalog configurados)
- Access Connector para Bronze configurado con permisos
- External Location `external-bronze` creada
- Catálogo `datalake_catalog` y schema `bronze` creados
- Azure Storage Explorer instalado (Laboratorio 01) o acceso a Azure Portal

## Estructura de Carpetas Objetivo

Crearemos la siguiente estructura en el contenedor `bronze`:

```
bronze (contenedor)/
└── bronze/                    # Carpeta para Unity Catalog schema
    └── raw_files/             # Volumen en Unity Catalog
        ├── customers/
        │   └── customers.csv
        ├── products/
        │   └── products.csv
        └── sales/
            └── sales.csv
```

**Explicación de la estructura:**
- **Contenedor**: `bronze` (nivel de Azure Storage)
- **Carpeta schema**: `bronze/` (corresponde al schema en Unity Catalog)
- **Carpeta volumen**: `bronze/raw_files/` (corresponde al volumen en Unity Catalog)
- **Subcarpetas por dataset**: `customers/`, `products/`, `sales/`

Esta organización permite:
- ✅ Alineación con la estructura de Unity Catalog (schema/volumen)
- ✅ Separación lógica por entidad de negocio
- ✅ Facilita versionado futuro (agregar archivos por fecha)
- ✅ Mejor organización en Unity Catalog (una tabla por carpeta)
- ✅ Escalabilidad para agregar más fuentes de datos

## Descripción de los Datasets

### Customers (Clientes)
- **Archivo**: `customers.csv`
- **Registros**: ~50 clientes
- **Campos**: customer_id, name, email, phone, address, city, state, zip_code, country
- **Descripción**: Información de clientes de Adventure Works

### Products (Productos)
- **Archivo**: `products.csv`
- **Campos**: product_id, product_name, category, price, stock_quantity
- **Descripción**: Catálogo de productos disponibles

### Sales (Ventas)
- **Archivo**: `sales.csv`
- **Campos**: sale_id, customer_id, product_id, quantity, sale_date, total_amount
- **Descripción**: Transacciones de ventas realizadas

## Método 1: Subir Archivos usando Azure Storage Explorer

### Paso 1: Conectar a la cuenta de almacenamiento

1. Abre **Azure Storage Explorer**
2. En el panel izquierdo, expande tu suscripción
3. Navega a **Storage Accounts** → `datalakemylab2025` → **Blob Containers** → `bronze`

### Paso 2: Crear estructura de carpetas y subir archivos

#### Crear estructura base:

1. Haz clic derecho en el contenedor `bronze` → **New Folder**
2. Nombre: `bronze` (carpeta para Unity Catalog schema)
3. Entra a la carpeta `bronze`
4. Crea nueva carpeta: `raw_files` (volumen en Unity Catalog)
5. Entra a la carpeta `raw_files`

#### Para Customers:

1. Dentro de `bronze/raw_files/`, crea nueva carpeta: `customers`
2. Entra a la carpeta `customers`
3. Haz clic en **Upload** → **Upload Files**
4. Selecciona el archivo: `D:\Proyectos-git\repo-databrick\databrick-machine-learning\data\DE-05\customers.csv`
5. Haz clic en **Upload**

#### Para Products:

1. Regresa a `bronze/raw_files/`
2. Crea nueva carpeta: `products`
3. Entra a la carpeta `products`
4. Sube el archivo: `products.csv` desde la misma ubicación

#### Para Sales:

1. Regresa a `bronze/raw_files/`
2. Crea nueva carpeta: `sales`
3. Entra a la carpeta `sales`
4. Sube el archivo: `sales.csv` desde la misma ubicación

### Paso 3: Verificar estructura

Asegúrate de que la estructura quede así:
```
bronze (contenedor)/
└── bronze/
    └── raw_files/
        ├── customers/
        │   └── customers.csv
        ├── products/
        │   └── products.csv
        └── sales/
            └── sales.csv
```

## Método 2: Subir Archivos usando Azure Portal

### Paso 1: Acceder al contenedor

1. Ve a [Azure Portal](https://portal.azure.com)
2. Busca tu cuenta de almacenamiento: `datalakemylab2025`
3. En el menú lateral, selecciona **Containers**
4. Haz clic en el contenedor `bronze`

### Paso 2: Crear subcarpetas y subir archivos

#### Para Customers:

1. Haz clic en **Upload** (parte superior)
2. En **Advanced** (expandir), en el campo **Upload to folder**, escribe: `bronze/raw_files/customers`
3. Haz clic en **Browse for files**
4. Selecciona `customers.csv` desde `D:\Proyectos-git\repo-databrick\databrick-machine-learning\data\DE-05\`
5. Haz clic en **Upload**

#### Para Products:

1. Haz clic en **Upload** nuevamente
2. En **Upload to folder**, escribe: `bronze/raw_files/products`
3. Selecciona `products.csv`
4. Haz clic en **Upload**

#### Para Sales:

1. Haz clic en **Upload** nuevamente
2. En **Upload to folder**, escribe: `bronze/raw_files/sales`
3. Selecciona `sales.csv`
4. Haz clic en **Upload**

## Método 3: Subir Archivos usando Azure CLI

### Prerequisito: Asignar permisos a tu usuario

Para usar `--auth-mode login`, tu cuenta de usuario necesita permisos en el Storage Account:

**Opción A: Asignar rol usando Azure Portal**

1. Ve a tu cuenta de almacenamiento `datalakemylab2025`
2. En el menú lateral, selecciona **Access Control (IAM)**
3. Haz clic en **+ Add** → **Add role assignment**
4. Selecciona el rol **Storage Blob Data Contributor**
5. En la pestaña **Members**, selecciona tu cuenta de usuario
6. Haz clic en **Review + assign**

**Opción B: Asignar rol usando Azure CLI**

```bash
# Obtener tu Object ID
USER_ID=$(az ad signed-in-user show --query id -o tsv)

# Obtener el Subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Asignar rol Storage Blob Data Contributor
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $USER_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-datalake-lab/providers/Microsoft.Storage/storageAccounts/datalakemylab2025"

echo "Permisos asignados. Espera 2-3 minutos para que se propaguen."
```

```powershell
# Obtener tu Object ID
$USER_ID = az ad signed-in-user show --query id -o tsv

# Obtener el Subscription ID
$SUBSCRIPTION_ID = az account show --query id -o tsv

# Asignar rol Storage Blob Data Contributor
az role assignment create `
  --role "Storage Blob Data Contributor" `
  --assignee $USER_ID `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-datalake-lab/providers/Microsoft.Storage/storageAccounts/datalakemylab2025"

Write-Host "Permisos asignados. Espera 2-3 minutos para que se propaguen."
```

### Opción 1: Subir usando autenticación de usuario (auth-mode login)

**Requiere**: Haber completado el prerequisito de permisos arriba.

**Linux/Bash:**
```bash
# Variables
STORAGE_ACCOUNT="datalakemylab2025"
CONTAINER="bronze"
LOCAL_PATH="D:/Proyectos-git/repo-databrick/databrick-machine-learning/data/DE-05"

# Subir customers.csv
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name $CONTAINER \
  --name "bronze/raw_files/customers/customers.csv" \
  --file "$LOCAL_PATH/customers.csv" \
  --auth-mode login

# Subir products.csv
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name $CONTAINER \
  --name "bronze/raw_files/products/products.csv" \
  --file "$LOCAL_PATH/products.csv" \
  --auth-mode login

# Subir sales.csv
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --container-name $CONTAINER \
  --name "bronze/raw_files/sales/sales.csv" \
  --file "$LOCAL_PATH/sales.csv" \
  --auth-mode login

echo "Todos los archivos subidos exitosamente"
```

**PowerShell:**
```powershell
# Variables
$STORAGE_ACCOUNT = "datalakemylab2025"
$CONTAINER = "bronze"
$LOCAL_PATH = "D:\Proyectos-git\repo-databrick\databrick-machine-learning\data\DE-05"

# Subir customers.csv
az storage blob upload `
  --account-name $STORAGE_ACCOUNT `
  --container-name $CONTAINER `
  --name "bronze/raw_files/customers/customers.csv" `
  --file "$LOCAL_PATH\customers.csv" `
  --auth-mode login

# Subir products.csv
az storage blob upload `
  --account-name $STORAGE_ACCOUNT `
  --container-name $CONTAINER `
  --name "bronze/raw_files/products/products.csv" `
  --file "$LOCAL_PATH\products.csv" `
  --auth-mode login

# Subir sales.csv
az storage blob upload `
  --account-name $STORAGE_ACCOUNT `
  --container-name $CONTAINER `
  --name "bronze/raw_files/sales/sales.csv" `
  --file "$LOCAL_PATH\sales.csv" `
  --auth-mode login

Write-Host "Todos los archivos subidos exitosamente"
```

### Opción 2: Subir usando Storage Account Key (sin permisos adicionales)

Si no puedes asignar permisos a tu usuario, usa la key del Storage Account:

**Paso 1: Obtener la Storage Account Key**

```bash
# Linux/Bash
STORAGE_KEY=$(az storage account keys list \
  --account-name datalakemylab2025 \
  --resource-group rg-datalake-lab \
  --query "[0].value" -o tsv)

echo "Key obtenida"
```

```powershell
# PowerShell
$STORAGE_KEY = az storage account keys list `
  --account-name datalakemylab2025 `
  --resource-group rg-datalake-lab `
  --query "[0].value" -o tsv

Write-Host "Key obtenida"
```

**Paso 2: Subir archivos usando la key**

**Linux/Bash:**
```bash
# Variables
STORAGE_ACCOUNT="datalakemylab2025"
CONTAINER="bronze"
LOCAL_PATH="D:/Proyectos-git/repo-databrick/databrick-machine-learning/data/DE-05"

# Subir customers.csv
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name $CONTAINER \
  --name "bronze/raw_files/customers/customers.csv" \
  --file "$LOCAL_PATH/customers.csv"

# Subir products.csv
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name $CONTAINER \
  --name "bronze/raw_files/products/products.csv" \
  --file "$LOCAL_PATH/products.csv"

# Subir sales.csv
az storage blob upload \
  --account-name $STORAGE_ACCOUNT \
  --account-key $STORAGE_KEY \
  --container-name $CONTAINER \
  --name "bronze/raw_files/sales/sales.csv" \
  --file "$LOCAL_PATH/sales.csv"

echo "Todos los archivos subidos exitosamente"
```

**PowerShell:**
```powershell
# Variables
$STORAGE_ACCOUNT = "datalakemylab2025"
$CONTAINER = "bronze"
$LOCAL_PATH = "D:\Proyectos-git\repo-databrick\databrick-machine-learning\data\DE-05"

# Subir customers.csv
az storage blob upload `
  --account-name $STORAGE_ACCOUNT `
  --account-key $STORAGE_KEY `
  --container-name $CONTAINER `
  --name "bronze/raw_files/customers/customers.csv" `
  --file "$LOCAL_PATH\customers.csv"

# Subir products.csv
az storage blob upload `
  --account-name $STORAGE_ACCOUNT `
  --account-key $STORAGE_KEY `
  --container-name $CONTAINER `
  --name "bronze/raw_files/products/products.csv" `
  --file "$LOCAL_PATH\products.csv"

# Subir sales.csv
az storage blob upload `
  --account-name $STORAGE_ACCOUNT `
  --account-key $STORAGE_KEY `
  --container-name $CONTAINER `
  --name "bronze/raw_files/sales/sales.csv" `
  --file "$LOCAL_PATH\sales.csv"

Write-Host "Todos los archivos subidos exitosamente"
```

### Verificar archivos subidos

**Linux/Bash:**
```bash
# Listar toda la estructura bajo bronze/raw_files/
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name $CONTAINER \
  --prefix "bronze/raw_files/" \
  --auth-mode login \
  --query "[].name" -o table

# O verificar carpeta específica
az storage blob list \
  --account-name $STORAGE_ACCOUNT \
  --container-name $CONTAINER \
  --prefix "bronze/raw_files/customers/" \
  --auth-mode login \
  --query "[].name" -o table
```

**PowerShell:**
```powershell
# Listar toda la estructura bajo bronze/raw_files/
az storage blob list `
  --account-name $STORAGE_ACCOUNT `
  --container-name $CONTAINER `
  --prefix "bronze/raw_files/" `
  --auth-mode login `
  --query "[].name" -o table

# O verificar carpeta específica
az storage blob list `
  --account-name $STORAGE_ACCOUNT `
  --container-name $CONTAINER `
  --prefix "bronze/raw_files/customers/" `
  --auth-mode login `
  --query "[].name" -o table
```

## Paso 4: Configurar Permisos (CRÍTICO - Requerido antes de acceder a datos)

### ⚠️ IMPORTANTE: Sin estos permisos obtendrás el error "PERMISSION_DENIED"

Hay dos niveles de permisos necesarios para acceder a los datos:

### 4.1. **[OBLIGATORIO]** Asignar permisos del Access Connector en Azure Storage

El Access Connector debe tener rol **Storage Blob Data Contributor** en el Storage Account.

**Verificar en Azure Portal:**

1. Ve a tu Storage Account `datalakemylab2025`
2. Selecciona **Access Control (IAM)**
3. Haz clic en **Role assignments**
4. Busca `databricks-connector-bronze` en la lista
5. Debe tener el rol **Storage Blob Data Contributor**

**Si no está asignado, ejecuta:**

```bash
# Linux/Bash
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Obtener el Principal ID del Access Connector
PRINCIPAL_ID=$(az databricks access-connector show \
  --name databricks-connector-bronze \
  --resource-group rg-datalake-lab \
  --query identity.principalId -o tsv)

# Asignar rol Storage Blob Data Contributor
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $PRINCIPAL_ID \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-datalake-lab/providers/Microsoft.Storage/storageAccounts/datalakemylab2025"

echo "Permisos asignados al Access Connector. Espera 2-3 minutos para propagación."
```

```powershell
# PowerShell
$SUBSCRIPTION_ID = az account show --query id -o tsv

# Obtener el Principal ID del Access Connector
$PRINCIPAL_ID = az databricks access-connector show `
  --name databricks-connector-bronze `
  --resource-group rg-datalake-lab `
  --query identity.principalId -o tsv

# Asignar rol Storage Blob Data Contributor
az role assignment create `
  --role "Storage Blob Data Contributor" `
  --assignee $PRINCIPAL_ID `
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-datalake-lab/providers/Microsoft.Storage/storageAccounts/datalakemylab2025"

Write-Host "Permisos asignados al Access Connector. Espera 2-3 minutos para propagación."
```

**✅ Verificar la asignación en Azure Portal:**

1. Ve a tu Storage Account `datalakemylab2025`
2. Selecciona **Access Control (IAM)**
3. Haz clic en **Role assignments**
4. Busca `databricks-connector-bronze` con rol **Storage Blob Data Contributor**

### 4.2. Asignar permisos en Unity Catalog

Abre un notebook SQL en Databricks y ejecuta:

```sql
-- Asignar permisos de uso del catálogo
GRANT USAGE ON CATALOG datalake_catalog TO `your_user@domain.com`;

-- Asignar permisos de uso del schema bronze
GRANT USAGE ON SCHEMA datalake_catalog.bronze TO `your_user@domain.com`;

-- Asignar permisos de lectura sobre el volumen raw_files
GRANT READ_VOLUME ON VOLUME datalake_catalog.bronze.raw_files TO `your_user@domain.com`;

-- Asignar permisos para crear tablas en el schema
GRANT CREATE TABLE ON SCHEMA datalake_catalog.bronze TO `your_user@domain.com`;

-- Verificar permisos
SHOW GRANTS ON CATALOG datalake_catalog;
SHOW GRANTS ON SCHEMA datalake_catalog.bronze;
SHOW GRANTS ON VOLUME datalake_catalog.bronze.raw_files;
```

**Alternativa: Asignar permisos a un grupo de usuarios**

Si trabajas en equipo, es mejor asignar permisos a un grupo:

```sql
-- Crear grupo (si no existe)
CREATE GROUP IF NOT EXISTS data_engineers;

-- Agregar usuario al grupo
ALTER GROUP data_engineers ADD USER `your_user@domain.com`;

-- Asignar permisos al grupo
GRANT USAGE ON CATALOG datalake_catalog TO data_engineers;
GRANT USAGE ON SCHEMA datalake_catalog.bronze TO data_engineers;
GRANT READ_VOLUME ON VOLUME datalake_catalog.bronze.raw_files TO data_engineers;
GRANT CREATE TABLE ON SCHEMA datalake_catalog.bronze TO data_engineers;
```

### 4.3. **[CRÍTICO]** Reiniciar el Cluster de Databricks

Después de asignar permisos en Azure Storage, **DEBES reiniciar el cluster**:

1. Ve a **Compute** en Databricks
2. Selecciona tu cluster
3. Haz clic en **Restart**
4. Espera a que el cluster esté en estado **Running**

**Tiempos de propagación:**
- **Permisos Azure Storage**: 2-3 minutos + reinicio de cluster (obligatorio)
- **Permisos Unity Catalog**: Inmediatos (no requieren reinicio)

---

## Paso 5: Verificar Acceso desde Databricks

Una vez configurados los permisos, verifica el acceso desde un notebook de Databricks:

### Verificar usando Volúmenes (Unity Catalog 100%)

```python
# Listar carpetas en Bronze
dbutils.fs.ls("/Volumes/datalake_catalog/bronze/raw_files")

# Verificar archivos de customers
display(dbutils.fs.ls("/Volumes/datalake_catalog/bronze/raw_files/customers"))

# Verificar archivos de products
display(dbutils.fs.ls("/Volumes/datalake_catalog/bronze/raw_files/products"))

# Verificar archivos de sales
display(dbutils.fs.ls("/Volumes/datalake_catalog/bronze/raw_files/sales"))
```

---

## Paso 6: Crear Tablas en Unity Catalog desde los archivos CSV

Una vez verificado el acceso, crea tablas externas en Unity Catalog:

### Crear Tabla Customers

```python
# Leer CSV desde el volumen
df_customers = spark.read.csv(
    "/Volumes/datalake_catalog/bronze/raw_files/customers/customers.csv",
    header=True,
    inferSchema=True
)

# Guardar como tabla en Unity Catalog
df_customers.write.mode("overwrite").saveAsTable("datalake_catalog.bronze.customers")

# Verificar tabla creada
display(spark.sql("SELECT * FROM datalake_catalog.bronze.customers LIMIT 10"))
```

### Crear Tabla Products

```python
# Leer CSV desde el volumen
df_products = spark.read.csv(
    "/Volumes/datalake_catalog/bronze/raw_files/products/products.csv",
    header=True,
    inferSchema=True
)

# Guardar como tabla en Unity Catalog
df_products.write.mode("overwrite").saveAsTable("datalake_catalog.bronze.products")

# Verificar tabla creada
display(spark.sql("SELECT * FROM datalake_catalog.bronze.products LIMIT 10"))
```

### Crear Tabla Sales

```python
# Leer CSV desde el volumen
df_sales = spark.read.csv(
    "/Volumes/datalake_catalog/bronze/raw_files/sales/sales.csv",
    header=True,
    inferSchema=True
)

# Guardar como tabla en Unity Catalog
df_sales.write.mode("overwrite").saveAsTable("datalake_catalog.bronze.sales")

# Verificar tabla creada
display(spark.sql("SELECT * FROM datalake_catalog.bronze.sales LIMIT 10"))
```

---

## Paso 7: Verificación Final

### Verificar en Data Explorer

1. En Databricks, ve a **Data**
2. Navega a `datalake_catalog` → `bronze`
3. Debes ver 3 tablas: `customers`, `products`, `sales`
4. Haz clic en cada tabla para ver su schema y preview de datos

### Verificar con SQL

```sql
-- Ver todas las tablas en bronze
SHOW TABLES IN datalake_catalog.bronze;

-- Ver esquema de cada tabla
DESCRIBE TABLE datalake_catalog.bronze.customers;
DESCRIBE TABLE datalake_catalog.bronze.products;
DESCRIBE TABLE datalake_catalog.bronze.sales;

-- Verificar conteos de registros
SELECT 'customers' AS tabla, COUNT(*) AS registros FROM datalake_catalog.bronze.customers
UNION ALL
SELECT 'products' AS tabla, COUNT(*) AS registros FROM datalake_catalog.bronze.products
UNION ALL
SELECT 'sales' AS tabla, COUNT(*) AS registros FROM datalake_catalog.bronze.sales;
```

### Checklist de completitud

- [ ] Archivos CSV subidos a Azure Storage en `bronze/bronze/raw_files/`
- [ ] ✅ **Permisos del Access Connector asignados en Azure Storage** (paso crítico)
- [ ] ✅ **Cluster reiniciado después de asignar permisos** (obligatorio)
- [ ] Permisos de usuario asignados en Unity Catalog
- [ ] Volúmenes accesibles desde notebooks (`dbutils.fs.ls` funciona)
- [ ] Tablas creadas en Unity Catalog (customers, products, sales)
- [ ] Datos visibles en Data Explorer

---

## Troubleshooting

### Error: "PERMISSION_DENIED: Request for user delegation key is not authorized"

**Causa**: El Access Connector NO tiene permisos en Azure Storage, o el cluster no se reinició después de asignar permisos.

**Solución (ejecutar en orden)**: 
1. Ejecutar script PowerShell del [Paso 4.1](#41-obligatorio-asignar-permisos-del-access-connector-en-azure-storage) para asignar rol al Access Connector
2. Esperar 2-3 minutos para propagación de permisos en Azure
3. **[CRÍTICO] Reiniciar el cluster de Databricks** ([Paso 4.3](#43-crítico-reiniciar-el-cluster-de-databricks)) - sin esto NO funcionará
4. Asignar permisos en Unity Catalog ([Paso 4.2](#42-asignar-permisos-en-unity-catalog))
5. Volver a ejecutar `dbutils.fs.ls("/Volumes/datalake_catalog/bronze/raw_files")`

### Error: "Catalog 'datalake_catalog' not found"

**Causa**: El catálogo no fue creado en Lab 02.

**Solución**: Volver al [Laboratorio 02](02-Creacion-DataLake-Azure.md) y ejecutar los comandos de creación de catálogo.

### Error: "Volume 'raw_files' not found"

**Causa**: El volumen no fue creado en el schema.

**Solución**: Ejecutar en un notebook SQL:
```sql
CREATE EXTERNAL VOLUME IF NOT EXISTS datalake_catalog.bronze.raw_files
LOCATION 'abfss://bronze@datalakemylab2025.dfs.core.windows.net/bronze/raw_files';
```

### Los archivos no aparecen en dbutils.fs.ls()

**Verificar**:
1. Los archivos están en la ruta correcta en Azure Storage: `bronze/bronze/raw_files/customers/`
2. El volumen apunta a la ubicación correcta: `bronze/raw_files` (no solo `bronze`)
3. Los permisos están asignados correctamente

```python
# Verificar ruta del volumen
spark.sql("DESCRIBE VOLUME datalake_catalog.bronze.raw_files").show(truncate=False)
```

### Error al crear tablas: "Path does not exist"

**Causa**: La ruta del volumen no coincide con la estructura de carpetas en Azure Storage.

**Solución**: Verificar que los archivos estén en:
- Azure Storage: `bronze` (container) → `bronze` (carpeta) → `raw_files` (carpeta) → `customers` (carpeta) → `customers.csv`
- Volumen debe apuntar a: `abfss://bronze@storage.dfs.core.windows.net/bronze/raw_files`

---

## Próximos Pasos

### Script completo para crear todas las tablas

```python
# Configuración
catalog = "datalake_catalog"
schema = "bronze"
volume_path = f"/Volumes/{catalog}/{schema}/raw_files"

# Definir datasets
datasets = [
    {"name": "customers", "path": f"{volume_path}/customers/customers.csv"},
    {"name": "products", "path": f"{volume_path}/products/products.csv"},
    {"name": "sales", "path": f"{volume_path}/sales/sales.csv"}
]

# Crear todas las tablas
for dataset in datasets:
    print(f"Creando tabla: {catalog}.{schema}.{dataset['name']}")
    
    # Leer CSV
    df = spark.read.csv(dataset['path'], header=True, inferSchema=True)
    
    # Guardar como tabla
    df.write.mode("overwrite").saveAsTable(f"{catalog}.{schema}.{dataset['name']}")
    
    # Contar registros
    count = spark.sql(f"SELECT COUNT(*) as count FROM {catalog}.{schema}.{dataset['name']}").collect()[0]['count']
    print(f"  ✓ Tabla creada con {count} registros")

print("\n✅ Todas las tablas creadas exitosamente")

# Listar tablas en el schema bronze
display(spark.sql(f"SHOW TABLES IN {catalog}.{schema}"))
```

## Paso 6: Verificar Estructura Completa

Ejecuta este script para verificar que todo está correctamente configurado:

```python
# Verificar estructura del catálogo
print("=== ESTRUCTURA DEL CATÁLOGO ===\n")

# Listar schemas
print("Schemas en datalake_catalog:")
display(spark.sql("SHOW SCHEMAS IN datalake_catalog"))

# Listar tablas en bronze
print("\nTablas en datalake_catalog.bronze:")
display(spark.sql("SHOW TABLES IN datalake_catalog.bronze"))

# Contar registros en cada tabla
tables = ["customers", "products", "sales"]
print("\n=== CONTEO DE REGISTROS ===\n")

for table in tables:
    result = spark.sql(f"""
        SELECT 
            '{table}' as tabla,
            COUNT(*) as registros
        FROM datalake_catalog.bronze.{table}
    """)
    display(result)

# Ver esquema de cada tabla
print("\n=== ESQUEMA DE TABLAS ===\n")

for table in tables:
    print(f"\nEsquema de {table}:")
    spark.sql(f"DESCRIBE datalake_catalog.bronze.{table}").show(truncate=False)
```

## Mejores Prácticas Aplicadas

✅ **Organización jerárquica**: Cada dataset en su propia subcarpeta  
✅ **Nombres descriptivos**: Carpetas y archivos con nombres claros  
✅ **Unity Catalog**: Acceso a través de volúmenes y tablas catalogadas  
✅ **Seguridad**: Access Connector con permisos específicos para Bronze  
✅ **Escalabilidad**: Estructura preparada para agregar más archivos (particiones por fecha)  
✅ **Auditoría**: Todo el acceso rastreado a través de Unity Catalog  

## Próximos Pasos

En el siguiente laboratorio:
- Procesaremos datos de Bronze a Silver (limpieza y transformaciones)
- Aplicaremos esquemas explícitos
- Implementaremos validaciones de calidad de datos
- Crearemos pipelines de transformación

## Referencias

- [Azure Data Lake Storage Best Practices](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-best-practices)
- [Unity Catalog Volumes](https://docs.databricks.com/sql/language-manual/sql-ref-volumes.html)
- [Databricks File Upload](https://docs.databricks.com/ingestion/file-upload/index.html)
