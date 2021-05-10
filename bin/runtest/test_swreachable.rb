require_relative '../lib/agents/switch/sw_reachable'

ip = '10.20.2.31'
community = 'monit_sw'

option = {
    :ip_address => ip,
    :community => community,
    :interval => 30,
    :basetarget => 'switch',
    :pin_code => 'pincode',
    :org_env => "@org_env",
    :username => 'networkguest',
    :password => "sw6tuswu4rUc",
}

r = SwReachable.new(option)
r.work
puts r.result

