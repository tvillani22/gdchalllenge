FROM openjdk:8-jre-slim

ARG SPARK_VERSION
ARG HADOOP_VERSION
ENV SPARK_HOME /usr/bin/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}

RUN apt-get update -y && \
    apt-get install curl python3 -y && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    curl https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -o spark.tgz && \
    tar -xf spark.tgz && \
    mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /usr/bin/ && \
    mkdir /usr/bin/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/logs && \
    rm spark.tgz

WORKDIR ${SPARK_HOME}

CMD ["bash"]