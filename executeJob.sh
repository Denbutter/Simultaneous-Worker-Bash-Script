#!/bin/bash
: '
CIS 3050
Assignment 4
November 26th, 2023
Created by: John Denbutter
1056466
Worker script
'

#variables
index=$1
workerFifo="/tmp/worker$index-denbutte-inputinfo"
fifo="/tmp/server-denbutte-inputinfo"
log="/tmp/worker-denbutte.$index.log"
terminate=1

#functions
cleanup()
{
    #remove worker's FIFO
    rm $workerFifo
    #echo "Worker $index finished!" #for debugging
}
trap cleanup EXIT

#echo "Worker $index created!" #for debugging

#clear previous log
if [ -f "$log" ]
then
    rm $log
fi

#setup FIFO
if [ -p "$workerFifo" ]
then
    #echo "worker FIFO $index already exists. Recreating $index worker FIFO." #for debugging
    rm $workerFifo
fi
if [ -f "$workerFifo" ]
then
    rm $workerFifo #the fifo can still exist as a file even if there are no reads or writes into it -> if process ends into a log
fi
mkfifo $workerFifo

#run tasks
while [ $terminate != 0 ]
do
    if read line; then
        #echo $line #for debugging
        if [[ $line == "shutdown" ]]
        then
            terminate=0
        else
            #execute job
            #echo "running: $line" #for debugging
            $line &>> $log

            #let server know that worker has finished job, only if the server is still running (fifo still exists)
            if [ -p "$fifo" ]
            then
                echo "FIN $index" > $fifo
            fi
        fi
    fi
done <$workerFifo