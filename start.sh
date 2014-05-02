#!/bin/sh

SCRIPT_DIR=$(readlink -f $(dirname $0))

echo Nginx start

sudo $SCRIPT_DIR/nginx/sbin/nginx -t -c $SCRIPT_DIR/nginx/conf/nginx.conf
CONFIG_TEST_RESULT=$?
if [ $CONFIG_TEST_RESULT -eq 0 ]; then
  sudo $SCRIPT_DIR/nginx/sbin/nginx -c $SCRIPT_DIR/nginx/conf/nginx.conf
  if [ $? -eq 0 ]; then
    echo '... started'
  fi
fi

if [ -f $SCRIPT_DIR/redis/bin/redis-server ]
then
  echo Redis start
  $SCRIPT_DIR/redis/bin/redis-server $SCRIPT_DIR/redis/conf/redis.conf
  if [ $? -eq 0 ]; then
    echo '... started'
  fi
fi