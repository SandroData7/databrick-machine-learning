# Working with data in Azure Databricks

**Technical Accomplishments:**
- viewing available tables
- loading table data in dataframes
- loading file/dbfs data in dataframes
- using spark for simple queries
- using spark to show the data and its structure
- using spark for complex queries
- using Databricks' `display` for custom visualisations

## Attach notebook to your cluster
Before executing any cells in the notebook, you need to attach it to your cluster. Make sure that the cluster is running.

In the notebook's toolbar, select the drop down arrow next to Detached, and then select your cluster under Attach to.

## About Spark DataFrames

Spark DataFrames are distributed collections of data, organized into rows and columns, similar to traditional SQL tables.

A DataFrame can be operated on using relational transformations, through the Spark SQL API, which is available in Scala, Java, Python, and R.

We will use Python in our notebook. 

We often refer to DataFrame variables using `df`.

## Loading data into dataframes

#### View available data

To check the data available in our Databricks environment we can use the `%sql` magic and query our tables:

```python
%sql

select * from nyc_taxi;
```


#### Reading data from our tables

Using Spark, we can read data into dataframes. 

It is important to note that spark has read/write support for a widely set of formats. 
It can use
* csv
* json
* parquet
* orc
* avro
* hive tables
* jdbc

We can read our data from the tables (since we already imported the initial csv as Databricks tables).

```python
df = spark.sql("SELECT * FROM nyc_taxi")
display(df)
```


#### Reading data from the DBFS

We can also read the data from the original files we've uploaded; or indeed from any other file available in the DBFS. 

The code is the same regardless of whether a file is local or in mounted remote storage that was mounted, thanks to DBFS mountpoints

```python
df = spark.read.csv('dbfs:/FileStore/tables/nyc_taxi.csv', header=True, inferSchema=True)
display(df)
```


#### DataFrame size

Use `count` to determine how many rows of data we have in a dataframe.

```python
df.count()
```


#### DataFrame structure

To get information about the schema associated with our dataframe we can use `printSchema`:

```python
df.printSchema
```

### show(..) vs display(..)
* `show(..)` is part of core spark - `display(..)` is specific to our notebooks.
* `show(..)` has parameters for truncating both columns and rows - `display(..)` does not.
* `show(..)` is a function of the `DataFrame`/`Dataset` class - `display(..)` works with a number of different objects.
* `display(..)` is more powerful - with it, you can...
  * Download the results as CSV
  * Render line charts, bar chart & other graphs, maps and more.
  * See up to 1000 records at a time.
  
For the most part, the difference between the two is going to come down to preference.

Remember, the `display` function is Databricks specific. It is not available in standard spark code.

## Querying dataframes

Once that spark has the data, we can manipulate it using spark SQL API.

We can easily use the spark SQL dsl to do joins, aggregations, filtering. 
We can change the data structure, add or drop columns, or change the column types.

We will use the python function we've already defined to convert Celsius degrees to Fahrenheit degrees.

```python
def celsiusToFahrenheit(source_temp=None):
    return(source_temp * (9.0/5.0)) + 32.0
  
celsiusToFahrenheit(27)
```


We will adapt it as a udf (user defined function) to make it usable with Spark's dataframes API.

And we will use it to enrich our source data.

```python
from pyspark.sql.functions import isnan, when, count, col
from pyspark.sql.types import *

udfCelsiusToFahrenheit = udf(lambda z: celsiusToFahrenheit(z), DoubleType())

display(df.filter(col('temperature').isNotNull()) \
  .withColumn("tempC", col("temperature").cast(DoubleType())) \
  .select(col("tempC"), udfCelsiusToFahrenheit(col("tempC")).alias("tempF")))
  
```


More complex SQL functions are available in spark: 

* grouping, sorting, limits, count
* aggregations: agg, max, sum
* windowing: partitionBy, count over, max over

For example may want to add a row-number column to our source data. Window functions will help with such complex queries:

```python
from pyspark.sql.window import Window
from pyspark.sql.functions import desc, row_number, monotonically_increasing_id

display(df.orderBy('tripDistance', ascending=False) \
  .withColumn('rowno', row_number().over(Window.orderBy(monotonically_increasing_id()))))
```


#### Data cleaning

Before using the source data, we have to validate the contents. Let's see if there are any duplicates:

```python
df.count() - df.dropDuplicates().count()
```


Some columns might be missing. We check the presence of null values for each column.

```python
display(df.select([count(when(col(c).isNull(), c)).alias(c) for c in df.columns]))
```


Since some of our columns seem to have such null values, we'll have to fix these rows.

We could either replace null values using `fillna` or ignore such rows using `dropna`

```python
df = df.fillna({'passengerCount':'1'}).dropna()
display(df)
```


#### Explore Summary Statistics and Data Distribution
Predictive modeling is based on statistics and probability, so we should take a look at the summary statistics for the columns in our data. The **describe** function returns a dataframe containing the **count**, **mean**, **standard deviation**, **minimum**, and **maximum** values for each numeric column.

```python
display(df.describe())

```


## Visualizing data

Azure Databricks has custom support for displaying data. 

The `display(..)` command has multiple capabilities:
* Presents up to 1000 records.
* Exporting data as CSV.
* Rendering a multitude of different graphs.
* Rendering geo-located data on a world map.

Let's take a look at our data using databricks visualizations:
* Run the cell below
* click on the second icon underneath the executed cell and choose `Bar`
* click on the `Plot Options` button to configure the graph
  * drag the `tripDistance` into the `Keys` list
  * drag the `totalAmount` into the `Values` list
  * choose `Aggregation` as `AVG`
  * click `Apply`

```python
dfClean = df.select(col("tripDistance"), col("totalAmount")).dropna()

display(dfClean)
```


Note that the points form a diagonal line, which indicates a strong linear relationship between the trip distance and the total amount. This linear relationship shows a correlation between these two values, which we can measure statistically. 

The `corr` function calculates a correlation value between -1 and 1, indicating the strength of correlation between two fields. A strong positive correlation (near 1) indicates that high values for one column are often found with high values for the other, which a strong negative correlation (near -1) indicates that low values for one column are often found with high values for the other. A correlation near 0 indicates little apparent relationship between the fields.

```python
dfClean.corr('tripDistance', 'totalAmount')
```


Predictive modeling is largely based on statistical relationships between fields in the data. To design a good model, you need to understand how the data points relate to one another.

A common way to start exploring relationships is to create visualizations that compare two or more data values. For example, modify the Plot Options of the chart above to compare the arrival delays for each carrier:

* Keys: temperature
* Series Groupings: month_num
* Values: snowDeprh
* Aggregation: avg
* Display Type: Line Chart

```python
display(df)
```


The plot now shows the relation between the month, the snow amount and the recorded temperature.