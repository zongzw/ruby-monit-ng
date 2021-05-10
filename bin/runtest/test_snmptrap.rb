require_relative '../../lib/base/get/snmptrap'

option = {
    :ip_address => '172.17.0.61',
    :snmpport => 162,
    :community => 'public'
}
get = SnmpTrap.new(option)

get.deal('1.0') do |trap|
  puts trap.inspect
end

while true
  sleep 1
  puts "sleeping for 1 sec"
end