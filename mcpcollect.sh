#!/bin/bash

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
	ssh -q -oStrictHostKeyChecking=no $confighost $sshCollectFiles
	echo "   complete."
}



function cleanTargethost {
	echo "Cleaning temproary files from $targethost,$component..."
	sshCleanTarget='sudo salt "*'$targethost'*" cmd.run "rm -fR '$remotetargetdir'"'
        ssh -q -oStrictHostKeyChecking=no $confighost $sshCleanTarget
	echo "   complete."
}

function cleanCfgHost {
        echo "Cleaning temporary files from $confighost,$component..."
        sshCleanCfg='rm -fR '$remotetargetdir''
        ssh -q -oStrictHostKeyChecking=no $confighost $sshCleanCfg
	echo "   complete."
}


function transferResultsCfg {
	echo "Transferring results from $targethost to $confighost,$component..."
	sshXferResultsCfg='mkdir -p '$remotetargetdir';scp -o StrictHostKeyChecking=no -r '$targethost':'$remotetargetdir'/* '$remotetargetdir
        ssh -q -oStrictHostKeyChecking=no $confighost $sshXferResultsCfg
	echo "   complete."
}

function transferResultsLocal {
        echo "Transferring $component results from $confighost to localhost..."
	mkdir -p $localtargetdir
	tarname="$targethost-$component-$datestamp.tar.gz"
	ssh -q -o StrictHostKeyChecking=no $confighost "cd $remotetargetdir;tar -czf $tarname *"
	scp -q -o StrictHostKeyChecking=no -r $confighost:$remotetargetdir/$tarname $localtargetdir/
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
        sshExecuteRemoteCommands='mkdir -p '$remotetargetdir'; sudo salt "*'$targethost'*" cmd.run "'$sshExecuteRemoteCommands'" > '$remotetargetdir'/'$targethost'-'$component'-'$commandType'-'$datestamp''
        ssh -q -oStrictHostKeyChecking=no $confighost $sshExecuteRemoteCommands
}


function fullRun {
	echo "Collecting results for target host $targethost"
	echo "==========================================================="
	executeRemoteCommands "cmd"
	executeRemoteCommands "svc"
	collectFiles "all"
	transferResultsCfg
	transferResultsLocal
	cleanTargethost
	cleanCfgHost
	echo "Collection complete for $targethost"
	echo "-----"
	echo ""
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

function confirmation {
	# Manipulate the Log array for all logs or not.
	scrubArrays
	if [ "$alllogs" = "0" ]; then
	    lenLog=${#Log[@]}
                countLog=1
                for (( i=0; i<${lenLog}; i++ ));
                do
                        Log[$i]+="*.log"
		done
	fi

	echo ""
	printf 'Target Host(s) : %s\tComponent : %s\tAll Logs : %s\n' "$targethost" "$component"  "$alllogs"
	printf '%s \n' "====================================================="
	printf '%s ' "Commands  :"
	printf '        %s,\n' "${Cmd[*]}"
	printf '\n'
	printf '%s ' "Logs      :"
	printf '        %s\n' "${Log[*]}"
	printf '\n'
	printf '%s ' "Services  :"
	printf '        %s\n' "${Svc[*]}"
	printf '\n'
	printf '%s ' "Configs   :"
	printf '        %s\n' "${Cfg[*]}"
	printf '\n'
	printf '%s \n' "-----------------------------------------------------"
	echo ""
}

function usage(){
	echo ""
        echo "    mcpcollector -c <nova|neutron|stacklight|ceph>"
        echo ""
        echo "    -c <component>"
	echo "		ceph-mon -- Retrieves ceph data from controller nodes"
	echo "		horizon -- Retrieves horizon data from controller nodes"
	echo "		keystone -- Retrieves keystone data from controller nodes"
	echo "		cinder-controller -- Retrieves cinder data from contoller nodes"
	echo "		nova-controller -- Retrieves nova data from controller nodes"
	echo "		neutron-controller -- Retrieves neutron data from controller nodes"
	echo "		reclass -- Retrieves reclass model from cfg/salt node"
        echo "    -s <cfg node or salt node>"
        echo "    -h <target hostname or IP>"
	echo "    -a all logs -- The default is to only collect *.log files, setting this switch will collect"
	echo "			all files in the log directory"
	echo ""
	exit

}


alllogs=0
while getopts "c:h:s:a" arg; do
	case $arg in
		c) componentvalues+=("$OPTARG");;
		h) targethostvalues+=("$OPTARG");;
		s) confighost="$OPTARG";;
		a) alllogs="1";;
		*) usage;;
		\?) usage;;
  	esac
done
localtargetdir="/tmp/mcpcollect/$confighost"
keystonercv3="/root/keystonercv3"
keystonercv2="/root/keystonerc"
remotetargetdir="/tmp/mcpcollect"
datestamp=`date '+%Y%m%d%H%M%S'`


if [[ ! -e "$localtargetdir" ]]; then
        mkdir -p $localtargetdir
        ### Check for error creating directory
fi


function assignArrays {
	component=$1
case $component in
        keystone)
                declare -g Log=(        "/var/log/keystone/"                       \
                                )
                declare -g Cfg=(        "/etc/keystone/keystone.conf"                   \
                                )
                declare -g Svc=(        "systemctl status apache2.service"                              \
                                )
                declare -g Cmd=(        ""                                              \
                                )
        ;;
        horizon)
                declare -g Log=(        "/var/log/horizon/"                        \
                                        "/var/log/apache2/"
                                )
                declare -g Svc=(        "systemctl status apache2.service"                              \
                                )
                declare -g Cmd=(        "netstat -nltp | egrep ':80|:443'"              \
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
	cephmon)
                ### Ceph General ###
                declare -g Cmd=(        "ceph --version"                                       \
					"ceph tell osd.* version"                       \
                                        "ceph tell mon.* version" 
					"ceph health detail"                            \
                                        "ceph -s"                                \
                                        "ceph df"                                       \
                                        "ceph pg dump"                                  \
                                        "ceph osd tree"                                 \
					"ceph osd getcrushmap -o /tmp/compiledmap; crushtool -d /tmp/compiledmap; rm /tmp/compiledmap" \
                                )
                declare -g Log=(		"/var/log/ceph/"			\       
                                )
                declare -g Svc=(        "systemctl status ceph-mon.target"                                      \
                                        "systemctl status ceph-mgr.target"                                      \
                                        "systemctl status ceph.target"                                  \
                                )
                declare -g Cfg=(        "/etc/ceph/"                                   \
                                )
        ;;
        novacontroller)
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
        *)
                usage
        ;;
esac
}


echo "ttt"
for x in ${targethostvalues[@]};
do
        targethost=$x

	for y in ${componentvalues[@]};
	do
		assignArrays "$y"
		confirmation
	done
done
	read -p "Do you want to continue? [y/n] " -n 1 -r
        if [[ $REPLY =~ ^[Yy]$ ]]
        then
                echo ""
        else
                exit
        fi


for x in ${targethostvalues[@]};
do
        targethost=$x
        for y in ${componentvalues[@]};
        do
                component="$y"
                echo "---"$component
		assignArrays "$component"
		fullRun
	done
done



