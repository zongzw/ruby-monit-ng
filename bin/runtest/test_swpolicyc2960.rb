require_relative '../lib/agents/switch/sw_policy_c2960'

ip = '10.20.2.21'
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

agent = SwPolicyC2960.new(option)

agent.work
puts agent.result

agent.work
puts agent.result

puts agent.migrate