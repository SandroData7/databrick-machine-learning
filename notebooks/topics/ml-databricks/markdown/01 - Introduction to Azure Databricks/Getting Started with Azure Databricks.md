# Getting Started with Azure Databricks

**Technical Accomplishments:**
- Set the stage for learning on the Databricks platform
- Create the cluster
- Discover the workspace, import table data
- Demonstrate how to develop & execute code within a notebook
- Review the various "Magic Commands"
- Introduce the Databricks File System (DBFS)

## Attach notebook to your cluster
Before executing any cells in the notebook, you need to attach it to your cluster. Make sure that the cluster is running.

In the notebook's toolbar, select the drop down arrow next to Detached, and then select your cluster under Attach to.

## Working with notebooks

A notebook is a web-based interface to a document that contains 
* runnable code
* visualizations
* descriptive text

To create a notebook, click on `Workspace`, browse into the desired folder, right click and choose `Create` then select `Notebook`.

A notebook contains multiple cells. Each cell has a specific type. 

A default programming language is configured when creating the notebook and it will be implicitly used for new cells.

#### Magic commands

We can override the cell's default programming language by using one of the following *magic commands* at the start of the cell:

* `%python` for cells running python code
* `%scala` for cells running scala code
* `%r` for cells running R code
* `%sql` for cells running sql code
  
Additional magic commands are available:

* `%md` for descriptive cells using markdown
* `%sh` for cells running shell commands
* `%run` for cells running code defined in a separate notebook
* `%fs` for cells running code that uses `dbutils` commands
  

To run a cell use one of the following options:
  * **CTRL+ENTER** or **CMD+RETURN**
  * **SHIFT+ENTER** or **SHIFT+RETURN** to run the cell and move to the next one
  * Using **Run Cell**, **Run All Above** or **Run All Below** as seen here<br/><img style="box-shadow: 5px 5px 5px 0px rgba(0,0,0,0.25); border: 1px solid rgba(0,0,0,0.25);" src="https://files.training.databricks.com/images/notebook-cell-run-cmd.png"/>

```python
#assuming the default language for a notebook was set to Python
print("I'm running Python!")
```


Below we use a simple python function to convert Celsius degrees to Fahrenheit degrees.

```python
%python

#convert celsius to fahrenheit
def celsiusToFahrenheit(source_temp=None):
    return(source_temp * (9.0/5.0)) + 32.0    
        
#input values - celsius
a = [1, 2, 3, 4, 5]
print(a)

#convert all
b = map(lambda x: celsiusToFahrenheit(x), a)
print(list(b))
```

##![Spark Logo Tiny](https://files.training.databricks.com/images/wiki-book/general/logo_spark_tiny.png) Databricks File System - DBFS

We've already imported data into Databricks by uploading our files.

Databricks is capable of mounting external/remote datasources as well.

DBFS allows you to mount storage objects so that you can seamlessly access data without requiring credentials.
Allows you to interact with object storage using directory and file semantics instead of storage URLs.
Persists files to object storage, so you won’t lose data after you terminate a cluster.

* DBFS is a layer over a cloud-based object store
* Files in DBFS are persisted to the object store
* The lifetime of files in the DBFS are **NOT** tied to the lifetime of our cluster

See also <a href="https://docs.azuredatabricks.net/user-guide/dbfs-databricks-file-system.html" target="_blank">Databricks File System - DBFS</a>.
### Databricks Utilities - dbutils
* You can access the DBFS through the Databricks Utilities class (and other file IO routines).
* An instance of DBUtils is already declared for us as `dbutils`.

The `mount` command allows to use remote storage as if it were a local folder available in the Databricks workspace

```
dbutils.fs.mount(
  source = f"wasbs://dev@{data_storage_account_name}.blob.core.windows.net",
  mount_point = data_mount_point,
  extra_configs = {f"fs.azure.account.key.{data_storage_account_name}.blob.core.windows.net": data_storage_account_key})
```

To show available DBFS mounts:

```python
%fs 
mounts
```


To show available tables:

```python
%fs
ls /FileStore/tables
```

Additional help is available via `dbutils.help()` and for each sub-utility: `dbutils.fs.help()`, `dbutils.meta.help()`, `dbutils.notebook.help()`, `dbutils.widgets.help()`.

See also <a href="https://docs.azuredatabricks.net/user-guide/dbutils.html" target="_blank">Databricks Utilities - dbutils</a>

```python
dbutils.fs.help()
```
