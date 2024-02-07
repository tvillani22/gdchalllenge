FROM openjdk:8-jre-slim

ARG WORKSPACE_PATH
ARG SPARK_VERSION
ARG PYTHON_VERSION

WORKDIR ${WORKSPACE_PATH}

COPY ./requirements.txt .

RUN apt-get update -y && \
    apt-get install curl openssl make gcc build-essential zlib1g-dev libsqlite3-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libbz2-dev liblzma-dev -y && \
    cd /usr/bin  && \
    curl https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz -o Python-${PYTHON_VERSION}.tgz && \
    tar -xf Python-${PYTHON_VERSION}.tgz && \
    cd Python-${PYTHON_VERSION}  && \
    ./configure --enable-optimizations --with-lto && \
    make install && \
    ln -s /usr/bin/Python-${PYTHON_VERSION}/python /usr/bin/python
    
RUN pip3 install --upgrade pip && \
    pip3 install --no-cache-dir pyspark==${SPARK_VERSION} && \
    pip3 install --no-cache-dir -r requirements.txt && \
    rm requirements.txt

EXPOSE 8888 4040

CMD jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token=