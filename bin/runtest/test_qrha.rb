require_relative '../../lib/agents/qradar/qr_ha'

option = {
    :ip_address => '172.16.11.11',
    :community => 'public',
    :snmpport => 8001,
    :org_env => 'a.b.c',
    :pin_code => '123456',
    :basetarget => 'd'
}

agent = QrHa.new(option)

agent.work
puts agent.migrate
agent.work
puts agent.migrate