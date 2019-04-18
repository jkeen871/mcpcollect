#!/bin/bash

keystonercfile="/root/keystonercv3"
remotetargetdir="/tmp/mcpcollect"

#sshCmd=". $keystonercfile;"


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
	  c) component+=("$OPTARG");;
	  h) targethostvalues+=("$OPTARG");;
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

localtargetdir="/tmp/mcpcollect/$confighost"
if [ "$component" == *"ctl"* ]; then
	sshCmd=". $keystonercfile;"
fi


if [[ ! -e "$localtargetdir" ]]; then
	mkdir -p $localtargetdir
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
					"/var/log/apache2/*.log"
				)
		declare -a Svc=(	"apache2.service" 				\
				)
		declare -a Cmd=(	"netstat -nltp | egrep ':80|:443'" 		\
				)
		declare -a Cfg=(	"/etc/apache2/*" 				\
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
		declare -a Log=(	"/var/log/cinder/*.log"				\
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
		declare -a Cmd=(	"ceph -s"					\
					"ceph health detail" 				\
				       	"ceph --version" 				\
					"ceph df" 					\
					"ceph pg dump" 					\
					"ceph osd tree" 				\
				)
		declare -a Log=(	"/var/log/ceph/*.log"				\	
				)
		declare -a Svc=(	"ceph-mon.target"					\
					"ceph-mgr.target"					\
					"ceph.target"					\
				)
		declare -a Cfg=(	"/etc/ceph/*"					\
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


echo ""
printf '%s: %s\tcomponent: %s\n' "Target host" "$targethost" "$component"
printf '%s \n' "====================================================="
printf '%s\n' "Will execute commands:"
printf '	%s\n' "${Cmd[@]}"
printf '%s\n' "Will collect logs:"
printf '	%s\n' "${Log[@]}"
printf '%s\n' "Will check status of services:"
printf '        %s\n' "${Svc[@]}"
printf '%s\n' "Will collect config files:"
printf '        %s\n' "${Cfg[@]}"
printf '%s \n' "-----------------------------------------------------"
echo ""
read -p "Do you want to continue? [y/n] " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Nn]$ ]]
then
	exit
fi

echo "${targethostvalues[@]}"
echo ${#targethostvalues[@]}

function collectFiles {
	collectType=$1
        echo "Collecting $collectType"
        sshCmd=""
	tarname="$targethost-$component-files.tar.gz"
	if [ "$collectType" = "Log" ]; then
                        sourceFile=${Log[@]}
	elif [ "$collectType" = "Cfg" ]; then
                        sourceFile=${Cfg[@]}
	elif [ "$collectType" = "All" ]; then
			sourceFile="`echo ${Log[@]}` `echo  ${Cfg[@]}`"
	fi
	
	sshCmd='sudo salt "*'$targethost'*" cmd.run "mkdir -p '$remotetargetdir';tar czf '$remotetargetdir'/'$tarname' '$sourceFile'";scp -o StrictHostKeyChecking=no -r '$targethost':'$remotetargetdir'/'$tarname' '$remotetargetdir'/'
	ssh -q -oStrictHostKeyChecking=no $confighost $sshCmd
	echo "   complete."
}



function cleanTargethost {
	echo "Cleaning target host..."
	sshCmd='sudo salt "*'$targethost'*" cmd.run "rm -fR '$remotetargetdir'"'
        ssh -q -oStrictHostKeyChecking=no $confighost $sshCmd
	echo "   complete."
}

function cleanCfgHost {
        echo "Cleaning CFG host..."
        sshCmd='rm -fR '$remotetargetdir''
        ssh -q -oStrictHostKeyChecking=no $confighost $sshCmd
	echo "   complete."
}


function transferResultsCfg {
	echo "Transferring results to cfg node..."
	sshCmd='mkdir -p '$remotetargetdir';scp -o StrictHostKeyChecking=no -r '$targethost':'$remotetargetdir'/* '$remotetargetdir
        ssh -q -oStrictHostKeyChecking=no $confighost $sshCmd
	echo "   complete."
}

function transferResultsLocal {
        echo "Transferring to localhost..."
	mkdir -p $localtargetdir
	tarname="$targethost-$component-`date '+%Y%m%d%H%M%S'`.tar.gz"
	ssh -q -o StrictHostKeyChecking=no $confighost "cd $remotetargetdir;tar -czf $tarname *"
	scp -q -o StrictHostKeyChecking=no -r $confighost:$remotetargetdir/$tarname $localtargetdir/
	echo "   complete."
}


function executeCommands {
	echo "Executing commands"
	lenCmd=${#Cmd[@]}
	countCmd=1
	for (( i=0; i<${lenCmd}; i++ ));
	do
		sshCmd+="echo '=';echo '==== ${Cmd[$i]}====';echo '=';${Cmd[$i]}"
		if [ $countCmd -lt $lenCmd ]; then
			sshCmd+=";"
		fi
		((countCmd++))
	done
	sshCmd='mkdir -p '$remotetargetdir'; sudo salt "*'$targethost'*" cmd.run "'$sshCmd'" > '$remotetargetdir'/'$targethost'-'$component'-cmd'
	ssh -q -oStrictHostKeyChecking=no $confighost $sshCmd
}

function getServices {
	echo "Collecting Services"
	sshCmd=""
	lenSvc=${#Svc[@]}
	countSvc=1
	for (( i=0; i<${lenSvc}; i++ ));
	do

		sshCmd+="echo '=';echo '==== ${Svc[$i]}====';echo '=';systemctl status ${Svc[$i]}"
		if [ $countSvc -lt $lenSvc ]; then
			sshCmd+=";"
		fi
		((countSvc++))

	done
	sshCmd='sudo salt "*'$targethost'*" cmd.run "'$sshCmd'" > '$remotetargetdir'/'$targethost'-'$component'-svc'
	ssh -q -oStrictHostKeyChecking=no $confighost $sshCmd
}


function fullRun {
	echo "Collectin results for target host $targethost"
	echo "==========================================================="
	executeCommands
	getServices
	collectFiles "All"
	#collectFiles "Log"
	#collectFiles "Cfg"
	transferResultsCfg
	transferResultsLocal
	cleanTargethost
	cleanCfgHost
	echo "Collection complete for $targethost"
	echo "-----"
	echo ""
}


for x in ${targethostvalues[@]}; 
do 
	targethost=$x
	fullRun
done
