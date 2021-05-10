require_relative '../lib/agents/switch/sw_policy_nexus'

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

agent = SwPolicyNexus.new(option)

agent.work
puts "first: #{agent.result}"

puts "migrate:", agent.migrate

agent.work
puts "second: #{agent.result}"

puts "migrate:", agent.migrate