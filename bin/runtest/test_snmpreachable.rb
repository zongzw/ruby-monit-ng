require_relative '../../lib/base/snmp_reachable'

option = {
    :ip_address => '172.16.11.11',
    :snmpport => '8001',
    :community => 'public'
}
test = SnmpReachable.new(option)
test.work

puts test.result