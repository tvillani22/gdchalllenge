FROM tvillani/gd:ubuntu-20.04-openjdk-8-jre

ARG SPARK_VERSION
ARG HADOOP_VERSION
ARG SPARK_HADOOP_BINARY=spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ENV SPARK_HOME=/usr/bin/${SPARK_HADOOP_BINARY}
ENV SPARK_CONF_DIR=${SPARK_HOME}/conf

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl python3 && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_HADOOP_BINARY}.tgz -o spark.tgz && \
    tar -xzf spark.tgz && \
    mv ${SPARK_HADOOP_BINARY} /usr/bin/ && \
    mkdir -p ${SPARK_HOME}/logs && \
    rm spark.tgz && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=644 ./spark-defaults.conf ${SPARK_CONF_DIR}

WORKDIR ${SPARK_HOME}

CMD ["bash"]