require_relative '../../lib/agents/bandwidth/fg_bandwidth'

require 'json'

interval = 5
short_term = 10
long_term = 15
agent = FgBandwidth.new(:ip_address => '10.20.2.42',
                     :community => 'monit_fg',
                     :interval => interval,
                     :interface_name => ['ag-public'],
                     :cluster_name => 'fg-cl02',
                     :basetarget => 'bandwidth',
                     :pin_code => 'sf2o@!co',
                     :org_env => 'ibm.bmxcn-local',
                     :short_term => short_term,
                     :long_term => long_term,
                        :bandwidth_in_Mbps => [60]
)

# agent.work
# #puts agent.lastVpnData
# puts agent.migrate.to_json


while true
  agent.work
  puts agent.migrate.to_json
  sleep interval
end