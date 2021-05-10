require_relative '../lib/agents/fortigate/fg_hwstat'

hwstat_agent = FgHwStat.new(:ip_address => '10.20.2.41',
                            :community => 'monit_fg',
                            :cluster_name => 'fg300c',
                            :interval => 30,
                            :basetarget => 'network.fortigate',
                            :pin_code => 'sf2o@!co',
                            :org_env => 'ibm.bmxcn-local')

hwstat_agent.work
puts hwstat_agent.migrate