#!/bin/bash
FILE_NAME=/var/log/container_monitor.log
touch $FILE_NAME
docker stats --no-stream | awk '{ print "Time-mm-dd-yy-H:M:S", $0 }' | head -n 1 >> $FILE_NAME
while true;
do
docker stats --no-stream | awk '{ print strftime("%m-%d-%Y-%H:%M:%S"), $0 }' | tail -n +2 >> $FILE_NAME
sleep 10
done
