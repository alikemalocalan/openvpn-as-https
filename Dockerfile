FROM jrei/systemd-ubuntu

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y iproute2 wget curl tzdata apt-utils
RUN ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
    && dpkg-reconfigure --frontend noninteractive tzdata
RUN echo "2\n" | apt-get install -y sslh \
    && rm -rf /var/lib/apt/lists/*
RUN sed 's/DAEMON_OPTS=/#DAEMON_OPTS=/' /etc/default/sslh -i
RUN echo DAEMON_OPTS=\"--user sslh --listen 0.0.0.0:443 --ssh 127.0.0.1:22 --ssl 127.0.0.1:4443 --openvpn 127.0.0.1:1194 --pidfile /var/run/sslh/sslh.pid --timeout 5\" >>  /etc/default/sslh
RUN echo "Run=yes" >>  /etc/default/sslh
RUN a2enmod ssl
RUN sed 's/443/4443/'  /etc/apache2/ports.conf -i
RUN systemctl enable sslh
RUN service sslh start
RUN service openvpn restart
RUN service apache2 restart

#ENV LISTEN_IP 0.0.0.0
#ENV LISTEN_PORT 443
#ENV SSH_HOST localhost
#ENV SSH_PORT 22
#ENV OPENVPN_HOST localhost
#ENV OPENVPN_PORT 1194
#ENV HTTPS_HOST localhost
#ENV HTTPS_PORT 8443
#CMD sslh -f -u root -p $LISTEN_IP:$LISTEN_PORT --ssh $SSH_HOST:$SSH_PORT --ssl $HTTPS_HOST:$HTTPS_PORT --openvpn $OPENVPN_HOST:$OPENVPN_PORT
EXPOSE 443
RUN mkdir /opt/scripts
COPY *.sh /opt/scripts/
WORKDIR /opt/scripts/

EXPOSE 4443
