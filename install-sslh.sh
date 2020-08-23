apt-get update
echo "2\n" | apt-get install -y sslh
sed 's/DAEMON_OPTS=/#DAEMON_OPTS=/' /etc/default/sslh -i
echo DAEMON_OPTS=\"--user sslh --listen 0.0.0.0:443 --ssh 127.0.0.1:22 --ssl 127.0.0.1:4443 --openvpn 127.0.0.1:1194 --pidfile /var/run/sslh/sslh.pid --timeout 5\" >>/etc/default/sslh
echo "Run=yes" >>/etc/default/sslh
a2enmod ssl
sed 's/443/4443/' /etc/apache2/ports.conf -i
systemctl enable sslh
service sslh start
service openvpn restart
service apache2 restart
