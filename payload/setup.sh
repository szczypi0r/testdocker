#!/bin/bash

chown www-data:www-data -R /var/www >/dev/null
chmod 0777 -R /var/www >/dev/null

service redis-server restart >/dev/null
service mysql restart >/dev/null
service memcached restart >/dev/null