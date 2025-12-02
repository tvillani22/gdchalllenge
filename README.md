Este repositorio contiene la resolución del challenge de Grandata efectuada en Febrero de 2024, de acuerdo a [estas consignas](./workspace/exercises/DE_Technical_challenge.pdf).

**UPDATE**: esta es la versión actualizada a Noviembre de 2025 (versión original en rama `v1`).

***

## Ejercicios

Para el Ejercicio 1 se replicó con Docker el entorno solicitado (ver más adelante) y se resolvió ejecutando una Jupyter notebook. El monto total a facturar por el servicio de SMS resultó ser **$ 391367**. Dicha [notebook](./workspace/exercises/Ej1.ipynb), el dataset con los 100 usuarios con mayor facturación y los histogramas se incluyen en la carpeta [exercises](./workspace/exercises/).

El Ejercicio 2, por cuestiones de espacio se respondió en [otro archivo](./workspace/exercises/Ej2.md) que se incluye en la misma carpeta.



## Entorno

Se levanta una aplicación de **Docker Compose** que permite replicar el entorno solicitado compuesta por 7 servicios[^1] corriendo un contenedor cada uno. La misma incluye:

- Tres servicios que forman el ***Spark cluster*** con un nodo *Master* y 2 nodos *Worker*, con 1 core y 2 Gb cada uno. De acuerdo a la consigna ejecut [**Spark 2.3**](https://downloads.apache.org/spark/docs/2.3.0/).

    De cada uno se mapea el puerto en el que corre su UI (`8080`, `8081` y `8082`) con el correspondiente puerto del host de modo de poder acceder a ellas desde el host.

- Un servicio que corre el *HistoryServer* de Spark, que permite acceder a los logs y la UI de las SparkApps en ejecucion, y sobre todo a las SparkApps ya finalizadas (que sin este server quedan inaccessibles).

    El el puerto expuesto por el webserver, `18080`, es reenviado al host. 

- Dos servicios que forman un mini cluster ***Hadoop Cluster***, con un *Hadoop NameNode* y un *Hadoop DataNode* para proveer el servicio de file system distribuido vía ***HDFS***. Por compatibilida con la versión de Spark requerida, ejecutan [**Hadoop 2.6.0**](https://hadoop.apache.org/docs/r2.6.0/).

    De ambos se mapea el puerto donde corre su UI: `50070` para el *NameNode* (análogo al `9870` en Hadoop 3) y `50075` para el *DataNode* (análogo al `9874` en Hadoop 3).

- Un servicio que cumple el rol de ***cliente***, es decir desde donde corre el ***driver*** y desde donde se ejecuta la aplicación (interactivamente o haciendo el ***submit***).

    De acuerdo a lo requerido, en él se instala **Python 3.6**, **PySpark 2.3.0** y *Jupyter* para poder levantar un servidor y poder ejecutar PySpark en notebooks. Por comodidad se incluye Jupyter Lab. Adicionalmene se instalan dependencias y paquetes de visualización. 

    Del container cliente se mapean los puertos `8888` y `4040` para tener acceso desde el host al server de Jupyter y a la UI de la SparkApp en ejecución, respectivamente.

- Una red bridge que vincula los contenedores.

- Tres volúmenes:
  - Uno donde se monta desde el host el directorio `./workspace` de este repo, de modo que los source datasets y los códigos a correr sean accesibles al servicio cliente y que al mismo tiempo permite dar persistencia a cualquier cambio efectuado durante la ejección.
  - Dos (uno para el *NameNode* y otro para el *DataNode*) que le dan persistencia al HDFS, donde se guarda el target dataset del ejercicio y tambien los logs de todas las SparkApps ejecutadas.

[^1]: **NOTA:** En el `compose` también se define un servicio llamado como *base* pero es simplemente por una cuestión de conveniencia a la hora de ejecutar los builds de forma consistente en relacion a la/s plataforma/s (ver mas adelante). El mismo esta *taggeado* de una forma tal que no se ejecuta con el resto.

Las imágenes que utilizan los servicios se crean a partir de una imagen *base* (`tvillani/gd:ubuntu-20.04-openjdk-8-jre`). La misma esta construida a su vez a partir de la imagen oficial de docker de Ubuntu, disponible en su [repositorio oficial en Dockerhub](https://hub.docker.com/_/ubuntu), a la que se le agrega la version 8 del Java JRE de [OpenJDK](https://openjdk.org/), necesaria para ejecutar la JVM sobre la que corre la version de Spark requerida.

A su vez, por comodidad (ver más adelante) se creó un [repositorio en dockerhub](https://hub.docker.com/repository/docker/tvillani/gd/general) donde se encuentran disponibles las imágenes aquí utilizadas.


## Ejecución

**Requisitos** 
- [Docker Engine](https://docs.docker.com/engine/) (>= 20.10).
- [Docker Compose](https://docs.docker.com/compose/) (>= 2.5).


**0. Clonar el repo:**<br>

**1. Obtención de las imágenes.** <br>

Puede hacerse el build local o descargarse del mencionado repositorio.

> **a. Build (opcional).** <br>
Si se desea, es posble hacer el build localmente, efectuando primero el build de la imagen base, y luego el resto que se construye sobre ella:
```
$ docker compose build base && docker compose build
```

> Por default esto lleva adelante el build de imágenes en la arquitectura nativa del host. Si se desea construir imagenes multi-plataforma, como se encuentran en el repo (ver mas adelante), simplemente debe adaptarse según lo deseado la primera linea del `compose` file.<br>
> **NOTA:** El build lleva varios minutos porque la versión de Python requerida (3.6) ya no se encuentra en los repositorios standard de `apt` ni en los PPA conocidos de otras distribuciones (eg deadsnakes) por lo que se instala desde fuente.

> **b. Pull.** <br>
Una alternativa que lleva menos tiempo es hacer un `pull` al mencionado [repositorio de dockerhub](https://hub.docker.com/repository/docker/tvillani/gd/general).
```
$ docker compose pull
```
> Como se dijo, ese repositorio contiene todas las imágenes necesarias para levantar este entorno, construidas tanto para plataformas `linux/amd64` como `linux/arm64` (por lo que pueden ser ejecutadas de forma nativa por la inmensa mayoría de las máquinas), y al momento del `pull` docker automáticamente descargará la versión compatible con la arqutectura del host.


**2. Levantado del compose:**<br>
```
$ docker compose up
```

Una vez que se inician los servicios y los *SparkWorkers* reportan que se han registrado satisfactoriamente con el *SparkMaster*, y el *HadoopDataNode* hace lo propio con el *HadoopNameNode* el cluster está listo para la ejecución. Como verificación puede accederse en `localost:8080`, `localost:8081`, `localost:8082` y `localost:18080` a las UI del *SparkMaster*, los *SparkWorkers* y el *SparkHistoryServer*, respecivamente. Análogamente, puede accederse en `localost:50070` y `localost:50075` a las UI del *NameNode* y *DataNode*, respectivamente; en la primera, a su vez, en la pestana *Utilities* puede inspeccionarse al contenido del HDFS, donde podrá verse el target dataset una vz que se cree, así como los archivos de los logs de spark que muestra en su UI el mencionado *HistoryServer*.


**3. Ejecución de una App de ejemplo:**<br>

En el *working dir* del servicio *client* se incluye una carpeta `examples`, con dos archivos que tienen código para ejecutar aplicaciones triviales de Spark (calculan la cantidad de múltiplos de 5 entre 1 y el argumento). Pueden correrse de distintas formas:

- **I. Interactivo desde notebook**: en `localhost:8888` se accede al servidor de *Jupyter* y dentro de ese directorio se encuentra la notebook `example.ipynb`, que sirve para evaluar este modo.


- **II. Interactivo usando el PySpark shell**: se debe acceder a la terminal del contenedor donde corre el cliente y una vez allí iniciar el shell de PySpark.
```
$ docker exec -it client bash
$ pyspark --master spark://spark-master:7077  --name ExampleFromShell
```
&emsp; &emsp; Allí se puede ejecutar el código de [examples/example.py](./workspace/examples/example.py) en modo REPL (luego `exit()` y `exit` para abandonar el shell y la terminal del conteneder, respectivamente).


- **III. Con *Spark-submit***: también se debe acceder a la terminal del contenedor donde corre el cliente y una vez allí hacer el *submit* de la SparkApp definida en archivo `example.py`.
```
$ docker exec -it client bash
$ /usr/local/bin/spark-submit --master spark://spark-master:7077 examples/example.py 300
```

Notar que en todos los casos:
- Mientras la SparkApp está corriendo puede accederse a su UI en `localhost:4040` que esta reenviado desde el container donde corre el cliente, así como también pueden inspeccionarse los recursos asignados a la misma en las UI del master y los workers en los puertos citados.
- Se especifican explicitamente el `SPARK_MASTER_HOST` y el `SPARK_MASTER_PORT`, pero es solo por claridad y no es estrictamente necesario porque esos parametros junto con otros (eg de logging) estan ya seteados en `spark-defaults.conf`.


**4. Ejecutar el Ejercicio 1**<br>

En *JupyterLab*, en el directorio `exercises` está disponible la notebook `Ej1.ipynb`. Ejecutándose en modo interactivo como se describió en el primer inciso del paso anterior pueden ir reproduciéndose los pasos efectuados para resolver el Ejercicio 1.


**5. Detención del compose:**<br>

Una vez concluido puede detenerse el entorno.
```
$ docker compose down
```

**6. Reinicio de entorno y validación de persistencia (opcional):**<br>

Si se desea reiniciar los servicios, puede correrse nuevamente `docker compose up` y, dado los volúmenes montados, puede verse que tanto los cambios en nuestro código (eg en la notebook `Ej1.ipynb`), como el dataset generado durante ejercicio y los logs de las SparkApps concluidas están disponibles. Los primeros gracias al volumen montado en el filesystem del contenedor que corre el *cliente*. Los dos restantes, debido a los volúmenes montados en las correspondientes paths del *NameNode* y *DataNode* (seteadas en `dfs.namenode.name.dir` y `dfs.datanode.data.dir`, respectivamente).

***
***