require_relative '../../lib/agents/qradar/qr_web'

option = {
    :pin_code => "123456",
    :org_env => "bmxcn.allenvs",
    :basetarget => 'qradar',
    :interval => 300,
    :weburl => "https://siem.cn.bluemix.net/console/",
    :rate_interval => 60
}

agent = QrWeb.new(option)

while true
  agent.work
  p agent.migrate
  sleep 10
end
