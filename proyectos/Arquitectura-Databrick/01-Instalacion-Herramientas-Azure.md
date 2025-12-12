# Laboratorio 01: Instalación de Herramientas y Conexión a Azure

## Introducción

En este laboratorio, aprenderemos a instalar y configurar las herramientas necesarias para trabajar con Azure Databricks y Azure Cloud. Las herramientas incluyen Azure CLI, Databricks CLI y Azure Storage Explorer. Una vez instaladas, configuraremos la conexión a tu suscripción de Azure.

## Requisitos Previos

- Una cuenta de Azure con una suscripción activa.
- Un sistema operativo compatible (Windows, macOS o Linux).
- Acceso a internet para descargar las herramientas.

## Paso 1: Instalación de Azure CLI

Azure CLI es una herramienta de línea de comandos para gestionar recursos de Azure.

### En Windows (usando PowerShell o CMD):

1. Descarga el instalador desde [https://aka.ms/installazurecliwindows](https://aka.ms/installazurecliwindows).
2. Ejecuta el instalador y sigue las instrucciones.
3. Verifica la instalación:
   ```bash
   az --version
   ```

### En macOS (usando Homebrew):

1. Instala Homebrew si no lo tienes:
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. Instala Azure CLI:
   ```bash
   brew update && brew install azure-cli
   ```
3. Verifica:
   ```bash
   az --version
   ```

### En Linux (Ubuntu/Debian):

1. Actualiza el índice de paquetes:
   ```bash
   sudo apt-get update
   ```
2. Instala Azure CLI:
   ```bash
   curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
   ```
3. Verifica:
   ```bash
   az --version
   ```

## Paso 2: Instalación de Databricks CLI

Databricks CLI permite interactuar con Databricks desde la línea de comandos.

### Instalación:

1. Asegúrate de tener Python instalado (versión 3.6 o superior).
2. Instala Databricks CLI usando pip:
   ```bash
   pip install databricks-cli
   ```
3. Verifica la instalación:
   ```bash
   databricks --version
   ```

Nota: Si usas entornos virtuales, activa el entorno antes de instalar.

## Paso 3: Instalación de Azure Storage Explorer

Azure Storage Explorer es una herramienta gráfica para gestionar almacenamiento en Azure.

### Instalación:

1. Descarga el instalador desde [https://azure.microsoft.com/en-us/features/storage-explorer/](https://azure.microsoft.com/en-us/features/storage-explorer/).
2. Ejecuta el instalador y sigue las instrucciones para tu sistema operativo (Windows, macOS o Linux).
3. Abre la aplicación y verifica que se inicie correctamente.

## Paso 4: Conexión a la Suscripción de Azure

Una vez instaladas las herramientas, configura la conexión a tu suscripción de Azure.

### Usando Azure CLI:

1. Inicia sesión en Azure:
   ```bash
   az login
   ```
   Esto abrirá una ventana del navegador para autenticarte. Si no puedes usar el navegador, usa:
   ```bash
   az login --use-device-code
   ```

2. Selecciona tu suscripción (si tienes varias):
   ```bash
   az account set --subscription "Tu-Suscripción-ID"
   ```
   Reemplaza "Tu-Suscripción-ID" con el ID de tu suscripción.

3. Verifica la conexión:
   ```bash
   az account show
   ```

### Configuración de Databricks CLI:

1. Obtén un token de acceso personal de Databricks:
   - Ve a tu workspace de Databricks.
   - Ve a Settings > User > Developer > Access Tokens > Generate New Token.

2. Configura Databricks CLI:
   ```bash
   databricks configure --token
   ```
   - Host: https://<tu-region>.azuredatabricks.net (ej. https://eastus.azuredatabricks.net)
   - Token: Pega el token generado.

3. Verifica:
   ```bash
   databricks workspace ls
   ```

### Conexión en Azure Storage Explorer:

1. Abre Azure Storage Explorer.
2. Haz clic en "Add Account" > "Add an Azure Account".
3. Selecciona "Azure" y sigue las instrucciones para iniciar sesión con tu cuenta de Azure.
4. Una vez conectado, podrás explorar tus recursos de almacenamiento.

## Conclusión

Ahora tienes instaladas y configuradas las herramientas esenciales para trabajar con Azure Databricks. En el próximo laboratorio, exploraremos la creación de un workspace de Databricks.

## Referencias

- [Documentación de Azure CLI](https://docs.microsoft.com/en-us/cli/azure/)
- [Documentación de Databricks CLI](https://docs.databricks.com/dev-tools/cli/index.html)
- [Azure Storage Explorer](https://docs.microsoft.com/en-us/azure/vs-azure-tools-storage-manage-with-storage-explorer)