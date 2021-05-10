require_relative '../../lib/agents/fortigate/fg_sslvpn'

require 'json'

agent = FgSslVpn.new(:ip_address => '10.20.2.41',
                        :community => 'monit_fg',
                        :cluster_name => 'fg1500D',
                        :username => 'networkguest',
                        :password => 'sw6tuswu4rUc',
                        :port => '10022',
                        :tops => 1000,
                        :basetarget => 'network.fortigate',
                        :pin_code => 'sf2o@!co',
                        :org_env => 'ibm.bmxcn-local')

# agent.work
# #puts agent.lastVpnData
# puts agent.migrate.to_json


while true
  agent.work
  puts agent.migrate
  sleep 30
end