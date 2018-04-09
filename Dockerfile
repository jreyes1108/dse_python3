FROM ubuntu:latest

MAINTAINER Juan Reyes <jreyes1108@gmail.com>

EXPOSE 8888

RUN apt-get update \
    && apt-get install -y build-essential bash vim curl git wget graphviz \
    && apt-get -y autoremove \
    && apt-get -y clean  \
    && apt-get autoclean  \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y python3 python3-pip python3-dev


RUN pip3 install --upgrade pip
RUN pip3 install jupyter notebook pydotplus \
        ipykernel numpy scipy pandas findspark \
        matplotlib plotly tabulate sklearn\
        pymysql pymongo sqlalchemy Pillow \
        pysocks requests[socks] Scrapy beautifulsoup4 wget \
        jupyter_contrib_nbextensions ipywidgets

# https://github.com/jupyter-widgets/ipywidgets
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension

RUN rm -r /root/.cache/pip


RUN useradd -m -s /bin/bash -N -u 1000 admin
USER admin
ENV HOME /home/admin
RUN mkdir -p /home/admin/notebooks
RUN mkdir -p /home/admin/.jupyter
COPY jupyter_notebook_config.py /home/admin/.jupyter/

WORKDIR /home/admin/notebooks

# download vim extension
RUN mkdir -p $(jupyter --data-dir)/nbextensions \
    && cd $(jupyter --data-dir)/nbextensions \
    && git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding
# enable Vim like environment
#RUN jupyter nbextension enable vim_binding/vim_binding


####################################################
# FULL PYTHON 3 and Jupyter Notebook at this point #
####################################################

# NOW INSTALL SPARK

USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION 2.3.0
ENV HADOOP_VERSION 2.7

RUN apt-get -y update && \
    apt-get install --no-install-recommends -y openjdk-8-jre-headless ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

    RUN cd /tmp && \
        wget -q http://apache.claz.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
        echo "258683885383480BA01485D6C6F7DC7CFD559C1584D6CEB7A3BBCF484287F7F57272278568F16227BE46B4F92591768BA3D164420D87014A136BF66280508B46 *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
        tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local --owner root --group root --no-same-owner && \
        rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

# Mesos dependencies
RUN . /etc/os-release && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
    DISTRO=$ID && \
    CODENAME=$VERSION_CODENAME && \
    echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" > /etc/apt/sources.list.d/mesosphere.list && \
    apt-get -y update && \
    apt-get --no-install-recommends -y --force-yes install mesos=1.2\* && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Spark and Mesos config
ENV SPARK_HOME /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.6-src.zip
ENV MESOS_NATIVE_LIBRARY /usr/local/lib/libmesos.so
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info



# DONE WITH SPARK. GO BACK TO USER ADMIN
USER admin
WORKDIR /home/admin/notebooks

CMD jupyter notebook
