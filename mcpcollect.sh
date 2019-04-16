#!/bin/bash


function usage(){
	echo "    mcpcollector -c <nova|neutron|stacklight|ceph>"
	echo ""
	echo "    -c component "
	echo "         <nova|neutron|stacklight|ceph|rabbitmq|cinder|contrail>"
	echo "	  -h target hostname or IP"
	echo "    -o ceph OSD"
	echo "    -t timeframe yymmddhhmm-yymmddhhmm"
	echo "    -i some ID"
	echo "    -r rotated logs"
	echo "		<Y|N>"
	echo "	  "

}

# may use optarg

while getopts "hc:n:e:" arg; do
  case $arg in
	  c);;
    i);;
  esac
done


# Nova instances
# OVS
# Versions of all services
# ceph pg
# Service status
# NTH : connectivity/network
# Networking Gereral Health
# Cinder ?
# Heat Stack
# Nova instance files : ls -al /var/lib/nova/instances/ (on a compute node)
# Cinder  -- /var/lib/cinder/volumes/



## MCP Collector ##

targetdir="/tmp/mcpcollect"
localtargetdir="/tmp/mcpcollect"

[[ -d dir ]] || mkdir $targetdir

if [ "$component" = "ceph" ]; then
	### Ceph General ###
	cephLogDir="/var/log/ceph"
	cephOsdDir="/var/log/ceph"
	declare -a Cmd ("ceph -s" "ceph health detail" "ceph --version")
	declare -a Log ("ceph.log")

elif [ "$component" = "cephosd" ]; then
	### Ceph OSD ###
	declare -a Log 

elif [ "$component" = "nova" ]; then
	### Nova ###
	declare -a Cmd ("nova hypervisor-list" "nova list --fields name,networks,host --all-tenants")
	declare -a Log ("/var/log/nova" "/var/log/nova/nova-api")

elif [ "$component" = "reclass" ]; then
	### Reclas Model ###
	declare -a Cmd ("tar -zcvf `date '+%Y%m%d%H%M%S'`.tar.gz /var/salt/reclass $targetdir")
fi


## Run Function ##

# RunCommands <targethost> <command|log> <commandString|logString>

fuction collectdata {
	targethost=$1
	commandorlog=$2 
	if [ "$2" = "CMD" ]; then
		echo "ssh to any host except cfg and execute command, if on salt commands run locally"

	elif [ "$2" = "LOG" ]; then
		echo "log"
	fi
}



fuction pullresults {
	echo "scp from targetdir on target host to $localtargetdir"

}



# a=(foo bar "foo 1" "bar two")  #create an array
#b=("${a[@]}")                  #copy the array in another one 

#for value in "${b[@]}" ; do    #print the new array 
#echo "$value" 
#done   
