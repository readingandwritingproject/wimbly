#!/bin/sh

SCRIPT_DIR=$(readlink -f $(dirname $0))

$SCRIPT_DIR/stop.sh
sleep 1
$SCRIPT_DIR/start.sh
