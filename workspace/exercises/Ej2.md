
# Ejercicio 2

&emsp; &emsp; 

## Respuesta 1

La priorización de los procesos productivos por sobre los de análisis exploratorios puede implementarse a distintos niveles:

I) **A nivel del cluster manager**, para lo cual debería utilizarse un deploy de *Spark on YARN*, en cuyo caso podrían utilizarse las herramientas de scheduling que el mismo YARN ofrece. Dependiendo del punto del *tradeoff* entre disponibilidad inmediata de recursos y optimización en el uso de esos recursos se decida estar, se puede elegir entre el *Capacity* y el *FAIR* scheduler. 
  - Una primera posibilidad es utilizar el *FAIR* scheduler creando dos queues/colas (una para los procesos productivos y otra para los análisis exploratorios) y asignarles distintos pesos relativos que reflejen al magnitud de esa priorizacion. Este scheduler tiene el beneficio de optimizar el uso del cluster, ya que los recursos no utilizados se distribuyen entre las aplicaciones en ejecución en el cluster, pero ello viene con el costo de no tener disponibilidad de recursos inmediata para la tarea prioritaria.
  - Si se quiere hacer una priorización más fuerte, e incluso garantizar una asignación de recursos específica para un cierto grupo de procesos, debe usarse el *Capacity* scheduler. También permite crear queues (y una jerarquía de subqueues) a las que asignar cada grupo de procesos, pero en este caso permite asignarles de forma garantizada una proporción de recursos mínimos del total (y también máximos, en caso de que se desee permitir cierta *elasticidad* si hay recursos libres). Siendo restrictivo al momento de configurar los recursos máximos de la queue donde corren los procesos exploratorios, puede garantizarse una data dotación de recursos mínimos de disponibilidad inmediata para la queue donde corren los procesos productivos prioritaros.

Por default ambos schedulers basan sus algoritmos de asignación de recursos tomando la memoria como parámetro de decisión. Pero, si los procesos poseen un uso intensivo tanto de CPU como de memoria, es posible optar por el *DRF*, un algoritmo, disponible para ambos schedulers, que considera tanto los requerimientos de memoria como de CPU y decide para cada proceso en función de su recurso *dominante* (ie su requermiento más restrictivo).

Con respecto a tener la seguridad de contar con recursos disponibles para ejecuciones de procesos prioritarios en ciertos momentos del día, puede utilizarse el *Reservation System* de YARN, una herramienta, también compatible con ambos schedulers, que permite que los mismos garanticen recursos disponibles en una dada ventana de tiempo prestablecida.

Si se trata de un deploy de *Spark StandAlone* (con los nodos Hadoop proveyendo HDFS), el *SparkMaster* actuando como cluster manager solo ofrece scheduling *FIFO*, que no permite asignar prioridades, por lo que no se puede hacer asignación de recursos a este nivel y debe necesariamente implementarse a nivel de las SparkApplications (ver siguiente párrafo).


II) **A nivel de la SparkApplication**, dado que al momento de crear una es posible configurar una asignación de recursos *estática* para la misma. Así, un scheduling simple podría hacerse ejectuando los procesos exploratorios no productivos en una "long-lived" SparkApp, limitando los recursos (memoria y CPU) que esta puede tomar del cluster, y dejando que todos los procesos productivos que corran en otra/s SparkApp/s tengan garantizados todos los recursos remanentes del cluster. Es obviamente un scheduling menos sofisticado que los mencionados previamente, pero útil en casos en que YARN no forme parte del deploy.

***

## Respuesta 2

Tratándose de un *Data Lake*, para que la tabla soporte alta transaccionalidad debería emplear de una arquitectura tipo *Data Lakehouse*, es decir, incluir una capa de abstracción por encima (eg *delta*) que garantice que las transacciones sean ACID y evite las inconsistencias que resultan en su ausencia (eg los corrupt files en parquet). Con este esquema, las lecturas no deberían tener problemas de concurrencia, por lo que las posibles causas y recomendaciones a considerar son:

- A nivel de storage layout y el file management:
  - File format: usar un format adecuado (particionable, optimizado para IO, con algoritmos rápidos de compresión, con metadata estadística y posiblemente columnar para optimizar la data skipping y el columm prunning).
  - Particionar de forma adecuada para permitir el predicate pushdown, pero no más de lo necesario (ya que cuando no se usa en el skipping ello implica in overhead en IO). Hacerlo en columnas con baja cardinalidad (o si se requiere hacerlo por una con alta combinarlo con ZORDER o usar drectamente Liquid clustering si está disponible), para evitar el "small files problem" y toda la sobrecarga de IO que trae asociada.
  - Hacer un *file maintenance* con compactaciones, remoción de archivos no referenciados, optimización en la escritura de particiones y recálculo de metadata (automatizado al momento de escritura si disponible; si no, con cierta frecuencia), también para evitar el "small files problem".

- Si el problema ocurre particularmente al hacer JOINs con la tabla, analizar:
  - La posibilidad de particionar por el/los campo/s usado/s para el JOIN, de modo de permitir que tenga efecto el *partition pruning* de Spark.
  - Si la distribución de los valores de el/los campo/s usado/s para el JOIN es muy asimátrica y puede afectar los shuffleJoins, verificar que la AQE de Spark esté resolviendo esos cuellos de botella.
  - Si un dado JOIN tiene alta frecuencia y se trata de un shuffleJoin considerar posibilidad de usar *bucketing* por el/los campo/s de ese JOIN en el paso anterior para omitir los shuffles que él implica.

Notar que otra sería la situación si se tratase de un *Data Warehouse*, ya que el control de concurrencia en ellos suele ser pesimista (ie usando locks) y dependiendo del tipo de warehouse las lecturas también pueden verse afectados por esos locks. En ese caso se pueden implementar opciones del lado de la escritura (para reducir las transacciones frente a la tabla al mínimo tiempo posible) y del lado de la lectura (eg materializando la data en una tabla anexa para los casos de analitica que no necesitar el nivel de actualización que requieren los procesos transaccionales).

***

## Respuesta 3

Dado que se requiere un proceso que utilice exactamente la mitad de los recursos del cluster, y deje disponible la otra mitad, se requiere una asgnación *estática* de recursos. Como se menciono en la Respuesta 1, tal distribución puede hacerse a nivel de cluster con el *Capacity scheduler* de YARN. Sin embargo, como la pregunta menciona específicamente las *"configuraciones en la sesión de Spark a implementar"*, debe considerarse la otra alternativa mencionada en la Respuesta 1, que es hacerlo a nivel de las SparkApplications.

Con respecto a los seteos a definir, se debe asegurar que `spark.dynamicAllocation.enabled` sea `false` (default) y se deben limitar los recursos que se asignarán a la SparkApplication que ejecutará los "procesos tempranos" al momento del submit. Para ello se debe configurar el número de executors con `spark.executor.instances`, el número de cores por executor con `spark.executor.cores` y la memoria a asignar a cada executor con `spark.executor.memory`.

Dado que se debe emplear el 50% de los recursos, se tienen en principio ~ 18 cores y 75 GB. Dejando un core y 3 GB libres por nodo, para que corran lo daemons del YARN node manager y lo propio del nodo (eg OS), puede plantearse una asignación de 3 executors, con 5 cores y 20 GB cada uno. Alternativamente, para obtener más paralelismo (pero a expensas de memoria y CPU), puede proponerse 5 executors con 3 cores y unos 12 GB cada uno.