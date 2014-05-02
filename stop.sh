#!/bin/sh

SCRIPT_DIR=$(readlink -f $(dirname $0))

echo Nginx stop

sudo $SCRIPT_DIR/nginx/sbin/nginx -s stop
CONFIG_TEST_RESULT=$?
if [ $CONFIG_TEST_RESULT -eq 0 ]; then
  echo '... stopped'
fi

if [ -f $SCRIPT_DIR/redis/bin/redis-server ]
then
  echo Redis stop
  $SCRIPT_DIR/redis/bin/redis-cli SHUTDOWN
  if [ $? -eq 0 ]; then
    echo '... stopped'
  fi
fi

