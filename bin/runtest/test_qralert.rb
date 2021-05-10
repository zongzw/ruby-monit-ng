require_relative '../../lib/agents/qradar/qr_alert'

option = {
    :pin_code => "123456",
    :org_env => "bmxcn.allenvs",
    :basetarget => 'qradar',
    :interval => 300,
    :tcp_port => 25777,
    :rate_interval => 60
}

agent = QrAlert.new(option)

while true
  agent.work
  p agent.migrate
  sleep 1
end
