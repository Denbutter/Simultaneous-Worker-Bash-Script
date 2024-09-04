#!/bin/bash
: '
CIS 3050
Assignment 4
November 26th, 2023
Created by: John Denbutter
1056466
The testing script for the server
'

#test1 - queuing
: '
echo "Test 1:"
./msgServer.sh
./submitJob.sh "bash timedCountdown.sh 4"
./submitJob.sh "bash timedCountdown.sh 4"
./submitJob.sh "bash timedCountdown.sh 1"
./submitJob.sh "bash timedCountdown.sh 1"
./submitJob.sh "bash timedCountdown.sh 1"
./submitJob.sh "bash timedCountdown.sh 1"
./submitJob.sh "bash timedCountdown.sh 1"
./submitJob.sh "bash timedCountdown.sh 1"
./submitJob.sh "bash timedCountdown.sh 1"
./submitJob.sh "bash timedCountdown.sh 1"
sleep 3
./submitJob.sh -s
sleep 4
./submitJob.sh -s
./submitJob.sh -x
sleep 1
#'


#test2 - multiple servers
: '
echo "Test 2:"
echo "Attempt 1"
./msgServer.sh
./msgServer.sh
./submitJob.sh ls
./submitJob.sh ls
./submitJob.sh -x
sleep 2
echo "Attempt 2"
./msgServer.sh
./server.sh &
./submitJob.sh ls
./submitJob.sh ls
./submitJob.sh -x
sleep 2
pkill server.sh
pkill executeJob.sh
#'

#test3 - no workers
: '
echo "Test 3:"
./msgServer.sh
./submitJob.sh exit
./submitJob.sh exit
./submitJob.sh exit
./submitJob.sh exit
./submitJob.sh exit
./submitJob.sh exit
./submitJob.sh exit
./submitJob.sh exit
./submitJob.sh ls
./submitJob.sh ls
sleep 1
./submitJob.sh -s
./submitJob.sh -x
#'

#test 4 - unknown/incorrect commands
#: '
echo "Test 4:"
./msgServer.sh
./submitJob.sh cd
./submitJob.sh bash timedCountdown.sh 5
./submitJob.sh nothing
./submitJob.sh
./submitJob.sh ""
./submitJob.sh "$1"
./submitJob.sh "./submitJob.sh ls"
./submitJob.sh NULL
./submitJob.sh "echo test"
sleep 1
./submitJob.sh -s
./submitJob.sh -x
#'