# Guía para Agentes de Código – Databricks ML

Estas instrucciones condensan cómo trabajar productivamente en este repo de formación de ML con Azure Databricks, Spark, MLflow y Azure ML. Mantén el trabajo dentro de notebooks de Databricks y usa DBFS para datos/modelos.

## Arquitectura y rutas clave
- **Notebooks**: ejemplos en `notebooks/topics/ml-databricks/ypnb/` y material complementario en `notebooks/dbc/`, `notebooks/markdown/`.
- **Datos**: CSV/JSON en `data/` (incluye subcarpetas como `retail-data/by-day/` y `DE-05/`). Carga en Spark, no local.
- **Persistencia**: usa `/dbfs/...` para leer/escribir desde código Python; DBFS/almacenamiento Azure montado.
- **Tracking**: MLflow integrado; opcionalmente sincronizado con Azure ML.

## Flujo de trabajo típico (Databricks)
- Adjunta el notebook a un cluster (runtime ML recomendado).
- Carga datos con Spark, ej.: `spark.read.csv('/dbfs/FileStore/path.csv', header=True, inferSchema=True)`.
- Preprocesa con PySpark; convierte a Pandas sólo para modelos sklearn cuando sea necesario.
- Encapsula featurización+modelo en `Pipeline` con `DataFrameMapper` (sklearn-pandas) para salida tipo DataFrame.
- Ejecuta entrenamientos dentro de `mlflow.start_run()` y registra métricas/artefactos.
- Guarda modelos/artefactos en `/dbfs/outputs/` y registra/implanta en Azure ML si aplica.

## Patrones y convenciones del proyecto
- **Featurización**: separa numéricas/categóricas. Numéricas → `SimpleImputer(strategy='median')` + `StandardScaler`. Categóricas → `OneHotEncoder(handle_unknown='ignore', sparse=False)`.
- **Modelado**: ejemplos con `GradientBoostingRegressor` integrados en `Pipeline` tras `DataFrameMapper`.
- **Errores de datos**: elimina NA en objetivo antes de entrenar: `df.dropna(subset=['target'])`.
- **Rutas**: siempre `/dbfs/...` en código; para Spark, puedes usar rutas DBFS montadas.
- **MLflow**: registra `rmse`, `mae`, `r2` y gráficos como artefactos.

## Integración con Azure ML
- Autenticación: `Workspace(subscription_id, resource_group, workspace_name)` con login de dispositivo.
- Tracking: `mlflow.set_tracking_uri(ws.get_mlflow_tracking_uri())` para sincronizar.
- Registro: `Model.register()` en el workspace; despliegue como servicio web para scoring en tiempo real.

## Ejemplo representativo (ver notebooks)
- `02 - Training and Evaluating Machine Learning Models/2.0 Train and Validate ML Model.ipynb`: usa `DataFrameMapper` + `GradientBoostingRegressor` y OHE en categóricas; entrena y registra con MLflow.
- `04 - Integrating Azure Databricks and Azure Machine Learning/`: patrones de conexión y despliegue con Azure ML.
- `03 - Managing Experiments and Models/`: gestión de experimentos y artefactos con MLflow.

## Comandos útiles en notebooks
- Instalar SDK: `%pip install azureml-sdk[databricks]`
- Preparar salida: `dbutils.fs.mkdirs('outputs')`; ruta modelo: `os.path.join('/dbfs', 'outputs', 'model.pkl')`

Si algo no está claro o falta (p.ej., comandos de build/tests fuera de notebooks), avísame y lo ampliamos según tu flujo.