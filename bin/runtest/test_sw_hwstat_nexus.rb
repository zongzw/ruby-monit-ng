require_relative '../lib/agents/switch/sw_hwstat_nexus'

option = {
    :ip_address => '10.20.2.31',
    :community => 'monit_sw',
    :interval => 300,
    :basetarget => 'any',
    :pin_code => 'pincode',
    :org_env => 'ibm.env',
    :username => 'networkguest',
    :password => 'sw6tuswu4rUc',
}

hwstat_agent = SwHwstatNexus.new(option)
#hwstat_agent.show_environment_temporature
hwstat_agent.work
puts hwstat_agent.result
merged = hwstat_agent.migrate
puts merged