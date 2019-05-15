# mcpcollect
MCP Log/Diagnostics collection tool

Note : at the time of writing this config the list of salt grains and related commands and collection information is incomplete
       please contribute if you have something to add that will make this tool more useful.

Note : This tool is not designed to modify or change anything in your MCP cluster.  Any suggestions to use this tool to
       make system changes will be rejected.

MCPCOLLECT is a tool designed to easily gather logs from your Mirantis MCP environment for support or analysis. 

The general premis of this tool is to collect information based on the installed salt.grains. By specifying the
salt grain, mcpcollect will query the reclass model and select the appropriate targets hosts then collect config 
files, logs, and run a set of commands to collect statistics or information about the services related to the salt grain.

**Usage**

    mcpcollector -g <some.grain> -h <somehost> -h <anotherhost> 

    -a -- All logs -- Collect all logs from the specified log directory.
          The default is to only collect *.log files, setting this switch will collect
          all files in the log directory. 
          This option will not work against component general, because that will collect all logs in
          /var/log and could potentially consume too much disk on certain nodes

    -g -- <salt grain>
          Specify the salt grain name (ceph.mon, ceph.common) to collect information from
          Hosts from grain are superceeded by host provided in -h

    -h -- <target hostname or IP>
          The MCP host name of the systems you want to collect information from 
          	* Multiple host selections are supported (-h host1 -h host2)

    -i -- Collect IPMI logs.  Queries reclass to locate IPMI login information and connects to pull information.   Acceptable values are : dell.

    -p -- Preview only --Do not collect any files, previews what will be collected for each grain

    -s -- <cfg node or salt node>
    		 Run on your localhost with ssh access to a Cfg or Salt node. 
	 			* REQUIRED : hostname or IP of the salt of config host.
	 			* Note this requires ssh keys to be installed from your  local host to the cfg node, 
	 			or you will be prompted many times for your ssh password.

    -y -- Autoconfirm -- Do not print confirmation and summary prompt

1) Clone from git hub :
   
    git clone https://github.com/jkeen871/mcpcollect.git
             
2) Copy the script to your cfg node as a NON-ROOT user:

    scp mcpcollect.sh <hostname or ip of cfg host>:</Your/Home_Directory>
              
3) Execute the script from your home directory as a NON-ROOT user.

    mcpcollector -g <some.grain> 
    
  4) You will receive a header similar to the following.  Note that this provides the output of what logs,commands,services, and journalctl output will be gathered upon execution.
  The output will be written to /tmp/mcpcollect-username/
  
    Summary for component : cinder.controller
    Output  : /tmp/mcpcollect-yourusername/20190510202534
    Hosts : ctl01, ctl03, ctl02
    ===================================================== 
    Commands    : uname -a, df -h, mount, du -h --max-depth=1 /, lsblk, free -h, ifconfig, ps au --sort=-rss, salt-call pkg.list_pkgs versions_as_list=True, ntpq -p, cinder list
    Log Files   : /var/log/syslog, /var/log/cinder*.log
    Journalctl  : <none>
    Services    : cinder-scheduler, cinder-volume
    Configs     : /etc/hosts, /etc/cinder/
     ----------------------------------------------------- 
    
    Do you want to continue? [y/n] 

5) Once the script completes, Change directories to the path specified as by the script. /tmp/mcpcollect-yourusername/

    ├── ctl01  
    │   ├── ctl01-controller-files-20190510202534.tar.gz  
    │   ├── output  
    │   │   ├── ctl01-cinder.controller-cmd  
    │   │   └── ctl01-cinder.controller-svc  
    │   └── reclass-.tar.gz  
    ├── ctl02  
    │   ├── ctl02-cinder.controller-files-20190510202534.tar.gz  
    │   ├── output  
    │   │   ├── ctl02-cinder.controller-cmd  
    │   │   └── ctl02-cinder.controller-svc  
    │   └── reclass-.tar.gz  
    └── ctl03  
        ├── ctl03-cinder.controller-files-20190510202534.tar.gz  
        ├── output  
        │   ├── ctl03-cinder.controller-cmd  
        │   └── ctl03-cinder.controller-svc  
        └── reclass-.tar.gz  
        
A directory will be created for each host collected.

Files collected are compressed in hostname-salt.grain-files-xxxxx.tar.gz

The output of commands are saved to hostname/output/hostname-salt.grain-cmd

The output of services collected are saved to hostname/output/hostname-salt.grain-svc


These information is now available fo you to review or send to support.

To compress this information to provide to Mirantis support or coworkers for review use the following command :

    tar -czf mcpcollect.tar.qz /tmp/mcpcollect-yourusername/


For questions or suggeststions contact Jerry Keen, jkeen@mirantis.com.
