require_relative '../../lib/agents/qradar/qr_eps'

option = {
    :community => 'public',
    :pin_code => "123456",
    :org_env => "bmxcn.allenvs",
    :basetarget => 'qradar',
    :interval => 300,
    :snmpport => 8001
}

agent = QrEps.new(option)

# len = 0
# while true
#   if len < agent.update.length
#     puts agent.update[len..-1]
#     len = agent.update.length
#   end
#   sleep 1
# end

while true
  agent.work
  puts agent.migrate
  sleep 5
end
# `snmptrap -v2c -c public 172.17.0.27 "" 1.2.4.0 1.2.4.0 s "1.0"`
#
# agent.work
# puts agent.migrate
#
# `snmptrap -v2c -c public 172.17.0.27 "" 1.2.4.0 1.2.4.0 s "2.4"`
# `snmptrap -v2c -c public 172.17.0.27 "" 1.2.4.0 1.2.4.0 s "7.0"`
#
# agent.work
# puts agent.migrate
