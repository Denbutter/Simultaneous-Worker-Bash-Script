Simultaneous Worker Bash Script ReadMe
John Denbutter
November 26th, 2023


*Important note: These bash scripts were designed to work within a Docker Image, and may therefore not work as intended on all machines.


msgServer:
The initialising script that activates the server FIFO, and the workers and the server scripts as background processes.


This script is very basic, only acting to separate the startup from the main scripts. If the server FIFO already exists, it will be removed and recreated. The number of workers is determined by the number of processors that are available to it, as described in the assignment outline.


This script requires no command-line arguments, and is able to be run as follows:
        ./msgServer.sh


submitJob:
A script that submits commands to the server through the FIFO. The submitter will send messages to the server FIFO: /tmp/server-denbutte-inputinfo in the following ways:
* -s - will be converted to “status”
* -x - will be converted to “shutdown”
* Anything else will be appended with CMD, and is expected to work as a job.


The submitter script simply sends its argument to the server: $1, and therefore all commands must be sent as if it was written on the command-line, and must be written in quotation marks if it is more than one word. A created bash script would need to be written out as follows:
        ./submitJob.sh “bash timedCountdown 5”


This would send the instruction in full to the worker, who can then execute the job.
A simpler binary file could be able to be sent on its own:
        ./submitJob.sh ls


If any flags are added however (making it more than one word), it again requires quotation marks:
        ./submitJob.sh “ls -l”


executeJob:
The worker script that runs the job given by the server. 


This script creates the FIFO that the server uses to communicate with it, as well as the log that it writes its commands into. If either of these files exist already, they will be removed before being used again. The worker should also remove its worker FIFO on termination.


The worker can receive one of two things:
* A command - which the worker will attempt to execute, and output into its log.
* shutdown - causing the worker to exit


Once the worker finishes its job, it will return “FIN [#]”, where [#] is the worker’s index, to the server. If the server’s FIFO no longer exists, it will not do so as this likely means the server has terminated, and will create issues on its restart.


server:
The main server script that delegates tasks from the FIFO to the workers. The server will delegate tasks in round-robin fashion, meaning it keeps track of which worker is in line to receive the next job.


The server keeps track of the status of its workers in an array: Workers, which acts as a normal array. The server also keeps track of any queued jobs that have not been assigned to a job in: jobQueue, this acts as a traditional queue, allowing commands to be popped from the queue. 


The server reads from the main server FIFO: /tmp/server-denbutte-inputinfo in the following ways:
* CMD* - a command to be passed on to the next worker
* FIN* - a worker has finished its job
* status - the server shares the number of workers and the number of tasks completed
* shutdown - the server pushes shutdown to each of the workers, and then terminates itself
* If the server is unable to process its input it will write a message to the console, and continue.


The server writes to the workers using the FIFO: /tmp/worker[#]-denbutte-inputinfo, where [#] is the worker number. The server will write only the command, excluding “CMD”.


The server will check to see if the next worker in the round-robin queue is ready when it from the server FIFO either: a new job (CMD*), or a returned worker (FIN*).


runTests:
        The following tests are designed to work for the developer’s system, which allows 8 processes to run a worker. runTests executes unique instances of the server to run the following tests:


Test 1:
The purpose of the test is to test the job queuing, and the ability of the round-robin to allocate jobs in order, and more than one cycle.
        
Expected log:
Logs 0 and 1 read “4, 3, 2, 1, 1 seconds remaining” and logs 3-7 read “1 seconds remaining”.


The test succeeds if workers 0 and 1 do a 4 second and a 1 second countdown, and workers 2-7 do only a 1 second countdown.


The test succeeds because the logs show the expected output. We can also see the server status showing 6 processes complete on the first pass (workers 2-7), and 10 on the second (workers 0 and 1 completing 2 countdowns each).


Test 2:
The purpose of this test is to check the ability of the server scripts to handle multiple conflicting server processes.


Expected log:
Logs 0 and 1 read out all the files in the current directory once each.


The test succeeds if either only one server successfully launches and operates, or multiple servers operate in unison, or multiple servers operate but do not interfere with one another.


The first attempt is dealt with successfully by the msgServer script, only spawning one server. The second attempt fails however because multiple servers are spawned, and they do not operate without conflicting with one another. One of the two running servers still responds to commands normally, and the other is unable to receive the input. On termination, only one server, and all the FIFOs are terminated normally, but one server and at least one worker still exist, and must be terminated using a kill command. The logs also show that one server is issuing one command each, and then fails a read, this is because only worker 0 outputs a log.


Test 3:
The purpose of the test is to break the server by killing its workers and continuing to send it jobs


Expected log:
The logs should be empty
Expected output:
Test 3:
Starting up 8 processing units.
Ready for processing: use ‘./submitJob Job’ to send tasks to the server
Number of workers: 8
Tasks processed: 0
Cancelled jobs: ls ls


The test succeeds if the server can correctly identify that no workers are available and queue the jobs up indefinitely. This is not ideal in a real world application, but for our purposes it is alright.


The test passes, because we can see the cancelled jobs on termination, and the logs are empty. One issue is that the number of workers is not updated when they terminate, because the server does not recognize that they have actually terminated. The server still operates correctly. This behaviour is the same if we would pause the workers indefinitely instead of terminating them. Also all FIFOs and processes terminate successfully. The worker FIFOs do still leave a trace in temp however, and even though the execute worker script can account for this (and delete the FIFO before they mkfifo), this means that to clean up for itself completely, the server needs to be restarted and stopped to flush the files out. Alternatively the FIFOs can be removed manually, but that defeats the purpose of the test.


Test 4:
The purpose of this test is to feed the server improper input, and give the workers commands that do not work.


Expected log:
The logs should be empty if it received the equivalent of no command (IE space, empty quotes…), contain an error if the command did not make sense, or contain the output of a valid command.
Expected output:
Test 4:
Starting up 8 processing units.
Ready for processing: use ‘./submitJob Job’ to send tasks to the server
Number of workers: 8
Tasks processed: 10


The test succeeds if the server remains stable and successfully passes every command off to a worker, and the workers can handle the input without abrupt termination.


The test succeeded. The ability of the workers to execute a given input is not very strong, however both the server and workers can successfully move on from strange commands such as changing directories.