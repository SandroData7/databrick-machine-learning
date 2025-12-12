# Guía para Agentes de Código – Databricks ML

Repo de formación práctica en Azure Databricks para ML con PySpark, MLflow, Azure ML y deep learning distribuido. Todo el trabajo se realiza en notebooks Jupyter conectados a clusters Databricks.

## Estructura del proyecto
```
notebooks/topics/ml-databricks/
├── ypnb/              # Notebooks completos (.ipynb)
│   ├── 01 - Introduction to Azure Databricks/
│   ├── 02 - Training and Evaluating Machine Learning Models/
│   ├── 03 - Managing Experiments and Models/
│   ├── 04 - Integrating Azure Databricks and Azure Machine Learning/
│   ├── 05 - Hyperparameter Tuning/
│   └── 06 - Distributed Deep Learning/
├── Train-alumnos/     # Versiones de ejercicios para estudiantes
├── dbc/               # Databricks archives (.dbc)
└── markdown/          # Versión markdown de notebooks
data/
├── retail-data/by-day/   # ~100 CSV de retail (2010-12-01.csv...)
├── DE-05/                # customers.csv, products.csv, sales.csv
└── *.csv                 # Varios datasets (flights, penguins, etc.)
proyectos/Arquitectura-Databrick/  # Docs de setup Azure
```

## Workflows clave

### 1. Entrenamiento ML con PySpark y MLflow
**Patrón canónico** en `02/2.0 Train and Validate ML Model.ipynb`:
```python
# 1. Cargar datos desde Spark table o DBFS
dataset = spark.sql("select * from nyc_taxi")

# 2. Feature engineering con UDFs para cyclical features
from pyspark.sql.functions import col, lit, udf
get_sin_cosineUDF = udf(get_sin_cosine, schema)
dataset = dataset.withColumn("udfResult", get_sin_cosineUDF(col("hour_of_day"), lit(24)))

# 3. Pipeline de featurización con stages separados
from pyspark.ml.feature import Imputer, VectorAssembler, MinMaxScaler, StringIndexer, OneHotEncoder
from pyspark.ml import Pipeline

stages = []
# Numéricas: Imputer → VectorAssembler → MinMaxScaler
imputer = Imputer(strategy="median", inputCols=["passengerCount"], outputCols=["passengerCount"])
stages += [imputer]
assembler = VectorAssembler(inputCols=numerical_cols, outputCol='numerical_features')
scaler = MinMaxScaler(inputCol='numerical_features', outputCol="scaled_numerical_features")
stages += [assembler, scaler]

# Categóricas: StringIndexer → OneHotEncoder
for col in categorical_cols:
    stringIndexer = StringIndexer(inputCol=col, outputCol=col+"_index", handleInvalid="skip")
    encoder = OneHotEncoder(inputCols=[stringIndexer.getOutputCol()], 
                            outputCols=[col+"_classVector"])
    stages += [stringIndexer, encoder]

# 4. Combinar features y entrenar
assembler = VectorAssembler(inputCols=assemblerInputs, outputCol="features")
stages += [assembler]
partialPipeline = Pipeline().setStages(stages)
preppedDataDF = partialPipeline.fit(dataset).transform(dataset)

# 5. Train/test split y modelo
(trainingData, testData) = preppedDataDF.randomSplit([0.7, 0.3], seed=97)
lr = LinearRegression(featuresCol="features", labelCol=label_column)
lrModel = lr.fit(trainingData)
```

### 2. Tracking con MLflow (patrón en `03/01 - Using MLflow to Track Experiments.ipynb`)
```python
import mlflow
import mlflow.spark

# Siempre usar context manager
with mlflow.start_run():
    lrModel = lr.fit(train_data)
    predictions = lrModel.transform(test_data)
    
    # Log params, metrics, artifacts
    mlflow.log_param("elastic_net_param", elastic_net_param)
    mlflow.log_metric("rmse", rmse)
    mlflow.spark.log_model(lrModel, "model")
    
    # Guardar modelo local en DBFS
    modelpath = "/dbfs/mlflow/taxi_total_amount/model-{}-{}-{}".format(...)
    mlflow.spark.save_model(lrModel, modelpath)
    
    # Artifacts (gráficos)
    fig.savefig("LinearRegressionPrediction.png")
    mlflow.log_artifact("LinearRegressionPrediction.png")
```
**Comandos útiles en notebook**: `%fs rm -r dbfs:/mlflow/taxi_total_amount` para limpiar runs anteriores.

### 3. Integración Azure ML (en `04/2.0 Deploying Models in Azure Machine Learning.ipynb`)
**Setup**:
```python
from azureml.core import Workspace
subscription_id = "XXX-XXXX-XXXX-XXXX"
resource_group = "XXX"
workspace_name = "aml-ws"
ws = Workspace(subscription_id, resource_group, workspace_name)  # Device login prompt

# Conectar MLflow a Azure ML
import mlflow
mlflow.set_tracking_uri(ws.get_mlflow_tracking_uri())
mlflow.set_experiment('MLflow-AML-Exercise')
```

**Deployment**:
```python
# 1. Entrenar y guardar modelo
output_folder = 'outputs'
dbutils.fs.mkdirs(output_folder)
model_file_path = os.path.join('/dbfs', output_folder, 'nyc-taxi.pkl')
# ... entrenar modelo sklearn/GradientBoostingRegressor con Pipeline ...
joblib.dump(pipeline, open(model_file_path, 'wb'))

# 2. Registrar en Azure ML
from azureml.core.model import Model
registered_model = Model.register(workspace=ws, model_path=model_file_path, 
                                   model_name='nyc-taxi-fare-predictor')

# 3. Crear scoring script (score.py) en /dbfs/outputs/
# 4. Deployment environment con conda dependencies
from azureml.core import Environment
myenv = Environment.get(workspace=ws, name='AzureML-Minimal').clone('nyc-taxi-env')
# ... add pip packages: sklearn, pandas, joblib, sklearn-pandas ...

# 5. Deploy a ACI
from azureml.core.webservice import AciWebservice
aci_config = AciWebservice.deploy_configuration(cpu_cores=3, memory_gb=15, 
                                                  auth_enabled=True, location='eastus')
service = Model.deploy(workspace=ws, name='nyc-taxi-service', models=[registered_model],
                       inference_config=inference_config, deployment_config=aci_config)
service.wait_for_deployment(show_output=True)  # 10-15 min
```

### 4. Hyperparameter tuning (en `05/`)
- **MLflow autolog**: `mlflow.sklearn.autolog()` antes de entrenar registra todo automáticamente
- **Hyperopt** (en `2.0 Hyperparameter tuning with Hyperopt.ipynb`): usa `fmin()` con `SparkTrials` para paralelización en cluster

### 5. Deep Learning distribuido con Horovod (en `06/1.0 Distributed Deep Learning with Horovod.ipynb`)
**Setup**:
```python
PYTORCH_DIR = '/dbfs/ml/horovod_pytorch'  # Checkpoints bajo /dbfs/ml/
import horovod.torch as hvd
from sparkdl import HorovodRunner
```

**Patrón de migración**:
1. Código single-node normal con PyTorch
2. Wrap en función `train_hvd(learning_rate)` con hooks Horovod:
```python
def train_hvd(learning_rate):
    hvd.init()  # Setup comunicación entre workers
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    if device.type == 'cuda':
        torch.cuda.set_device(hvd.local_rank())  # Pin GPU a rank local
    
    # DataLoader con DistributedSampler
    train_sampler = torch.utils.data.distributed.DistributedSampler(
        train_dataset, num_replicas=hvd.size(), rank=hvd.rank())
    train_loader = torch.utils.data.DataLoader(train_dataset, 
                                                batch_size=batch_size,
                                                sampler=train_sampler)
    
    # Wrap optimizer con DistributedOptimizer
    optimizer = optim.SGD(model.parameters(), lr=learning_rate * hvd.size(), momentum=0.5)
    optimizer = hvd.DistributedOptimizer(optimizer, named_parameters=model.named_parameters())
    
    # Broadcast params para que todos los workers empiecen igual
    hvd.broadcast_parameters(model.state_dict(), root_rank=0)
    
    # Guardar checkpoints sólo en worker 0
    if hvd.rank() == 0:
        save_checkpoint(log_dir, model, optimizer, epoch)
```
3. Ejecutar con HorovodRunner:
```python
hr = HorovodRunner(np=2)  # np = número de workers (np=-1 usa driver)
hr.run(train_hvd, learning_rate=0.001)
```

## Convenciones técnicas críticas

### Rutas y DBFS
- **Desde Python**: `/dbfs/path` (filesystem local en driver/workers)
- **Desde Spark**: `dbfs:/path` o `/path` si está montado
- **Guardar outputs**: siempre bajo `/dbfs/outputs/` o `/dbfs/ml/`
- **Autenticación moderna**: usar **Access Connector for Azure Databricks** con Azure Managed Identity (reemplaza Service Principal obsoleto)
  - Crear Access Connector en Azure Portal: "Databricks Access Connectors"
  - Asignar rol "Storage Blob Data Contributor" a la Managed Identity
  - En Unity Catalog: crear Storage Credential tipo "Azure Managed Identity" con Access Connector ID
  - Crear External Locations usando el credential (ej: `abfss://container@storage.dfs.core.windows.net/`)
- **Montaje tradicional** (legacy, para clusters sin Unity Catalog): `dbutils.fs.mount(source="wasbs://...", mount_point="/mnt/data", extra_configs={...})`

### Featurización estándar
- **Numéricas**: `Imputer(strategy='median')` → `StandardScaler` o `MinMaxScaler`
- **Categóricas**: `StringIndexer(handleInvalid='skip')` → `OneHotEncoder(handle_unknown='ignore', sparse=False)`
- **Features cíclicas** (hora, día): convertir a sin/cos con UDF
- **Limpieza previa**: `dataset.filter(dataset.target.isNotNull())` o `dropna(subset=['target'])`

### Métricas de evaluación
```python
from pyspark.ml.evaluation import RegressionEvaluator
evaluator = RegressionEvaluator(labelCol=label_column, predictionCol="prediction", 
                                 metricName="rmse")  # o "mae", "r2"
rmse = evaluator.evaluate(predictions)
```
Siempre log `rmse`, `mae`, `r2` en MLflow.

### Dependencias clave
- **Azure ML**: `%pip install azureml-sdk[databricks] azureml-mlflow sklearn-pandas==2.1.0`
- **ML runtime** recomendado: Databricks Runtime 7.0 ML o superior
- **Horovod**: incluido en ML runtime; requiere múltiples workers para aprovechar distribución

## Errores comunes y soluciones
- **"Table not found"**: verificar con `spark.sql("SHOW TABLES")` o cargar desde DBFS path completo
- **Import conflicts**: al usar Azure ML SDK, asegurar versiones compatibles de sklearn/pandas
- **Horovod "No slots available"**: cluster necesita >1 worker; usar `np=-1` para test local en driver
- **MLflow tracking falla**: verificar `mlflow.set_tracking_uri()` apunta al workspace correcto

## Recursos adicionales
- **Setup Azure**: ver `proyectos/Arquitectura-Databrick/01-Instalacion-Herramientas-Azure.md` para conexión con Databricks CLI y tokens
- **Data Lake setup**: `02-Creacion-DataLake-Azure.md` para configurar ADLS Gen2 con capas Bronze/Silver/Gold
- **Train-alumnos**: versiones con placeholders "TO-DO" para ejercicios guiados