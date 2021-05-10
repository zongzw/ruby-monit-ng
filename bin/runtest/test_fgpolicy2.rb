require 'pathname'
#require 'regexp'
require_relative '../lib/agents/fortigate/fg_policy2'

file = File.open(Pathname.new(File.dirname(__FILE__) + "/..//data/sys_config").realpath)
data = file.read

#puts data

policy2_agent = FgPolicy2.new(:ip_address => '10.20.2.41',
                              :community => 'monit_fg',
                              :username => 'networkguest',
                              :password => 'sw6tuswu4rUc',
                              :serial_number => 'fd3000c',
                              :basetarget => 'basetarget',
                              :pin_code => '2342$32&',
                              :org_env => 'bmxcn.allenvs',
                              :cluster_name => 'fg-cl01',
                              :port => 10022)

policy2_agent.work
puts policy2_agent.origin
puts policy2_agent.diff
policy2_agent.origin['bridge'] = 'config firewall policy\n end\n'
policy2_agent.work
puts policy2_agent.diff

posted = policy2_agent.migrate

puts posted