#!/bin/bash

DEPLOY_IN_KUBE=${DEPLOY_IN_KUBE:-"YES"}
LETSENCRYPT_SERVER=${DEVOPS_CERTBOT_SERVICE_HOST:-"127.0.0.1"}
LETSENCRYPT_PORT=${DEVOPS_CERTBOT_SERVICE_PORT:-"80"}

if [ "$DEPLOY_IN_KUBE" = "YES" ]; then
	[ "$(curl -s -H "Authorization: token $DEVOPS_TOKEN" -H 'Accept: application/vnd.github.v3.raw' \
			'https://api.github.com/repos/wizeline/app-manager/contents/scripts/get_environment_variables.py?ref=master' \
			-w %{http_code} -o get_environment_variables.py)" = "200" ] || exit 2
	python get_environment_variables.py --check || exit 1
	python get_environment_variables.py --env >env.sh
	source env.sh
fi

pushd /var/app

curl -s -L https://github.com/google/protobuf/releases/download/v3.1.0/protoc-3.1.0-linux-x86_64.zip -o protoc-3.1.0-linux-x86_64.zip || exit 1
unzip -qq protoc-3.1.0-linux-x86_64.zip -d protoc && protoc/bin/protoc --python_out=import_style=binary:. --proto_path=/var/app /var/app/addressbook.proto || exit 1

sed -e "s#%LETSENCRYPT_SERVER%#${LETSENCRYPT_SERVER}#g" \
    -e "s#%LETSENCRYPT_PORT%#${LETSENCRYPT_PORT}#g" \
    -i /etc/nginx/conf.d/nginx.conf || exit 1
echo "daemon off;" >>/etc/nginx/nginx.conf

sed -i -e "s/%NEW_RELIC_LICENSE_KEY%/$NEW_RELIC_LICENSE_KEY/g" \
    -e "s/%NEW_RELIC_APP_NAME%/$NEW_RELIC_APP_NAME/g" \
    /etc/newrelic.ini

/usr/bin/supervisord
