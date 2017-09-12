FROM python:3

WORKDIR /var/app

RUN mkdir -p /var/log/uwsgi \
  && apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62 \
  && echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list \
  && apt-get update \
  && apt-get install -y unzip ca-certificates nginx=1.9.11-1~jessie gettext-base supervisor \
  && rm -rf /var/lib/apt/lists/* \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log \
  && rm -f /etc/nginx/conf.d/default.conf


ADD requirements.txt .
RUN pip install -r requirements.txt

# Supervisor config
ADD deploy/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Nginx config
ADD deploy/nginx.conf deploy/blacklist.conf /etc/nginx/conf.d/
ADD deploy/uwsgi.ini deploy/app-uwsgi.ini /etc/uwsgi/
ADD deploy/newrelic.ini /etc/newrelic.ini
ADD app.py data.py addressbook.proto start-services.sh ./

EXPOSE 80 443

CMD ["/var/app/start-services.sh"]
