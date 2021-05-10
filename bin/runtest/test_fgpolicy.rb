require_relative '../lib/agents/fortigate/fg_policy'

require 'json'

agent = FgPolicy.new(:ip_address => '10.20.2.41',
                        :community => 'monit_fg',
                        :cluster_name => 'fg300c',
                        :username => 'admin',
                        :password => 'landing',
                        :basetarget => 'network.fortigate',
                        :pin_code => 'sf2o@!co',
                        :org_env => 'ibm.bmxcn-local')

while true
  agent.work
  puts agent.migrate.to_json
  sleep 5
end