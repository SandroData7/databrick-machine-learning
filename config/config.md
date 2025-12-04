# Configuración del Repositorio

Este archivo contiene la configuración del proyecto.

## Variables de Entorno

```
DATABRICKS_HOST=your-databricks-instance
DATABRICKS_TOKEN=your-token
```

## Configuración de Spark

```python
spark.conf.set("spark.databricks.delta.retentionDurationCheck.enabled", "false")
```
