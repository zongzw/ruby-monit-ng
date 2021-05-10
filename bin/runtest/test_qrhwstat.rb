require_relative '../../lib/agents/qradar/qr_hwstat'

option = {
    :ip_address => '172.16.11.11',
    :community => 'public',
    :snmpport => 8001,
    :org_env => 'a.b',
    :pin_code => '123456',
    :basetarget => 'c'
}

agent = QrHwStat.new(option)

agent.work
puts agent.migrate
# while true
#   agent.cpu_usage
#   sleep(4)
# end