FROM i386/debian:latest

RUN apt-get -qq update \
    && apt-get install -y apt-utils \
    && apt-get install -y \
    build-essential \
    gcc-multilib \
    binutils \
    wget \
    curl \
    awscli \
    dpkg-dev \
    devscripts
COPY ./setup.sh /opt/src/scripts/setup.sh
RUN mkdir /Build /Release && chmod +x /opt/src/scripts/setup.sh
