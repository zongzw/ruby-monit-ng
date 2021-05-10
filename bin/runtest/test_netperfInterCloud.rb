require_relative '../../lib/agents/netperformance/netperf_intercloud'

require 'json'

interval = 60

agent = NetPerfInterCloud.new(:hosts=>[{"cluster_name"=>"YS", "ip_address"=>["172.17.0.50"]},
                                       #{"cluster_name"=>"YP", "ip_address"=>["172.17.4.50"]},
                                       #{"cluster_name"=>"Dedi01", "ip_address"=>["172.17.8.40"]},
                                       {"cluster_name"=>"Dedi02", "ip_address"=>["172.17.12.80"]},
                                       #{"cluster_name"=>"Dedi03", "ip_address"=>["172.17.14.50"]},
                                       #{"cluster_name"=>"BMetal", "ip_address"=>["172.16.11.100"]}
                              ],
                        :username=>"networkguest",
                        :password=>"sw6tuswu4rUc",
                        :iperf_port=>3000,
                        :iperf_time=>10,
                        :monit_time => ["13:41", "00:00"],
                        :basetarget=>"netperformance",
                        :pin_code=>"kd2!r0c$",
                        :org_env=>"bmxcn.allenvs.test",
                        :logdir=>"./",
                        :interval=>60,
                        :id=>"YSYP"
)


# agent.work
# #puts agent.lastVpnData
# puts agent.migrate.to_json


while true
  agent.work
  puts agent.migrate.to_json
  puts "SLEEP #{interval} seconds...................................."
  sleep interval
end

