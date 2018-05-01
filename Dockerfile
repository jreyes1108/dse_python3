FROM ubuntu:latest

MAINTAINER Juan Reyes <jreyes1108@gmail.com>

RUN apt-get update \
    && apt-get install -y build-essential bash bzip2 vim curl git wget graphviz \
    ca-certificates libglib2.0-0 libxext6 libsm6 libxrender1 texlive-xetex pandoc \
    python3 python3-pip python3-dev \
    python3-matplotlib python3-mpltoolkits.basemap \
    && apt-get -y autoremove \
    && apt-get -y clean  \
    && apt-get autoclean  \
    && rm -rf /var/lib/apt/lists/*

RUN rm -f /usr/bin/python && ln -s /usr/bin/python3 /usr/bin/python

RUN pip3 install --upgrade pip
RUN pip3 install jupyter jupyterthemes notebook pydotplus pyparsing \
        ipykernel numpy scipy pandas autopep8 RISE import_ipynb \
        matplotlib plotly tabulate sklearn yapf pyarrow seaborn \
        pymysql pymongo sqlalchemy Pillow ipyleaflet folium \
        pysocks requests[socks] Scrapy beautifulsoup4 wget \
        jupyter_contrib_nbextensions ipywidgets pydot


RUN pip3 install --no-cache-dir Cython
#RUN cd /lib && python3 setup.py

RUN rm -r /root/.cache/pip


ENV HOME /home
RUN mkdir -p /home/notebooks
RUN mkdir -p /home/.jupyter
RUN mkdir -p /home/.jupyter/nbconfig
COPY jupyter_notebook_config.py /home/.jupyter/

WORKDIR /home/notebooks

RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension
RUN jupyter contrib nbextension install --user
RUN jupyter nbextensions_configurator enable --user
RUN jupyter nbextension enable --py --sys-prefix ipyleaflet
RUN jupyter-nbextension install rise --py --sys-prefix
RUN jupyter nbextension enable rise --py --sys-prefix

# download vim extension
RUN mkdir -p $(jupyter --data-dir)/nbextensions \
    && cd $(jupyter --data-dir)/nbextensions \
    && git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding


# simple styles https://github.com/dunovank/jupyter-themes
#RUN jt -t grade3 -T -f roboto
# dark
#RUN jt -t onedork -fs 95 -altp -tfs 11 -nfs 115 -cellw 88% -T
# light
#RUN jt -t grade3 -altp -f roboto -fs 90 -tfs 90 -nfs 90 -dfs 80 -ofs 80 -cellw 98% -T -vim

####################################################
# FULL PYTHON 3 and Jupyter Notebook at this point #
####################################################

# NOW INSTALL SPARK

# Python3 libs
RUN pip3 install --upgrade pip
RUN pip3 install findspark pyspark

# Spark dependencies
ENV APACHE_SPARK_VERSION 2.3.0
ENV HADOOP_VERSION 2.7
ENV PYSPARK_PYTHON /usr/bin/python3
ENV PYSPARK_DRIVER_PYTHON /usr/bin/python3

RUN apt-get -y update && \
    apt-get install --no-install-recommends -y openjdk-8-jre-headless ca-certificates-java && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN cd /tmp && \
        wget -q http://apache.claz.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz && \
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
ENV MESOS_NATIVE_LIBRARY /usr/local/lib/libmesos.so
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info


# For Jupyter Notebook
EXPOSE 8888
CMD jupyter notebook
