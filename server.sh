#!/bin/bash
: '
CIS 3050
Assignment 4
November 26th, 2023
Created by: John Denbutter
1056466
The server script that delegates tasks from the FIFO to the workers
'

#variables
fifo="/tmp/server-denbutte-inputinfo"
processor_num=$(cat /proc/cpuinfo | grep processor | wc -l)
#processor_num=2 #for debugging -> my default is 8
i=0
terminate=1
jobsFinished=0
declare -a jobQueue
declare -a Workers
currentWorker=0



#functions
cleanup()
{
    #show cancelled jobs
    if [ ${#jobQueue[@]} -gt 0 ]
    then
        echo "Cancelled jobs: ${jobQueue[@]}" #for debugging
    fi

    #remove FIFO
    rm $fifo
}
trap cleanup EXIT

jobToWorker()
{
    #if worker is available
    if [[ ${Workers[$currentWorker]} == 1 ]] && [ ${#jobQueue[@]} -gt 0 ]
    then
        #send next job to next worker
        #echo "Sending ${jobQueue[0]} to $currentWorker" #for debugging
        echo ${jobQueue[0]} > "/tmp/worker$currentWorker-denbutte-inputinfo" &

        #make worker unavailable
        Workers[$currentWorker]=0

        #pop command from queue
        jobQueue=("${jobQueue[@]:1}")

        #move to next worker, if it exceeds max, wrap back to 0
        ((currentWorker++))
        if [[ $currentWorker == $processor_num ]]
        then
            currentWorker=0
        fi
        #echo "currentWorker = $currentWorker" #for debugging
    fi
}



#initialize worker status array 
while [ $i -lt $processor_num ]
do
    Workers+=(1)
    #echo "$i: ${Workers[$i]}" #for debugging
    ((i++))
done
i=0



#main server run state
while [ $terminate != 0 ]
do
    if read line; then
        #echo $line #for debugging

        #for shutdown
        if [[ $line == "shutdown" ]]
        then
            while [ $i -lt $processor_num ]
            do
                echo "shutdown" > "/tmp/worker$i-denbutte-inputinfo"
                ((i++))
            done
            terminate=0

        #for check status
        elif [[ $line == "status" ]]
        then
            echo "Number of workers: $processor_num"
            echo "Tasks processed: $jobsFinished"

        #for adding a command to queue
        elif [[ $line == CMD* ]]
        then
            #add job to queue
            jobQueue+=("${line:4}")
            #check if "current worker" is available, then send job to worker
            jobToWorker

        #for recieving a completed worker
        elif [[ $line == FIN* ]]
        then
            #get index from returned worker
            #echo "Returned with: $line" #for debugging
            index=${line:4}
            #echo $index #for debugging

            #increment completed jobs
            ((jobsFinished++))

            #make worker available
            Workers[$index]=1
            #echo "Worker $currentWorker: ${Workers[$currentWorker]}" #for debugging

            #check if "current worker" is available, then send job to worker
            jobToWorker

        #for dealing with an unknown
        else
            echo "ERROR: unknown input"
        fi
    fi
done <$fifo

#wait for child processes to terminate. Server sits idle, not longer reads from FIFO
#this is required because any workers that write to FIFO after it has been deleted, cause errors when the server is restarted
#wait