# mcpcollect
MCP Log/Diagnostics collection tool

Note : at the time of writing this config the list of salt grains and related commands and collection information is incomplete
       please contribute if you have something to add that will make this tool more useful.

Note : This tool is not designed to modify or change anything in your MCP cluster.  Any suggestions to use this tool to
       make system changes will be rejected.

MCPCOLLECT is a tool designed to easily gather logs from your Mirantis MCP environment for support or analysis. 

The general premis of this tool is to collect information based on the installed salt.grains. By specifying the
salt grain, mcpcollect will query the reclass model and select the appropriate targets hosts then collect config 
files, logs, and run a set of commands to collect statistics or information abou the services related to the salt grain.

mcpcollector -s <mmo-somehost> -g ceph.osd -h osd001 -h osd002 -y -l

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

    -l -- Run on your localhost with ssh access to a Cfg or Salt node.  This option also requires the -s switch
		* Note this requires ssh keys to be installed from your local host to the cfg node, or you will be prompted
		  many times for your ssh password

    -p -- Preview only --Do not collect any files, previews what will be collected for each grain

    -s -- <cfg node or salt node>
		* REQUIRED : hostname or IP of the salt of config host.

    -y -- Autoconfirm -- Do not print confirmation and summary prompt

For questions or suggeststions contact Jerry Keen, jkeen@mirantis.com.

