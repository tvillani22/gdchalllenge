
# Ejercicio 2

**NOTA**: En todos los casos se considera el uso de _Standalone_ como cluster manager.

## Respuesta 1

**Si los procesos productivos y los análisis exploratorios no comparten la misma sesión de Spark, se pueden repartir estáticamente recursos entre las sesiones, priorizando los primeros a través de una mayor asignación (un escenario similar se describe en la respuesta 3). Asumiendo en cambio que todos los procesos son parte de la misma sesión, para administrar la ejecución y priorizar los procesos productivos se deberían utilizar las herramientas de _scheduling_ dentro de una misma aplicación que ofrece Spark.**

**Dentro de una sesión por defecto Spark asigna recursos a los jobs en modo _FIFO_ (primero entra, primero sale), que no permite asignar prioridades por lo cual no es indicado en esta situación. Además, tampoco es el modo ideal cuando se tienen varios jobs corriendo al mismo tiempo y algunos de ellos son muy pesados, dado que penaliza a los más livianos que necesariamente quedarán en cola esperando que concluyan aquellos.**

**Sin embargo, Spark también ofrece la posibilidad de configurar el scheduler en modo _FAIR_ (a través del parámetro `spark.scheduler.mode`). Con ello, se implementa una asignación de recursos tipo _round-robin_, lo cual implica que todos los jobs reciben parte de los recursos y, aún con jobs productivos pesados corriendo, el resto no quedarán bloqueados. Pero más relevante aún para este escenario, el modo _FAIR_ permite establecer prioridades en el uso de los recuros por medio de la creación de _pools_. Cada pool agrupa los jobs de uno o más threads que a él se han asignado (seteando la local property `spark.scheduler.pool`) y, a cada pool, se le puede establecer un _weight_ que determina la prioridad relativa de los jobs de ese pool respecto a los demás. Así, agrupando los jobs de procesos productivos y los de desarrollo en distintos pools y asignando distintos pesos a cada uno se puede establecer la prioridad deseada.**

**A su vez, el scheduler funcionando en modo _FAIR_ permite otros seteos para ajustar más finamente: por un lado la posibilidad de establecer una proporción mínima de recursos que un pool debe recibir (parámetro `minShare`) de modo que aún si no tiene alta prioridad no quede bloqueado en cola; por otro, la posibilidad de establecer un modo _FAIR_ dentro del propio pool de modo de, pagando el "precio" de que jobs pesados demoren un poco más, poder garantizar que no se bloqueen completamente el resto de los jobs del pool.**

***

## Respuesta 2

**Asumiendo que la conectividad disponible para el DFS es la adecuada, probablemente el problema sea que la data no está guardada de forma óptima para tener una alta transaccoinalidad, en términos de formato y particionado.**

**Respecto al primer punto, es necesario que se utilice un formato particionable (ver más abajo) y que esté optimizado para IO. Parquet por ejemplo, además de incorporar un algoritmo veloz de compresión cuenta con una serie de características (distribución columnar, metadata estadística) que le permiten, aun en ausencia de particionado, evitar traer a memoria data no deseada (usando _column pruning_ y filtrado de bloques por metadata). Así, el formato en sí mismo ya tiene una fuerte incidencia en los tiempos de respuesta.**

**Sin embargo, dado que la adopción del formato no tiene mayor complejidad, el principal punto a considerar habitualmente es el particionado. En términos generales, la idea se basa en dividir la data en bloques o particiones de forma de poder a) ejecutar transformaciones en ellas en paralelo, b) minimizar shuffles y c), en el caso particular del guardado a disco, poder almacenar la data de forma tal que pueda ser filtrada lo más posible al momento de la lectura. Dependiendo del objetivo principal, el particionado puede hacerse basándose en columna/s o especificando un número de particiones.**

**Considerando la lectura, dado que habitualmente las tablas son filtradas antes de efectuar transformaciones, para reducir los tiempos de lectura debe particionarse por columna/s. En particular debe utilizarse una (o más) columna que se use frecuentemente para filtrar, dado que ello permitirá llevar ese filtrado al momento mismo de la lectura (_predicate pushdown_) evitando llevar a memoria data no deseada; un ejemplo típico es particionar por una columa de fecha que habitualmente se usa para filtrar en ejecuciones incrementales. A su vez, es importante evitar columnas que tengan un numero grande de values distintos (alta cardinalidad) o eventualmente evaluar la reducción de particiones resultantes con una columna menos granular.**

**Nótese que este particionado está pensado para optimizar la _lectura_ y una vez traida la data a memoria muy probablemente convenga reparticionar considerando las transformaciones a efectuar. Y en particular eligiendo un número de particionesconveniente que permita paralelizar y optimizar los recursos disponibles, evitando al mismo tiempo que el overhead del scheduling se vuelva demsiado costoso en relación a la ejecución.**

***

## Respuesta 3

**Si no se establece ninguna configuración de distribución de recursos entre sesiones, por default el scheduler los asignará entre ellas usando el modo _FIFO_ (ver respuesta 1). A su vez, de no setearse el parámetro `spark.deploy.defaultCore` cada aplicación usará todos los recursos disponibles, lo cual implicará que si un job pesado los toma todos, los demás jobs (aún por pequeños que sean) quedarán en cola esperando que este termine para iniciar su ejecución.**

**Por lo tanto, para evitar ello en la situación planteada sería útil separar las sesiones de Spark (dejando una para el proceso principal y otra/s para el resto de los jobs), y hacer una distribución _estática_ de los recursos entre ellas. Con eso, es posible garantizar que el proceso principal utilizará solamente la mitad de los recursos, y los demás quedarán disponibles para otros jobs que se ejecuten luego.**

**En particular, ejecutando en modo _cliente_, en primer lugar debería setearse en la sesión del proceso principal el número máximo de cores que se le asignará a dicha aplicación. Para ello puede setearse el parámetro `spark.cores.max`, por ejemplo en 18 (notar que si se corre en cluster mode el driver debe correr en los nodos del cluster por lo que habría que dejar disponibilidad para él). Con esta configuración, si no se especifica un límite de memoria o de cores por executor, por default Spark utilizará un executor por worker, que tomará todos los cores disponibles, solo limitado por ese máximo global.**

**Para configurar más finamente y evitar esto, puede setearse la cantidad de memoria a asignar a cada executor por medio del parámetro `spark.executor.memory`, lo cual llevará implícito un máximo de executors posible. Por ejemplo, seteando 8Gb la aplicación podrá tener hasta 9 executors (de 2 cores cada uno). Alternativamente, podría simplemente asignarse el número de cores por executor con el parámetro `spark.executor.cores`. Finalmente, al momento crear la sesión podría setearse directamente el numero total de execuors con el parámetro `spark.executor.instances`, teniendo presente que operará la configuración más restrictiva por lo que debería elegirse un número consistente con los demás para utilzar la mitad de los recursos como se desea.**

**Los valores son aproximados, porque no se descontó la memoria para el overhead, el OS, el manager, etc, pero con esta configuración quedaría cerca de la mitad de los recursos para el resto de los jobs. Dichos jobs podrían compartir una única aplicación, en cuyo caso para priorizarlos podrían usarse las herramientas de scheduling descriptas en la respuesta 1. O podrían formar parte de distintas aplicaciones en cuyo caso pueden o bien usarse los recursos remanentes en modo _FIFO_, o bien distribuirselos estáticamente como se hizo con el proceso principal.**