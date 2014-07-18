#!/bin/sh

SCRIPT_DIR=$(readlink -f $(dirname $0))
cd $SCRIPT_DIR

while true
do
  inotifywait -e modify $SCRIPT_DIR/nginx/conf/* `find application -name '*.lua' | xargs -n 1` `find application -name '*.conf.source' | xargs -n 1`
  $SCRIPT_DIR/reload.sh
  if [ $? -eq 0 ]
  then
    echo "(Reloading Nginx)"
  fi
done
                