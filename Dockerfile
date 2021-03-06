FROM ubuntu:18.04

ARG CONDA="https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh"
ARG JULIA1="https://julialang-s3.julialang.org/bin/linux/x64/1.0/julia-1.0.5-linux-x86_64.tar.gz"
ARG RSTUDIO_SERVER_DEB="https://download2.rstudio.org/server/trusty/amd64/rstudio-server-1.2.5033-amd64.deb"

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y \
  sudo \
  whois \
  git \
  wget \
  curl \
  gdebi \
  ca-certificates \
  locales \
  tzdata \
  libopenblas-base \
  libopenblas-dev \
  fonts-dejavu \
  build-essential \
  libxml2-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  r-base \
  gfortran \
  psmisc \
  libapparmor1 \
  libgmp3-dev \
  libmpfr-dev \
  libclang-dev &&\
apt-get clean &&\
rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# install Python + NodeJS with conda
RUN wget -q $CONDA -O /tmp/miniconda.sh  && \
    bash /tmp/miniconda.sh -f -b -p /opt/conda && \
    /opt/conda/bin/conda install --yes -c conda-forge \
      python sqlalchemy tornado jinja2 traitlets requests pip pycurl numpy scipy \
      nodejs configurable-http-proxy notebook \
      jupyterhub jupyterlab=1.2.10 oauthenticator \
      && \
    /opt/conda/bin/pip install --upgrade pip && \
    rm /tmp/miniconda.sh

RUN  mkdir -p /opt/julia1 && \
  wget -O /tmp/julia1.tar.gz $JULIA1 && \
  tar zxvf /tmp/julia1.tar.gz -C /opt/julia1 --strip-components 1 && \
  rm /tmp/julia1.tar.gz

ENV PATH=/opt/julia1/bin:/opt/conda/bin:$PATH

RUN wget -O /tmp/rstudio.deb $RSTUDIO_SERVER_DEB && \
      yes | gdebi /tmp/rstudio.deb && \
      rm /tmp/rstudio.deb

RUN mkdir -p /srv/jupyterhub/
WORKDIR /srv/jupyterhub/

RUN jupyter labextension install @jupyterlab/hub-extension
RUN pip install --upgrade jupyterlab-git
RUN jupyter lab build

ENV NB_UID        1000
ENV NB_USER       jupyter
ENV NB_PASSWORD   jupyter
ENV NB_GID        1000
ENV NB_GROUP      jupyter
ENV NB_GRANT_SUDO nopass
ENV NB_PORT       8000
ENV NB_VOLUME     /home/jupyter
ENV RS_PORT       8888

COPY entrypoint.sh /entrypoint.sh
COPY adduser.sh /adduser.sh

CMD ["/entrypoint.sh"]
