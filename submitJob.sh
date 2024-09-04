#!/bin/bash
: '
CIS 3050
Assignment 4
November 26th, 2023
Created by: John Denbutter
1056466
submits commands to the server through the FIFO
'
fifo="/tmp/server-denbutte-inputinfo"

#flock the fifo for exclusive printing -> not actually needed for our message lengths
#exec 3>$fifo
#flock -x 3

#echo "$1" #for debugging

if [ "$1" == "-s" ]
then
    echo "status" > $fifo
elif [ "$1" == "-x" ]
then
    echo "shutdown" > $fifo
else
    echo "CMD $1" > $fifo
fi

#release flock on fifo
#exec 3>&-