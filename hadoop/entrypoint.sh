#!/bin/bash
set -e

export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:/bin/java::")

exec > >(tee -a ${HADOOP_LOG_DIR}/node.log) 2>&1

format_namenode_and_setup_logs() {
    hdfs namenode -format -force
    echo "Starting NameNode temporarily to create spark-history-logs (${SPARK_LOGS_HDFS_PATH})..."
    "${HADOOP_HOME}/sbin/hadoop-daemon.sh" start namenode
    sleep 3
    hdfs dfs -mkdir -p "${SPARK_LOGS_HDFS_PATH}"
    hdfs dfs -chmod -R 777 "${SPARK_LOGS_HDFS_PATH}"
    echo "Stopping temporary NameNode..."
    "${HADOOP_HOME}/sbin/hadoop-daemon.sh" stop namenode
}

if [ "$(hostname)" = "namenode" ]; then
    echo "Reading NameNode directory ${HADOOP_HDFS_CONF_DFS_NAME_DIR} to check if HDFS formatting is needed..."

    if [ ! -f "${HADOOP_HDFS_CONF_DFS_NAME_DIR}/current/VERSION" ]; then
        echo "NameNode directory (${HADOOP_HDFS_CONF_DFS_NAME_DIR}) unformatted, formatting now..."
        format_namenode_and_setup_logs

    elif [ "$FORCE_HDFS_FORMAT" = "true" ]; then
        echo "NameNode already formatted, but FORCE_HDFS_FORMAT set to true, formatting now.."
        format_namenode_and_setup_logs
    else
        echo "NameNode already formatted and FORCE_HDFS_FORMAT set to false. Skipping HDFS format."
    fi

elif [ "$(hostname)" = "datanode" ]; then
    sleep 10
    if [ "$FORCE_HDFS_FORMAT" = "true" ] && [ -n "${HADOOP_HDFS_CONF_DFS_DATA_DIR}" ] && [ -d "${HADOOP_HDFS_CONF_DFS_DATA_DIR}" ]; then
        echo "FORCE_HDFS_FORMAT set to true, deleting Datanode directory (${HADOOP_HDFS_CONF_DFS_DATA_DIR}) to avoid mismatches..."
        rm -r "${HADOOP_HDFS_CONF_DFS_DATA_DIR}"
    fi
else
    echo "Hostname not recognized."
fi

echo "Running final command: $@"

exec "$@"