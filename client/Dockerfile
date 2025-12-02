FROM tvillani/gd:ubuntu-20.04-openjdk-8-jre AS builder

ARG PYTHON_VERSION
ARG SPARK_VERSION

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends curl \
    openssl make gcc build-essential zlib1g-dev libsqlite3-dev libncurses5-dev libgdbm-dev \
    libnss3-dev libssl-dev libreadline-dev libffi-dev libbz2-dev liblzma-dev && \
    cd /usr/bin  && \
    curl https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz -o Python-${PYTHON_VERSION}.tgz && \
    tar -xf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION}  && \
    ./configure --enable-optimizations --with-lto && \
    make install && \
    rm -rf /var/lib/apt/lists/*

COPY ./client/bootstrap.txt ./client/requirements.txt ./

RUN pip3 install --no-cache-dir pyspark==${SPARK_VERSION} && \
    pip3 install --upgrade --no-cache-dir -r bootstrap.txt && \
    pip3 install --no-cache-dir -r requirements.txt && \
    rm bootstrap.txt requirements.txt


FROM tvillani/gd:ubuntu-20.04-openjdk-8-jre

ARG WORKSPACE_PATH

WORKDIR ${WORKSPACE_PATH}

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local

COPY --chmod=644  ./spark/spark-defaults.conf /tmp/spark-defaults.conf

RUN SPARK_CONF_DIR=$(python3 -c "import pyspark, os; print(os.path.join(os.path.dirname(pyspark.__file__), 'conf'))") && \
    mkdir -p $SPARK_CONF_DIR && \
    mv /tmp/spark-defaults.conf $SPARK_CONF_DIR/

COPY --chmod=755 ./client/entrypoint.sh /entrypoint.sh

EXPOSE 8888 4040

ENTRYPOINT ["/entrypoint.sh"]

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token="]