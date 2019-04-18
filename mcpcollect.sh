#!/bin/bash
keystonercfile="/root/keystonercv3"
remotetargetdir="/tmp/mcpcollect"
localtargetdir="/tmp/mcpcollect"

sshCmd=". $keystonercfile;"


function usage(){
	echo "    mcpcollector -c <nova|neutron|stacklight|ceph>"
	echo ""
	echo "    -C confighost"
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

while getopts "C:c:h:o:t:i:r:" arg; do
  case $arg in
	  c) component="$OPTARG";;
	  h) targethost="$OPTARG";;
	  C) confighost="$OPTARG";;
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

if [[ ! -e "$targetdir" ]]; then
	mkdir -p $targetdir
	### Check for error creating directory
fi

case $component in 
	keystone) 
		declare -a Log=(	"/var/log/keystone/*.log" 			\
				)
		declare -a Cfg=(	"/etc/keystone/keystone.conf" 			\
				)
		declare -a Svc=(	"apache2.service" 				\
				)
		declare -a Cmd=(	""						\
				)
	;;
	horizon)
		declare -a Log=(	"/var/log/horizon/*.log" 			\
				)
		declare -a Svc=(	"apache2.service" 				\
				)
		declare -a Cmd=(	"netstat -nltp | egrep ':80|:443'" 		\
				)
		declare -a Cfg=(	"/etc/apache/*" 				\
				)
	;;	
	neutron)
		declare -a Log=(	"/var/log/neutron/*" 				\
				)
		declare -a Cfg=(	"/etc/neutron/plugins/ml2/ml2_conf.ini" 	\
					"/etc/neutron/plugins/ml2/openvswitch_agent.ini"\
				)
		declare -a Svc=(	"neutron-openvswitch-agent.service"   		\
				)
		declare -a Cmd=(	"neutron agent-list"				\
				)
	;;
	cinder)
		declare -a Log=(	"/var/log/cinder/cinder.log"			\
				)
		declare -a Cfg=(	"/etc/cinder/*" 				\
				)
		declare -a Svc=(	"cinder-scheduler.service" 			\
					"cinder-volume.service" 			\
				)
		declare -a Cmd=(	"ls /var/lib/cinder/volumes" 			\
				)
	;;
	ceph) 
		### Ceph General ###
		cephLogDir="/var/log/ceph"
		cephOsdDir="/var/log/ceph"
		declare -a Cmd=(	"ceph -s"					\
					"ceph health detail" 				\
				       	"ceph --version" 				\
					"ceph df" 					\
					"ceph pg dump" 					\
					"ceph osd tree" 				\
				)
		declare -a Log=(	"ceph.log"					\	
				)
	;;
	cephallnodes) 
		### Run this on all ceph nodes"
		declare -a Cmd=(	"service ceph status" 				\ 
				)
		declare -a Log=(	"none"						\
				) 
		declare -a Cfg=(	"/etc/ceph/ceph.conf"				\
				)
	;;

	cephosd) 
		### Ceph OSD ###
		declare -a Log=("none")
	;;
	nova) 	
		### Nova ###
		declare -a Cmd=(	"nova hypervisor-list"				\
					"nova list --fields name,networks,host --all-tenants" \
				)
		declare -a Log=(	"/var/log/nova/*.log" 				\
					"/var/log/libvirt/*.log" 				\
				)
		declare -a Svc=(	"nova-api.service" 				\
					"nova-conductor.service" 			\
					"nova-scheduler.service" 			\
				)

		declare -a Cfg=(	"/etc/nova/*" 				\
				)

	;;
	reclass) 
		### Reclas Model ###
		declare -a Cmd=("tar -zcvf `date '+%Y%m%d%H%M%S'`.tar.gz /var/salt/reclass $targetdir")
	;;
	*) 
		usage
	;;
esac




## Run Function ##

# RunCommands <targethost> <command|log> <commandString|logString>

function collectdata {
	targethost=$1
	commandorlog=$2 
	if [ "$2"="CMD" ]; then
		echo "ssh to any host except cfg and execute command, if on salt commands run locally"

	elif [ "$2"="LOG" ]; then
		echo "log"
	fi
}



function pullresults {
	echo "scp from targetdir on target host to $localtargetdir"

}

echo ""
printf '%s:     %s\n' "Target host" "$targethost"
printf '%s:     %s\n' "Component" "$component"
printf '%s\n' "Executing:"
printf '	%s\n' "${Cmd[@]}"
printf '%s\n' "Collecting logs:"
printf '	%s\n' "${Log[@]}"
printf '%s\n' "Checking these services"
printf '        %s\n' "${Svc[@]}"
printf '%s\n' "Collecting these configuration files:"
printf '        %s\n' "${Cfg[@]}"

echo ""


function collect {
        collectTarget=$1
        collectName=$2

        ############ Collect files #########
        # TODO:
        # *** Clean up remote-target dir

        sshCmd='sudo salt "*'$targethost'*" cmd.run "mkdir -p '$remotetargetdir';tar cvzf '$remotetargetdir'/'$component'-'$collectName'.tar.gz '$collectTarget'";scp -r '$targethost':'$remotetargetdir'/* '$remotetargetdir'/'
#       echo $sshCmd
        ssh $confighost $sshCmd
}

function cleantargethost {
        sshCmd='sudo salt "*'$targethost'*" cmd.run "rm -fR '$remotetargetdir'"'
        ssh $confighost $sshCmd
#       echo $sshCmd

}

function transferResults {
        sshCmd='mkdir -p '$remotetargetdir';scp -r '$targethost':'$remotetargetdir'/* '$remotetargetdir
        ssh $confighost $sshCmd
#       echo $sshCmd
}









############## Execute Commands ################

lenCmd=${#Cmd[@]}
countCmd=1
for (( i=0; i<${lenCmd}; i++ ));
do

	sshCmd+="echo '=';echo '==== ${Cmd[$i]}====';echo '=';${Cmd[$i]}"
	if [ $countCmd -lt $lenCmd ]; then
		sshCmd+=";"
	fi
#	echo $sshCmd
	((countCmd++))

done
sshCmd='mkdir -p '$remotetargetdir';date > '$remotetargetdir'/'$component'; sudo salt "*'$targethost'*" cmd.run "'$sshCmd'" >> '$remotetargetdir'/'$component'-cmd'
ssh $confighost $sshCmd


#### Check Services ####
sshCmd=""
lenSvc=${#Svc[@]}
countSvc=1
for (( i=0; i<${lenSvc}; i++ ));
do

        sshCmd+="echo '=';echo '==== ${Svc[$i]}====';echo '=';systemctl status ${Svc[$i]}"
        if [ $countSvc -lt $lenSvc ]; then
                sshCmd+=";"
        fi
#        echo $sshCmd
        ((countSvc++))

done
sshCmd='sudo salt "*'$targethost'*" cmd.run "'$sshCmd'" >> '$remotetargetdir'/'$component'-svc'
echo $sshCmd
#>i> '$remotetargetdir'/'$component
ssh $confighost $sshCmd




#### Collect data ####

collect $Log "Logs"
collect $Cfg "Confs"
transferResults
cleantargethost
