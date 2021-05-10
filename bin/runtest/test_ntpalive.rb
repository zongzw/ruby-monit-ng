require_relative '../../lib/agents/ntp/ntp_alive'

require 'json'

agent = NtpAlive.new(:ip_address => ["10.20.1.1", "10.20.2.1", "10.20.3.1", "10.20.3.9", "10.20.3.17", "10.20.3.25", "10.20.3.33"],
                     :cluster_name => ["IPMI", "OOB", "BM01", "YSYF", "YP", "Dedi01", "IOTP"],
                     :basetarget => 'ntp',
                      :query_timeout => '2',
                     :pin_code => 'sf2o@!co',
                     :org_env => 'ibm.bmxcn-local')

# agent.work
# #puts agent.lastVpnData
# puts agent.migrate.to_json


#while true
  agent.work

  puts agent.migrate.to_json

#end