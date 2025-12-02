#!/bin/bash

set -e

export SPARK_HOME=$(python3 -c "import pyspark, os; print(os.path.dirname(pyspark.__file__))")
export SPARK_CONF_DIR=${SPARK_HOME}/conf

exec "$@"