#!/bin/sh

SCRIPT_DIR=$(readlink -f $(dirname $0))

echo Nginx reload

sudo $SCRIPT_DIR/nginx/sbin/nginx -t -c $SCRIPT_DIR/nginx/conf/nginx.conf
CONFIG_TEST_RESULT=$?
if [ $CONFIG_TEST_RESULT -eq 0 ]; then
  sudo $SCRIPT_DIR/nginx/sbin/nginx -c $SCRIPT_DIR/nginx/conf/nginx.conf -s reload
  echo '... reloaded'
fi