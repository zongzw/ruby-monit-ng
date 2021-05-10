require_relative '../lib/agents/fortigate/fg_reachable'

option = {
    :ip_address => '10.20.2.41',
             :community => 'monit_fg',
             :username => 'networkguest',
             :password => 'sw6tuswu4rUc',
             :serial_number => 'fd3000c',
             :basetarget => 'basetarget',
             :pin_code => '2342$32&',
             :org_env => 'bmxcn.allenvs',
             :cluster_name => 'fg-cl01',
             :port => 10022
}
r = FgReachable.new(option)
r.work
puts r.result

puts r.migrate

