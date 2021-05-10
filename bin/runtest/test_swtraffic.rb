require_relative '../lib/agents/switch/sw_traffic'
require 'json'

option = {
    :ip_address => '10.20.2.21',
    :community => 'monit_sw',
    :interval => 300,
    :basetarget => 'switch',
    :pin_code => '12345678',
    :org_env => 'bmxcn.allenvs',
    :username => 'networkguest',
    :password => 'sw6tuswu4rUc',
    :exvlan => ['fddi-default', 'token-ring-default', 'fddinet-default', 'trnet-default'],
    :tops => "5"
}


option = {
    :ip_address => '10.20.2.24',
    :community => 'monit_sw',
    :interval => 300,
    :basetarget => 'switch',
    :pin_code => '12345678',
    :org_env => 'bmxcn.allenvs',
    :username => 'networkguest',
    :password => 'sw6tuswu4rUc',
    :exvlan => ['fddi-default', 'token-ring-default', 'fddinet-default', 'trnet-default'],
    :tops => "5"
}
agent = SwTraffic.new(option)
agent.work
#puts agent.result
puts "======="
puts agent.migrate