FROM ubuntu:20.04

LABEL maintainers="James Bury <jabury@uwaterloo.ca>"

# Set Args
ARG TRADING_MODE

# Set Env vars
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Toronto
ENV TWS_MAJOR_VRSN=1012
ENV TWS_MINOR_VRSN=2h
ENV IBC_VERSION=3.12.0
ENV IBC_INI=/root/IBController/IBController.ini
ENV IBC_PATH=/opt/IBController/
ENV GITHUB_REPO=https://github.com/d3an/ibgateway-docker
ENV TWS_PATH=/root/Jts
ENV TWS_CONFIG_PATH=/root/Jts
ENV LOG_PATH=/opt/IBController/Logs
ENV JAVA_PATH=/opt/i4j_jres/1.8.0_152-tzdata2019c/bin
ENV APP=GATEWAY

# Install needed packages
RUN apt-get -qq update -y && apt-get -qq install -y unzip xvfb libxtst6 libxrender1 libxi6 socat software-properties-common curl supervisor x11vnc tmpreaper python3-pip openjfx

# Setup IB TWS
RUN mkdir -p /opt/TWS
WORKDIR /opt/TWS
RUN set -o pipefail && wget ${GITHUB_REPO}/releases/download/${TWS_MAJOR_VRSN}.${TWS_MINOR_VRSN}/ibgateway-standalone-linux-${TWS_MAJOR_VRSN}-${TWS_MINOR_VRSN}-x64.sh
COPY ./ibgateway-standalone-linux-${TWS_MAJOR_VRSN}-${TWS_MINOR_VRSN}-x64.sh /opt/TWS/ibgateway-standalone-linux-x64.sh
RUN chmod a+x /opt/TWS/ibgateway-standalone-linux-x64.sh

# Install IBController
RUN mkdir -p /opt/IBController/ && mkdir -p /opt/IBController/Logs
WORKDIR /opt/IBController/
COPY ./IBCLinux-${IBC_VERSION}/ /opt/IBController/
RUN chmod -R u+x scripts/*.sh

WORKDIR /

# Install TWS
RUN (echo; echo n) | /opt/TWS/ibgateway-standalone-linux-x64.sh
RUN rm /opt/TWS/ibgateway-standalone-linux-x64.sh

# Must be set after install of IBGateway
ENV DISPLAY :0

# Below files copied during build to enable operation without volume mount
COPY ./ib/$TRADING_MODE/IBController.ini /root/IBController/IBController.ini
RUN mkdir -p /root/Jts/
COPY ./ib/$TRADING_MODE/jts.ini /root/Jts/jts.ini

# Overwrite vmoptions file
RUN rm -f /root/Jts/ibgateway/${TWS_MAJOR_VRSN}/ibgateway.vmoptions
COPY ./ibgateway.vmoptions /root/Jts/ibgateway/${TWS_MAJOR_VRSN}/ibgateway.vmoptions

# Install Python requirements
RUN pip3 install supervisor

COPY ./restart-docker-vm.py /root/restart-docker-vm.py

COPY ./ib/$TRADING_MODE/supervisord.conf /root/supervisord.conf

CMD /usr/bin/supervisord -c /root/supervisord.conf
