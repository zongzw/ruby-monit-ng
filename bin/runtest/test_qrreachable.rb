require_relative '../../lib/agents/qradar/qr_reachable'

option = {
    :ip_address => ['172.16.11.15', '172.16.11.11'],
    :community => 'public',
    :snmpport => 8001,
    :org_env => 'a.b.c',
    :pin_code => '123456',
    :basetarget => 'd'
}

agent = QrReachable.new(option)

agent.work
puts agent.migrate
