# Instrucciones del Proyecto de Machine Learning en Databricks

Este repositorio contiene materiales de capacitación para flujos de trabajo de Machine Learning en Azure Databricks. Demuestra pipelines de ML de extremo a extremo usando PySpark, MLlib, MLflow e integración con Azure Machine Learning.

## Resumen de Arquitectura

- **Plataforma**: Azure Databricks (notebooks ejecutados en clusters con Spark)
- **Almacenamiento de Datos**: DBFS (Databricks File System) o almacenamiento Azure montado
- **Seguimiento de Experimentos**: MLflow integrado con Azure Machine Learning
- **Despliegue de Modelos**: Azure ML para servicios web y puntuación en tiempo real
- **Componentes Clave**:
  - Notebooks en `notebooks/topics/ml-databricks/ypnb/` para ejemplos de capacitación
  - Datos de muestra en `data/` (archivos CSV, JSON)
  - Clusters de Databricks para procesamiento distribuido

## Patrones de Flujo de Datos

Los datos fluyen desde archivos crudos → DataFrames de Spark → featurización → entrenamiento de modelos → evaluación → registro/despliegue.

- Cargar datos: `spark.read.load('/FileStore/file.csv', format='csv', header='true', schema=schema)`
- Procesar: Usar funciones SQL de PySpark (`withColumn`, `select`, etc.)
- Featurizar: Pipelines de sklearn con DataFrameMapper para preprocesamiento numérico/categórico
- Entrenar: Ajustar modelos como GradientBoostingRegressor dentro de ejecuciones de MLflow
- Registrar: `mlflow.log_metric()`, `mlflow.log_artifact()` para seguimiento

Ejemplo de `notebooks/topics/ml-databricks/ypnb/02 - Training and Evaluating Machine Learning Models/2.0 Train and Validate ML Model.ipynb`:
```python
numerical = ['passengerCount', 'tripDistance']
categorical = ['hour_of_day', 'day_of_week']

numeric_transformations = [([f], Pipeline(steps=[
  ('imputer', SimpleImputer(strategy='median')),
  ('scaler', StandardScaler())])) for f in numerical]

categorical_transformations = [([f], OneHotEncoder(handle_unknown='ignore', sparse=False)) for f in categorical]

clf = Pipeline(steps=[('preprocessor', DataFrameMapper(transformations, df_out=True)), 
                      ('regressor', GradientBoostingRegressor())])
```

## Flujos de Trabajo de Desarrollo

- **Configuración del Entorno**: Adjuntar notebooks a clusters de Databricks (runtime con bibliotecas ML preinstaladas)
- **Instalación de Paquetes**: Usar `%pip install azureml-sdk[databricks]` en celdas de notebook
- **Seguimiento de Experimentos**: Establecer `mlflow.set_tracking_uri(ws.get_mlflow_tracking_uri())` para integración con Azure ML
- **Registro de Modelos**: `Model.register()` en el workspace de Azure ML
- **Despliegue**: Crear servicios web vía SDK de Azure ML para inferencia en tiempo real

Comandos no obvios:
- Autenticar Azure ML: Ejecutar `ws = Workspace(subscription_id, resource_group, workspace_name)` y seguir el login de dispositivo
- Guardar modelos en DBFS: `dbutils.fs.mkdirs('outputs'); model_file_path = os.path.join('/dbfs', 'outputs', 'model.pkl')`

## Convenciones del Proyecto

- **Preprocesamiento**: Separar características numéricas/categóricas con transformadores específicos (imputador mediano + escalador para numérico, OneHotEncoder para categórico)
- **Registro de Modelos**: Registrar RMSE, MAE, R2 dentro de ejecuciones de MLflow; guardar gráficos como artefactos
- **Manejo de Datos**: Usar DataFrames de Spark para datasets grandes; convertir a Pandas para compatibilidad con sklearn
- **Manejo de Errores**: Eliminar NA en columna objetivo antes del entrenamiento: `df.dropna(subset=['target'])`
- **Rutas de Archivos**: Usar prefijo `/dbfs/` para rutas DBFS en código Python

Diferencias con prácticas estándar:
- Sin entornos Python locales; todo se ejecuta en clusters de Databricks
- Modelos guardados como archivos .pkl en DBFS, registrados en Azure ML para despliegue
- Featurización usa DataFrameMapper de sklearn-pandas en lugar de ColumnTransformer para salida DataFrame

## Puntos de Integración

- **Workspace de Azure ML**: Conectar vía SDK para seguimiento de experimentos y registro de modelos
- **MLflow**: Rastrea ejecuciones, métricas, artefactos; sincroniza con Azure ML
- **DBFS de Databricks**: Almacenamiento persistente para modelos y datos
- **Almacenamiento Azure**: Montar contenedores para datasets grandes

Notebooks de referencia:
- `notebooks/topics/ml-databricks/ypnb/04 - Integrating Azure Databricks and Azure Machine Learning/` para patrones de integración con Azure ML
- `notebooks/topics/ml-databricks/ypnb/03 - Managing Experiments and Models/` para uso de MLflow