require 'pathname'
#require 'regexp'
require_relative '../lib/agents/fortigate/fg_policy2'

file = File.open(Pathname.new(File.dirname(__FILE__) + "/..//data/sys_config").realpath)
data = file.read

#puts data

policy2_agent = FgPolicy2.new(:ip_address => '',
                            :community => 'monit_fg',
                            :username => 'admin',
                            :password => 'landing',
                            :serial_number => 0,
                            :basetarget => 0,
                            :pin_code => '',
                            :org_env => '',
:cluster_name => '',
:port => 10022)

policy2_agent.parse_fgt_config(data)