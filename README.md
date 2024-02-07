Este repositorio contiene la resolución del challenge de Grandata efectuada en Febrero de 2024, de acuerdo a [estas consignas](./workspace/exercises/DE_Technical_challenge.pdf).

## Ejercicios

Para el Ejercicio 1 se replicó con Docker el entorno solicitado (ver más adelante) y se resolvió ejecutando una Jupyter notebook. El monto total a facturar por el servicio de SMS resultó ser **$ 391367**. Dicha [notebook](./workspace/exercises/Ej1.ipynb), el dataset con los 100 usuarios con mayor facturación y los histogramas se incluyen en la carpeta [exercises](./workspace/exercises/).

El Ejercicio 2, por cuestiones de espacio se respondió en [otro archivo](./workspace/exercises/Ej2.md) que se incluye en la misma carpeta.



## Entorno

Se levanta una aplicación de **Docker Compose** que permite replicar el entorno solicitado compuesta por 4 servicios corriendo un contenedor cada uno. La misma incluye:
- Tres servicios que forman el cluster de Spark con un nodo master y 2 nodos worker, con 1 core y 2 Gb cada uno. De acuerdo a la consigna se ejecuta **Spark la 2.3**.

    De cada uno se mapea el puerto en el que corre su UI (`8080`, `8081` y `8082`) con el correspondiente puerto del host de modo de poder acceder a ellas desde el host.

- Un servicio que cumple el rol de ***cliente***, es decir desde donde corre el ***driver*** y desde donde se ejecuta la aplicación (interactivamente o haciendo el ***submit***).

    De acuerdo a lo requerido, en él se instala **Python 3.6**, **PySpark 2.3.0** y Jupyter para poder levantar un servidor y poder ejecutar PySpark en notebooks. Por comodidad se incluye Jupyter Lab. Adicionalmene se instalan dependencias y paquetes de visualización. 

    Del container cliente se mapean los puertos `8888` y `4040` para tener acceso desde el host al server de Jupyter y a la UI de la Aplicación de Spark, respectivamente.

- Una red bridge que vincula los contenedores.

- Un volumen compartido por todos los servicios que, si bien no se comporta como tal porque no es un DFS, viene a cumplir el rol de HDFS. En él a su vez se monta el contenido del directorio `./workspace` del host, incluido en este repo.

Las dos imágenes que se crean están basadas en la [imagen oficial](https://hub.docker.com/_/openjdk) de docker de [openjdk:8-jre-slim](https://openjdk.org/), a su vez basada en una imágen liviana de debian y que incluye JRE 8.

A su vez, por comodidad (ver más adelante) se creó un [repositorio en dockerhub](https://hub.docker.com/repository/docker/tvillani/grandatachallenge/general) donde se encuentran disponibles las imágenes aquí utilizadas.

## Ejecución

**Requisitos** 
- [Docker Engine](https://docs.docker.com/engine/) (>= 20.10).
- [Docker Compose](https://docs.docker.com/compose/) (>= 2.5).


**0. Clonar el repo:**<br>
```
$ git clone https://github.com/tvillani22/grandata_challenge.git && cd grandata_challenge # HTTPS
$ git clone git@github.com:tvillani22/grandata_challenge.git && cd grandata_challenge # SSH
```


**1. Obtener las imágenes.**<br>
Una posibilidad es hacer el build localmente:
```
$ docker compose build
```
**NOTA:** El build lleva varios minutos porque la versión de Python requerida (3.6) ya no se encuentra en los repositorios standard de Debian ni en los PPA conocidos de otras distribuciones (eg deadsnakes) por lo que se instala desde fuente.

Una alternativa que lleva menos tiempo es hacer un pull al mencionado [repositorio en dockerhub]().
```
$ docker compose pull
```


**2. Levantado del docker compose:**<br>
```
$ docker compose up
```
Con `-d` puede correrse *detached* y no bloquea la terminal, pero lo interesante de correrlo *attached* es que se tiene acceso a los logs de los servicios.

Una vez que se inician los servicios y los workers reportan que se han registrado satisfactoriamente con el master, el cluster está listo para iniciar una sesión de Spark. Como verificación puede accederse en `localost:8080`, `localost:8081` y `localost:8082` a las UI de cada uno de los nodos.


**3. Ejecución de una App de ejemplo:**<br>

En el *working dir* del servicio *client* se incluye una carpeta `examples`, con dos archivos que tienen código para ejecutar aplicaciones triviales de Spark (calculan la cantidad de múltiplos de 5 entre 1 y el argumento). Pueden correrse de distintas formas:

- **Interactivo desde notebook**: en `localhost:8888` se accede al servidor de Jupyter y dentro de ese directorio se encuentra la notebook `example.ipynb` que sirve para evaluar este modo.

- **Interacitivo usando el PySpark shell**: se debe acceder a la terminal del contenedor donde corre el cliente y una vez allí iniciar el shell de PySpark.
```
$ docker exec -it client /bin/bash
$ pyspark --master spark://spark-master:7077  --name ExampleFromShell
```
    Allí se puede ejecutar código en modo REPL y luego con `exit()` se abandona el shell y con `exit` la consola del conteneder.

- **Con *Spark-submit***: también se debe acceder a la terminal del contenedor donde corre el cliente y una vez allí hacer el submit de la aplicación definida en archivo `example.py`.
```
$ docker exec -it client /bin/bash
$ /usr/local/bin/spark-submit --master spark://spark-master:7077 examples/example.py 300
```
    Conlcuida la aplicación, con `exit` se abandona la consola del conteneder.

En todos los casos, mientras la sesión está corriendo puede accederse a la UI de la Aplicación en `localhost:4040` que esta fowardeado desde el cliente, así como pueden verificarse los recursos asignados a la misma en las UI del master y los workers en los puertos citados.


**4. Ejecutar el Ejercicio 1**<br>

En Jupyter Lab, en el directorio `exercises` está disponible la notebook `Ej1.ipynb`. Ejecutándose en modo interactivo como se describió en el primer incido del paso anterior pueden ir reproduciéndose los pasos efectuados para resolver el Ejercicio 1.


**5. Detener el docker compose:**<br>

Una vez concluido puede detenerse el conjunto de servicios desde la misma terminal donde están ejecutándose (`ctrl` + `C`) o desde otra, lo cual tine el beneficio de incluir un _prune_ automático de los contenedores.
```
$ docker compose down
``````

***
***