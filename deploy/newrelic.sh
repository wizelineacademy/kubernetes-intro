#!/bin/bash
pushd /var/app
NEW_RELIC_CONFIG_FILE=newrelic.ini
export NEW_RELIC_CONFIG_FILE
exec newrelic-admin run-program python app.py
popd
