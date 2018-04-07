FROM ubuntu:latest

MAINTAINER Juan Reyes <juan@reyescode.com>

EXPOSE 8888
EXPOSE 8889

RUN apt-get update \
    && apt-get install -y build-essential vim curl git wget supervisor graphviz\
    && apt-get -y autoremove \
    && apt-get -y clean  \
    && apt-get autoclean  \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y python3 python3-pip python3-dev npm

RUN wget -qO- https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs


RUN pip3 install --upgrade pip
RUN pip3 install jupyter jupyterlab notebook pydotplus \
        ipykernel numpy scipy pandas findspark \
        matplotlib plotly tabulate sklearn\
        pymysql pymongo sqlalchemy Pillow \
        pysocks requests[socks] Scrapy beautifulsoup4 wget \
        jupyter_contrib_nbextensions ipywidgets \
        jupyterlab_widgets

# https://github.com/jupyter-widgets/ipywidgets
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension

RUN jupyter labextension install @jupyter-widgets/jupyterlab-manager

#https://github.com/jwkvam/jupyterlab_vim
# RUN jupyter labextension install jupyterlab_vim

RUN rm -r /root/.cache/pip

# Adding the configuration file of the Supervisor
ADD supervisord.conf /etc/

RUN mkdir -p /home/admin/notebooks
RUN mkdir -p /home/admin/.jupyter
COPY jupyter_notebook_config.py /home/admin/.jupyter/

ENV HOME /home/admin
WORKDIR /home/admin/notebooks

# # enable Vim like environment
# RUN mkdir -p $(jupyter --data-dir)/nbextensions \
#     && cd $(jupyter --data-dir)/nbextensions \
#     && git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding
# RUN jupyter nbextension enable vim_binding/vim_binding

RUN jupyter lab build

# Executing supervisord
CMD ["supervisord", "-n"]
