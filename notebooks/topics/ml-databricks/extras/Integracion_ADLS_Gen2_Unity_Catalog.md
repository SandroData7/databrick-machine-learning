# 📘 Integración ADLS Gen2 con Azure Databricks usando Access Connector + Unity Catalog

## 📌 Resumen

Este documento describe cómo conectar Azure Databricks (Unity Catalog) con un Data Lake Gen2 utilizando:

- Access Connector for Azure Databricks
- Managed Identity
- Storage Credential
- External Data
- Unity Catalog schema

Este método reemplaza `dbutils.fs.mount` y cumple con los requisitos de seguridad de UC.

---

## ✅ 1. Prerrequisitos

### Requisitos en Azure

Un Azure Data Lake Storage Gen2:
- `datadatabrick`

Un contenedor:
- `dev`

Un workspace Azure Databricks con Unity Catalog habilitado

Permisos de Owner en la suscripción o Resource Group

### Requisitos en Databricks

- Ser metastore admin
- Tener permisos para crear:
  - Storage Credentials
  - External Data
  - Schemas

---

## ✅ 2. Crear el Access Connector for Azure Databricks

1. Ir al Portal de Azure
2. Crear recurso:
   - **Access Connector for Azure Databricks**
3. Nombre sugerido:
   - `ac-databricks-data`
4. Seleccionar la misma región del workspace
5. Crear

El connector genera una **Managed Identity** que Databricks usará para acceder al Data Lake.

---

## ✅ 3. Asignar permisos RBAC en el ADLS Gen2

1. Ir al Storage Account:
   - **Storage Accounts → datadatabrick → Access Control (IAM) → Add role assignment**

2. Asignar al Access Connector:

### Roles obligatorios
- ✔ Storage Blob Data Contributor
- ✔ Storage Blob Data Reader

### Scope
- ✔ Nivel Storage Account completo

---

## ✅ 4. Crear el Storage Credential en Unity Catalog

En Databricks:

1. **Catalog → Storage Credentials → Create**
2. Nombre:
   - `cred_datadatabrick`
3. Tipo:
   - `Azure Managed Identity`
4. Access connector ID:
   - Copiar desde el portal Azure: en **ac-databricks-data**, copiar el valor que marca **Resource ID**
   - Ejemplo: `/subscriptions/YOUR_SUBSCRIPTION_ID/resourcegroups/YOUR_RESOURCE_GROUP/providers/microsoft.databricks/accessconnectors/ac-databricks-data`
5. Crear

Este credential autoriza UC a usar la Managed Identity para acceder a ADLS.

---

## ✅ 5. Crear la External Data

1. Ir a **Catalog → External Data → Create**
2. Nombre:
   - `extloc_datadatabrick_dev`
3. URL:
   - `abfss://dev@datadatabrick.dfs.core.windows.net/`
4. Storage Credential:
   - `cred_datadatabrick`
5. **Test Connection** → debe ser **Successful**
6. Crear

---

## ✅ 5.5 Crear un Catálogo en Unity Catalog

Ejecutar en un Notebook SQL:

```sql
CREATE CATALOG IF NOT EXISTS ml_catalog
MANAGED LOCATION 'abfss://dev@datadatabrick.dfs.core.windows.net/ml_catalog';
```

Este catálogo alojará los esquemas y tablas de tu proyecto de Machine Learning.

---

## ✅ 6. Crear un schema en Unity Catalog asociado al Data Lake

Ejecutar en un Notebook SQL:

```sql
%sql
CREATE SCHEMA IF NOT EXISTS ml_catalog.ml_models
MANAGED LOCATION 'abfss://dev@datadatabrick.dfs.core.windows.net/ml_catalog/ml_models/';
```

---

## ✅ 7. Crear tablas en esa external data

### Celda 1: Leer el archivo CSV desde la ruta

```python
df = spark.read.csv("abfss://dev@dataadatbrick.dfs.core.windows.net/nyc-taxi/", header=True, inferSchema=True)
#display(df)
```

### Celda 2: Escribir el DataFrame como tabla Delta

```python
df.write.format("delta").mode("overwrite").saveAsTable("ml_catalog.ml_models.nyctaxi")
```

---

## 🚀 8. Script SQL Automatizado

```sql
-- Crear Storage Credential (ejecutar como Metastore Admin)
CREATE STORAGE CREDENTIAL cred_datadatabrick
  USING (TYPE = 'AZURE_MANAGED_IDENTITY', AZURE_MANAGED_IDENTITY_ID = '/subscriptions/YOUR_SUBSCRIPTION_ID/resourcegroups/YOUR_RESOURCE_GROUP/providers/microsoft.databricks/accessconnectors/ac-databricks-data');

-- Crear External Data
CREATE EXTERNAL LOCATION extloc_datadatabrick_dev
  URL = 'abfss://dev@datadatabrick.dfs.core.windows.net/'
  WITH (STORAGE_CREDENTIAL = cred_datadatabrick);

-- Crear Catálogo
CREATE CATALOG IF NOT EXISTS ml_catalog
MANAGED LOCATION 'abfss://dev@datadatabrick.dfs.core.windows.net/ml_catalog';

-- Crear Schema
CREATE SCHEMA IF NOT EXISTS ml_catalog.ml_models
MANAGED LOCATION 'abfss://dev@datadatabrick.dfs.core.windows.net/ml_catalog/ml_models/';

-- Crear Tabla desde CSV
-- Ejecutar en Python:
-- df = spark.read.csv("abfss://dev@dataadatbrick.dfs.core.windows.net/nyc-taxi/", header=True, inferSchema=True)
-- df.write.format("delta").mode("overwrite").saveAsTable("ml_catalog.ml_models.nyctaxi")
```

---

**Documentación oficial:** [Azure Databricks + ADLS Gen2 + UC](https://docs.microsoft.com/en-us/azure/databricks/)

---

## 🎵 Bonus Track: Comandos Útiles

### Comprobar si tu External Location funciona

```sql
DESCRIBE EXTERNAL LOCATION extloc_datadatabrick_dev;
```

### Comando para borrar un catálogo

```sql
DROP CATALOG IF EXISTS nombre_catalog CASCADE;
```

Reemplaza `nombre_catalog` con el nombre real del catálogo que deseas eliminar (ej: `ml_catalog`).
