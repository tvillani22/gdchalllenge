FROM tvillani/gd:ubuntu-20.04-openjdk-8-jre

ARG HADOOP_VERSION
ARG HADOOP_HOME
ARG HADOOP_CONF_DIR
ARG HADOOP_LOG_DIR
ARG HADOOP_HDFS_CONF_DFS_NAME_DIR
ARG HADOOP_HDFS_CONF_DFS_DATA_DIR
ARG SPARK_LOGS_HDFS_PATH

ENV HADOOP_HOME=${HADOOP_HOME}
ENV HADOOP_CONF_DIR=${HADOOP_CONF_DIR}
ENV HADOOP_LOG_DIR=${HADOOP_LOG_DIR}
ENV HADOOP_HDFS_CONF_DFS_NAME_DIR=${HADOOP_HDFS_CONF_DFS_NAME_DIR}
ENV HADOOP_HDFS_CONF_DFS_DATA_DIR=${HADOOP_HDFS_CONF_DFS_DATA_DIR}
ENV PATH=${PATH}:$HADOOP_HOME/bin:${HADOOP_HOME}/sbin
ENV SPARK_LOGS_HDFS_PATH=${SPARK_LOGS_HDFS_PATH}

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    curl -fSL https://archive.apache.org/dist/hadoop/core/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz -o hadoop.tar.gz && \
    tar -xvf hadoop.tar.gz && \
    mv hadoop-${HADOOP_VERSION} $HADOOP_HOME && \
    rm hadoop.tar.gz && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY --chmod=644 ./hadoop_conf ${HADOOP_CONF_DIR}

COPY --chmod=755 ./entrypoint.sh /entrypoint.sh

RUN mkdir -p "${HADOOP_LOG_DIR}" "${HADOOP_HDFS_CONF_DFS_NAME_DIR}" "${HADOOP_HDFS_CONF_DFS_DATA_DIR}" && \
    chmod -R 755 "${HADOOP_LOG_DIR}" "${HADOOP_HDFS_CONF_DFS_NAME_DIR}" "${HADOOP_HDFS_CONF_DFS_DATA_DIR}"

ENTRYPOINT ["/entrypoint.sh"]