#!/bin/bash
: '
CIS 3050
Assignment 4
November 26th, 2023
Created by: John Denbutter
1056466
The initializing script that activates the workers and server
'

#variables
fifo="/tmp/server-denbutte-inputinfo"
processor_num=$(cat /proc/cpuinfo | grep processor | wc -l)
#processor_num=2 #for debugging -> my default is 8
i=0

if pgrep -x "server.sh" > /dev/null
then
    echo "server is already running"
    exit 1
fi

#setup FIFO
if [ -p "$fifo" ]
then
    echo "Server FIFO already exists. Recreating FIFO."
    rm $fifo
fi
mkfifo $fifo

#starting workers
echo "Starting up $processor_num processing units."
while [ $i -lt $processor_num ]
do
    ./executeJob.sh $i &
    ((i++))
done

#start server
./server.sh &

echo "Ready for processing: use './submitJob.sh Job' to send tasks to the server"