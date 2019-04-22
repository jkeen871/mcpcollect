#!/bin/bash

#aodh.server
#apache.server
#aptly.publisher
#backupninja.client
#backupninja.server
#ceilometer.agent
#ceilometer.server
#ceph.client
#ceph.common
#ceph.mgr
#ceph.mon
#ceph.osd
#ceph.radosgw
#ceph.setup
#cinder.controller
#cinder.volume
#devops_portal.config
#docker.client
#docker.host
#elasticsearch.client
#elasticsearch.server
#fluentd.agent
#galera.master
#galera.slave
#gerrit.client
#git.client
#glance.server
#glusterfs.client
#glusterfs.server
#gnocchi.common
#gnocchi.server
#grafana.client
#grafana.collector
#haproxy.proxy
#heat.server
#heka.remote_collector
#horizon.server
#influxdb.relay
#influxdb.server
#java.environment
#jenkins.client
#keepalived.cluster
#keystone.client
#keystone.server
#kibana.client
#kibana.server
#libvirt.server
#linux.network
#linux.storage
#linux.system
#logrotate.server
#maas.cluster
#maas.region
#memcached.server
#mysql.client
#neutron.compute
#neutron.gateway
#neutron.server
#nginx.server
#nova.compute
#nova.controller
#ntp.client
#ntp.server
#openldap.client
#openssh.client
#openssh.server
#panko.server
#prometheus.alertmanager
#prometheus.collector
#prometheus.pushgateway
#prometheus.relay
#prometheus.server
#rabbitmq.cluster
#rabbitmq.server
#reclass.storage
#redis.cluster
#redis.server
#rsyslog.client
#rundeck.client
#rundeck.server
#salt.api
#salt.control
#salt.master
#salt.minion
#sphinx.server
#telegraf.agent
#telegraf.remote_agent
#xtrabackup.client
#xtrabackup.server


while getopts "c:h:g::s:layp" arg; do
        case $arg in
                c) componentFlag=true; componentvalues+=("$OPTARG");;
                h) targetHostFlag=true;targethostvalues+=("$OPTARG");;
                s) confighostFlag=true;confighost="$OPTARG";;
                a) alllogsFlag=true;;
                g) saltgrainsFlag=true;saltgrain+=("$OPTARG");;
                y) skipconfirmationFlag=true;;
                p) previewFlag=true;;
		q) queryflag=true;;
		l) runlocalFlag=true;;
		*) usage;;
                \?) usage;;
        esac
done
datestamp=`date '+%Y%m%d%H%M%S'`
localbasedir="/tmp/mcpcollect"
localtargetdir="$localbasedir/$confighost/$datestamp"
keystonercv3="/root/keystonercv3"
keystonercv2="/root/keystonerc"
remotebasedir="/tmp/mcpcollect"
remotetargetdir="$remotebasedir/$datestamp"
green='\e[1;92m'
nocolor='\033[0m'
red='\e[1;31m'

function usage {
        echo ""
        echo "    mcpcollector -c <nova|neutron|stacklight|ceph>"
        echo ""
	echo "    -a -- All logs -- Collect all logs from the specified log directory."
        echo "          The default is to only collect *.log files, setting this switch will collect"
        echo "          all files in the log directory. "
        echo "          This option will not work against component general, because that will collect all logs in"
        echo "          /var/log and could potentially consume too much disk on certain nodes"
        echo ""
        echo "    -c -- <component>"
        echo "          ceph-mon -- Retrieves ceph data from controller nodes"
        echo "          horizon -- Retrieves horizon data from controller nodes"
        echo "          keystone -- Retrieves keystone data from controller nodes"
        echo "          cinder-controller -- Retrieves cinder data from contoller nodes"
        echo "          nova-controller -- Retrieves nova data from controller nodes"
        echo "          neutron-controller -- Retrieves neutron data from controller nodes"
        echo "          reclass -- Retrieves reclass model from cfg/salt node"
        echo ""
        echo "    -g -- <salt grain>"
        echo "          Specify the salt grain name (ceph.mon, ceph.common) to collect information from"
        echo "          Hosts from grain are superceeded by host provided in -h"
        echo ""
        echo "    -h -- <target hostname or IP>"
        echo "          The MCP host name of the systems you want to collect information from"
        echo "          * Multiple host selections are supported (-h host1 -h host2)"
        echo ""
	echo "    -l -- Run on your localhost with ssh access to a Cfg or Salt node.  This option also requires the -s switch"
        echo ""
	echo "    -p -- Preview only --Do not collect any files, previews what will be collected for each grain"
	echo ""
        echo "    -s -- <cfg node or salt node>"
        echo "          REQUIRED : hostname or IP of the salt of config host."
        echo ""
        echo "    -y -- Autoconfirm -- Do not print confirmation and summary prompt"

        exit

}


function assignArrays {
component=$1

case $component in
        general)
                declare -g Log=(        "/var/log/syslog"                 \
s                                )
                declare -g Cfg=(        "/etc/hosts"                   \
                                )
                declare -g Svc=(        "systemctl status ntpd.service"                              \
                                )
                declare -g Cmd=(        "free -h"    \
                                        "df -h" \
                                        "uname -a" \
                                        "ntpq -p" \
                                        "dmesg" \
                                )
        ;;

        keystone.server)
                declare -g Log=(        "/var/log/keystone/"                       \
                                )
                declare -g Cfg=(        "/etc/keystone/"                   \
                                )
                declare -g Svc=(        "systemctl status apache2.service"                              \
                                )
                declare -g Cmd=(        "netstat -nltp | grep apache2"           \
                                )
        ;;
        keystone.client)
                declare -g Log=(        "/var/log/keystone/"                       \
                                )
                declare -g Cfg=(        "/etc/keystone/"                   \
                                )
                declare -g Svc=(        "systemctl status apache2.service"                              \
                                )
                declare -g Cmd=(                                                      \
                                )
        ;;
        horizon.server)
                declare -g Log=(        "/var/log/horizon/"                        \
                                        "/var/log/apache2/"
                                )
                declare -g Svc=(        "systemctl status apache2.service"                              \
                                )
                declare -g Cmd=(        "netstat -nltp | egrep apache2"              \
                                )
                declare -g Cfg=(        "/etc/apache2/"                                \
                                )
        ;;
        neutroncontroller)
                declare -g Log=(        "/var/log/neutron/"                            \
                                )
                declare -g Cfg=(        "/etc/neutron/plugins/ml2/ml2_conf.ini"         \
                                        "/etc/neutron/plugins/ml2/openvswitch_agent.ini"\
                                )
                declare -g Svc=(        "systemctl status neutron-openvswitch-agent.service"            \
                                )
                declare -g Cmd=(        "neutron agent-list"                            \
                                )
        ;;
        cindercontroller)
                declare -g Log=(        "/var/log/cinder/"                         \
                                )
                declare -g Cfg=(        "/etc/cinder/"                                 \
                                )
                declare -g Svc=(        "systemctl status cinder-scheduler.service"                     \
                                        "systemctl status cinder-volume.service"                        \
                                )
                declare -g Cmd=(        "ls /var/lib/cinder/volumes"                    \
                                )
        ;;
        ceph.mon)
                declare -g Cmd=(        "ceph --version"                                       \
                                        "ceph tell osd.* version"                       \
                                        "ceph tell mon.* version"
                                        "ceph health detail"                            \
                                        "ceph -s"                                \
                                        "ceph df"                                       \
                                        "ceph pg dump | grep flags"                     \
                                        "ceph osd tree"                                 \
                                        "ceph osd getcrushmap -o /tmp/mcpcollect/compiledmap; crushtool -d /tmp/mcpcollect/compiledmap; rm /tmp/mcpcollect/compiledmap" \
                                )
                declare -g Log=(        "/var/log/ceph/"                        \ 
                                )
                declare -g Svc=(        "systemctl status ceph-mon.target"                                      \
                                        "systemctl status ceph-mgr.target"                                      \
                                        "systemctl status ceph.target"                                  \
                                )
                declare -g Cfg=(        "/etc/ceph/"                                   \
                                )
        ;;
        ceph.osd)
                declare -g Cmd=(        "ceph --version"                                       \
                                        "ceph tell osd.* version"                       \
                                        "ceph tell mon.* version"
                                        "dmesg"         \
                                        "ps -ef | grep osd"
                                        "netstat -p | grep ceph"        \
                                        "df -h"  \
                                        "mount" \
                                        "netstat -a | grep ceph"        \
                                        "netstat -l | grep ceph"        \
                                        "ls -altrn /var/run/ceph"       \
                                        "ceph osd dump | grep flags"
                                        "ceph health detail"                            \
                                        "ceph -s"                                \
                                        "ceph df"                                       \
                                        "ceph pg dump"                                  \
                                        "ceph osd tree"                                 \
                                        "ceph osd getcrushmap -o /tmp/compiledmap; crushtool -d /tmp/compiledmap; rm /tmp/compiledmap" \
                                )
                declare -g Log=(        "/var/log/ceph/"                        \
                                )
                declare -g Svc=(        "systemctl status ceph-mon.target"                                      \
                                        "systemctl status ceph-mgr.target"                                      \
                                        "systemctl status ceph.target"                                  \
                                )
                declare -g Cfg=(        "/etc/ceph/"                                   \
                                )
        ;;

        nova.controller)
                ### Nova ###
                declare -g Cmd=(        "nova hypervisor-list"                          \
                                        "nova list --fields name,networks,host --all-tenants" \
                                )
                declare -g Log=(        "/var/log/nova/"                           \
                                        "/var/log/libvirt/"                                \
                                )
                declare -g Svc=(        "systemctl status nova-api.service"                             \
                                        "systemctl status nova-conductor.service"                       \
                                        "systemctl status nova-scheduler.service"                       \
                                )

                declare -g Cfg=(        "/etc/nova/"                           \
                                )

        ;;
        reclass)
                ### Reclas Model ###
                declare -a Cmd=("tar -zcvf reclass-$datestamp.tar.gz /var/salt/reclass $targetdir")
        ;;
esac
}

function abortprompt {
 read -p " Do you want to continue? [y/n] " -n 1 -r
 echo -e "${nocolor}\n"
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
		echo ""
	else
                exit
        fi
}

function info {
        echo ""
        echo -e "${green}Info message :"
        leninfo=${#infomessage[@]}
        for (( i=0; i<${leninfomessage}; i++ ));
        do
                printf '        %s\n' "${infomessage[$i]}"
        done
        echo -e "${nocolor}"
	infomessage=()
}

function warning {
        echo ""
        echo -e "${green}Warning message :"
	lenwarningmessage=${#warningmessage[@]}
        for (( i=0; i<${lenwarningmessage}; i++ ));
        do
                printf '        %s\n' "${warningmessage[$i]}"
        done
	echo -e "${nocolor}"
	warningmessage=()
}

function abort {
	echo -e "${red} \n"
	echo "Exiting with error(s):" 
	lenabortmessage=${#abortmessage[@]}
	for (( i=0; i<${lenabortmessage}; i++ ));
	do
		printf '        %s\n' "${abortmessage[$i]}"
	done
	echo -e "${nocolor} \n"
	abortmessage=()
	exit
}

function collectFiles {
	collectType=$1
	echo "Collecting $component files ($collectType) from $targethost"
	tarname="$targethost-$component-files-$datestamp.tar.gz"

	if [ "$collectType" = "log" ]; then
		sourceFile=("${Log[@]}")
	elif [ "$collectType" = "cfg" ]; then
		sourceFile=("${Cfg[@]}")
	elif [ "$collectType" = "all" ]; then
		sourceFile="`echo ${Cfg[@]} ${Log[@]}`"
	fi
	sshCollectFiles='sudo salt "*'$targethost'*" cmd.run "mkdir -p '$remotetargetdir';tar czf '$remotetargetdir'/'$tarname' '$sourceFile'";scp -o StrictHostKeyChecking=no -r '$targethost':'$remotetargetdir'/'$tarname' '$remotetargetdir'/'
	if [ $runlocalFlag ]; then
		ssh -q -oStrictHostKeyChecking=no $confighost $sshCollectFiles
	else
		eval $sshCollectFiles
	fi
	echo "   complete."
}

function cleanTargethost {
	echo "Cleaning temproary files from $targethost,$component..."
	sshCleanTarget='sudo salt "*'$targethost'*" cmd.run "rm -fR '$remotebasedir'"'
	if [ $runlocalFlag ]; then
		ssh -q -oStrictHostKeyChecking=no $confighost $sshCleanTarget
	else
                eval $sshCleanTarget
        fi
	echo "   complete."
}

function cleanCfgHost {
        echo "Cleaning temporary files from $confighost,$component..."
        sshCleanCfg='rm -fR '$remotebasedir''
        	ssh -q -oStrictHostKeyChecking=no $confighost $sshCleanCfg
	echo "   complete."
}

function transferResultsCfg {
	echo "Transferring results from $targethost to $confighost,$component..."
	localdestdir="$remotetargetdir/$targethost"
	sshXferResultsCfg='mkdir -p '$localdestdir';scp -o StrictHostKeyChecking=no -r '$targethost':'$remotetargetdir'/* '$localdestdir
	if [ $runlocalFlag ]; then
		ssh -q -oStrictHostKeyChecking=no $confighost $sshXferResultsCfg
	else
		eval $sshXferResultsCfg
	fi
	echo "   complete."
}

function transferResultsLocal {
	#compress tmpdir and copy to localhost
        echo "Transferring $component results from $confighost to localhost..."
	localdestdir="$localtargetdir/$targethost"
	mkdir -p $localdestdir
	tarname="$targethost-$component-$datestamp.tar.gz"
	ssh -q -o StrictHostKeyChecking=no $confighost "cd $remotetargetdir/$targethost;tar -czf $tarname *"
	scp -q -o StrictHostKeyChecking=no -r $confighost:$remotetargetdir/$targethost/$tarname $localdestdir/
	echo "   complete."
}

function executeRemoteCommands {
	commandType=$1
	sshExecuteRemoteCommands="if [ -f $keystonercv3 ]; then . $keystonercv3; elif [ -f $keystonerc ] ; then . $keystonerc; fi;"
	declare -a remoteCmds
	if [ "$commandType" = "svc" ]; then
		remoteCmds=("${Svc[@]}")
		label="collect services results"
	elif [ "$commandType" = "cmd" ]; then
		remoteCmds=("${Cmd[@]}")
		label="collect command results"
	elif [ "$commandType" = "cli" ]; then
		remoteCmds=("${Cli[@]}")
		label="collect commands provided from cli (${Cli[@]})"
	fi

	### Exit function if array is emtpy
	if [ ${#remoteCmds[@]} = 0 ]; then 
		echo -e "${green} Array for type $commandType is empty.${nocolor}\n"
		return 1
	fi

	echo "Executing commands to $label ($commandType) from $targethost"
        lenCmd=${#remoteCmds[@]}
	countCmd=1
        for (( i=0; i<${lenCmd}; i++ ));
        do
                sshExecuteRemoteCommands+="echo '=';echo '==== ${remoteCmds[$i]}====';echo '=';${remoteCmds[$i]}"
                if [ $countCmd -lt $lenCmd ]; then
                        sshExecuteRemoteCommands+=";"
                fi
                ((countCmd++))
        done
	localdestdir="$remotetargetdir/$targethost"
	sshExecuteRemoteCommands='mkdir -p '$localdestdir'/output; sudo salt "*'$targethost'*" cmd.run "'$sshExecuteRemoteCommands'" > '$localdestdir'/output/'$targethost'-'$component'-'$commandType''
#        sshExecuteRemoteCommands='mkdir -p '$localdestdir'/output-'$datestamp'; sudo salt "*'$targethost'*" cmd.run "'$sshExecuteRemoteCommands'" > '$localdestdir'/output-'$datestamp'/'$targethost'-'$component'-'$commandType'-'$datestamp''
	if [ $runlocalFlag ]; then
		ssh -q -oStrictHostKeyChecking=no $confighost $sshExecuteRemoteCommands
	else
		eval $sshExecuteRemoteCommands
	fi
}

function scrubArrays {

	 lenLog=${#Log[@]}
	 for (( i=0; i<${lenLog}; i++ ));
                do
                        if [ "${Log[$i]}" = " " ] ; then
                                unset Log[$i]
                        fi
                done
	lenCmd=${#Cmd[@]}
	for (( i=0; i<${lenCmd}; i++ ));
                do
                        if [ "${Cmd[$i]}" = " " ] ; then
                                unset Cmd[$i]
                        fi
                done
	lenSvc=${#Svc[@]}
	for (( i=0; i<${lenSvc}; i++ ));
                do
                        if [ "${Svc[$i]}" = " " ] ; then
                                unset Svc[$i]
                        fi
                done
	lenCfg=${#Cfg[@]}
	for (( i=0; i<${lenCfg}; i++ ));
                do
                        if [ "${Cfg[$i]}" = " " ] ; then
                                unset Cfg[$i]
                        fi
                done
}


function getTargetHostByGrains() {
	grain=$1
	sshGetHostByGrains="sudo salt --out txt  '*' grains.item roles  | grep '$grain' | awk -F':' '{printf \$1 \" \" }'"
	if [ $runlocalFlag ]; then
		result=`ssh -q mmo-mediakind-stg-cfg01 $sshGetHostByGrains`
	else
		eval $sshGetHostByGrains
	fi
	echo $result
}

containsElement () {
  local e match="$1"
  shift
  for e; do [[ "$e" == *"$match"* ]] && return 0; done
  return 1
}

function hostsAssociatedWithSaltGrain {
	grain=$1
	echo "Collecting hosts associated with $grain.."
	grainhostvalues=($(getTargetHostByGrains "$grain"))
	
	if [ $targetHostFlag ]; then
		targethostloopvalues=()
		for x in ${targethostvalues[@]}
		do	
			containsElement "$x" "${grainhostvalues[@]}"
			containsElementResult=$?
	
			if [ $containsElementResult = 0 ]; then
				targethostloopvalues+=("$x")
			fi
		done
	else
		targethostloopvalues=(${grainhostvalues[@]})
	fi
	}


function collect {
			targethost=$1
			component=$2
			echo "Collecting results for target host $targethost, $component"
                        echo "==========================================================="
                        executeRemoteCommands "cmd"
                        executeRemoteCommands "svc"
                        collectFiles "all"
                        transferResultsCfg
			cleanTargethost
			if [ $runlocalFlag ]; then
	                        transferResultsLocal
        	                cleanCfgHost	
			fi

                        echo "Collection complete for $targethost"
                        echo "-----"
                        echo ""

}


function main {
	
	targethostloopvalues=(${targethostvalues[@]});

	if [ "$confighost" != "" ]; then
		if [ ! -d "$localtargetdir" ]; then
			echo $localtargetdir
			mkdir -p $localtargetdir
			### Check for error creating directory
		fi
	fi

	if [ ! $confighostFlag ] && [ $runlocalFlag ];  then
		echo " USAGE ERROR  -s is a required switch"
		usage
	fi

        if [ ${#componentvalues[@]} = 0 ] && [ ${#saltgrain[@]} != 0 ]; then
                componentvalues=(${saltgrain[@]})
		#append components and apply uniq
        fi

	for y in ${componentvalues[@]};
        do
		component=$y
		if [ $saltgrainsFlag ]; then
			hostsAssociatedWithSaltGrain "$component"
		fi

		if [ ${#infomessage[@]} != 0 ]; then
			info
		fi

		if [ ${#warningmessage[@]} != 0 ]; then
			warning
		fi
		if [ ${#abortmessage[@]} != 0 ]; then
			abort
		fi

		if [ ${#componentvalues[@]} = 0 ] && [ ${#saltgrain[@]} != 0 ]; then
			componentvalues=(${saltgrain[@]})

		fi
		if [ $previewFlag ] || [ $skipconfirmationFlag ] ; then
			noconfirm=true
		fi
		assignArrays "$component"	
		scrubArrays
		logWildCards
		componentSummary
		for x in ${targethostloopvalues[@]}; 
		do
			targethost=$x
			component="$y"
			if [ ! $previewFlag ]; then
				collect $targethost $component 
			fi
			

		done
	done

}

function logWildCards() {
# Manipulate the Log array for all logs or not
	if [ ! $alllogsFlag  ] ; then
	       if [ "$component" != "general" ]; then
        	lenLog=${#Log[@]}
                countLog=1
                for (( i=0; i<${lenLog}; i++ ));
                	do
                        	Log[$i]+="*.log"
                        done

		fi
	fi
}

function componentSummary () {
	echo ""
	printf '%s' "Summary for hosts : "
	printf '%s, ' "${targethostloopvalues[@]}"| cut -d "," -f 1-${#targethostloopvalues[@]}
	printf 'Component : %s\nDatestamp : %s\n' "$component" "$datestamp" 
	printf '%s \n' "====================================================="
	printf '%s ' "Commands  :"
	printf '%s, ' "${Cmd[@]}" | cut -d "," -f 1-${#Cmd[@]}
	printf '%s ' "Logs      :"
	printf '%s, ' "${Log[@]}" | cut -d "," -f 1-${#Log[@]}
	printf '%s ' "Services  :"
	printf '%s, ' "${Svc[@]}"| cut -d "," -f 1-${#Svc[@]} 
	printf '%s ' "Configs   :"
	printf '%s, ' "${Cfg[@]}"| cut -d "," -f 1-${#Cfg[@]}
	printf '%s \n' "-----------------------------------------------------"
	echo ""
	if [ ! $noconfirm ]; then
		abortprompt
	fi 
}



main


