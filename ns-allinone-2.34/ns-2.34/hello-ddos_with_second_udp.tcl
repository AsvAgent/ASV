#Create a simulator object
#Any ns simulation will start with this command
#'ns' is an instance of the simulator. 
# set a 10 is equivalent to a = 10 in C
set ns [new Simulator]


#Define different colors for data flows (for NAM)
#Later flow id 1 will have color blue in nam
#Note how the simulator object 'ns' is referred to using '$'. all variable are referred to using '$'
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green

#Open the NAM trace file
#[open out.nam w] opens a file named 'out.nam' in write mode
#'nf' is a pointer to this file
#'a' can be used for appending to file instead of 'w'
set nf [open out.nam w]
$ns namtrace-all $nf

#Open trace file
set tf [open out.tf w]
$ns trace-all $tf


#Define a 'finish' procedure
#This is a procedure that terminates the program
#This a procedure named finish that can be called later
#TIP: The opening curly brace needs to be there - it cannot be moved to next line. 
#If its on the next line the script will not run

proc finish {} {

#'global' keyword defines variables declared outside this procedure that will be used here
        global ns nf tf
        
#'flush-tace' will force write the trace file       
        $ns flush-trace
        #Close the NAM trace file
        close $nf
	#Close trace file
	close $tf
#Execute NAM on the trace file
# 'exec' is used for external command. Here it is used to execute nam on the trace file.
        exec nam out.nam &
        exit 0
}

#Create four nodes
#[$ns node] creates a node. Then you can assign variable names to them.
#NOTE: Nodes are assigned IP in order of node creation. So here n0 has id 1, n1 2 and so on
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]
set n4 [$ns node]


#Create links between the nodes
#$ns simlplex/duplex node1 node2 capacity delay Queue-model
#This creates a link between two nodes with the given capacity, delay and queue-model
#Other than DropTail, RED, FQ, DRR, SFQ can be used as queuing models
#The links could have been assigned a named pointer same as nodes (not done here)

$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 1.7Mb 20ms DropTail
$ns duplex-link $n4 $n2 2Mb 10ms DropTail

#Set Queue Size of link (n2-n3) to 10
#A link can be referred to using its endpoint nodes. 
#Here variables $n2 $n3 define the link that will have queue-size of 10
#All the other links will have the default queue-size. 
#The default value can be found at ns-default.tcl

$ns queue-limit $n2 $n3 10

#Give node position (for NAM)
$ns duplex-link-op $n0 $n2 orient right-down
$ns duplex-link-op $n1 $n2 orient right-up
$ns duplex-link-op $n4 $n2 orient right-center
$ns duplex-link-op $n2 $n3 orient right

#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $n2 $n3 queuePos 0.5

#Now that we have nodes and link in place 
#we need to define routing netween them 
#and applications that can use the routing

#now we need to set up a tcp connection between n0 and n3
#and an FTP app on that tcp connection

#Setup a TCP connection
#This is the general way to create any agent. 

#To create any object. You need to know its tcl Class name
# For example Agent/TCP, Application/UDP

#TCP source
set tcp [new Agent/TCP]
$ns attach-agent $n0 $tcp

#TCP destination
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink

# connect source and destination
$ns connect $tcp $sink

#We are assigning the flow an id to distinguish it in nam
#fid can be used to analysis too
$tcp set fid_ 1

#Setup a FTP over TCP connection
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP


#now we setup a UDP connection between n1 and n3

#Setup a UDP connection
set udp [new Agent/UDP]
$ns attach-agent $n1 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 2

#now we setup a UDP connection between n4 and n3

#Setup a UDP connection
set udp2 [new Agent/UDP]
$ns attach-agent $n4 $udp2
set null2 [new Agent/Null]
$ns attach-agent $n3 $null2
$ns connect $udp2 $null2
$udp2 set fid_ 3

set cbr2 [new Application/Traffic/CBR]
$cbr2 attach-agent $udp2
$cbr2 set type_ CBR

$cbr2 set packet_size_ 1000
$cbr2 set rate_ 1mb
$cbr2 set random_ false

#Setup a CBR over UDP connection
#CBR just generates random packets at rate specified for the udp connection
#we need to set some parameters for CBR
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp

#Packet type, their also other default types
$cbr set type_ CBR


$cbr set packet_size_ 1000
$cbr set rate_ 1mb

#random_ is a flag indicating whether or not to introduce random noise in transmission times
$cbr set random_ false

#Now that the topology, connections and applications are setup 
#we need to schedule when each app starts

#Schedule events for the CBR and FTP agents
#time unit is second
$ns at 0.1 "$cbr start"
$ns at 0.1 "$cbr2 start"
$ns at 1.0 "$ftp start"
$ns at 4.0 "$ftp stop"
$ns at 4.5 "$cbr stop"
$ns at 4.5 "$cbr2 stop"

#Detach tcp and sink agents (not really necessary)
$ns at 4.5 "$ns detach-agent $n0 $tcp ; $ns detach-agent $n3 $sink"

#Call the finish procedure after 5 seconds of simulation time
#Usually keep some time for queues to clear up and such
#call 'finish'. Procedure names go in qoutes
$ns at 5.0 "finish"

#Print CBR packet size and interval
#you can use puts as printf in C. 
#The variable goes into square braces
#here, [$cbr set packet_size_]
#Notice the use of 'set'. '$cbr set interval'is kinda like 'cbr->interval' in C
puts "CBR packet size = [$cbr set packet_size_]"
puts "CBR interval = [$cbr set interval_]"


#You always need to run the simulation at the end
#Run the simulation
$ns run

