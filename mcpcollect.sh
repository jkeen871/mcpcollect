#!/bin/bash


function usage(){
	echo "    mcpcollector -c <nova|neutron|stacklight|ceph>"
	echo ""
	echo "    -c component"
	echo "    -i instance id"

}


while getopts "hc:n:e:" arg; do
  case $arg in
	  c);;
    i);;
  esac
done





## MCP Collector ##

targetdir="/tmp/mcpcollector"

[[ -d dir ]] || mkdir $targetdir


### Ceph General ###
cephLogDir="/var/log/ceph"
cephOsdDir="/var/log/ceph"
declare -a cephCmd ("ceph -s" "ceph health")
declare -a cephLog ("ceph.log")

### Ceph OSD ###
declare -a cephOsdLog 

### Nova ###
declare -a cmd_nova ("nova hypervisor-list" "nova list --fields name,networks,host --all-tenants")
declare -a logs_nova ("/var/log/nova")
declare -a logs_api_nova ("/var/log/nova/nova-api")

### Reclas Model ###
declare -a reclassGet ("tar -zcvf `date '+%Y%m%d%H%M%S'`.tar.gz /var/salt/reclass $targetdir")



## Run Function ##

# RunCommands <targethost> <command|log> <commandString|logString>


