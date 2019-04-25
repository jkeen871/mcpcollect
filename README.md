# mcpcollect
MCP Log/Diagnostics collection tool


 mcpcollector -s cfg.host.exmple.net -g salt.grain1 -g salt.grain2 -h host1 -h host2 -y -l

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

    -p -- Preview only --Do not collect any files, previews what will be collected for each grain

    -s -- <cfg node or salt node>
          REQUIRED : hostname or IP of the salt of config host.

    -y -- Autoconfirm -- Do not print confirmation and summary prompt
