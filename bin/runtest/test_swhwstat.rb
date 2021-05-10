require_relative '../lib/agents/switch/sw_hwstat'

option = {
    :ip_address => '10.20.2.21',
    :community => 'monit_sw',
    :interval => 300,
    :basetarget => 'any',
    :pin_code => 'pincode',
    :org_env => 'ibm.env',
    :username => 'networkguest',
    :password => 'password',
}

option = {
    :ip_address => '10.20.2.31',
    :community => 'monit_sw',
    :interval => 300,
    :basetarget => 'any',
    :pin_code => 'pincode',
    :org_env => 'ibm.env',
    :username => 'networkguest',
    :password => 'password',
}

hwstat_agent = SwHwstat.new(option)
hwstat_agent.work
puts hwstat_agent.result
merged = hwstat_agent.migrate
puts merged