require_relative '../../lib/agents/fortigate/fg_config'

agent = FgConfig.new(:ip_address => '10.20.2.41',
                              :community => 'monit_fg',
                              :username => 'networkguest',
                              :password => 'sw6tuswu4rUc',
                              :serial_number => 'fd3000c',
                              :basetarget => 'basetarget',
                              :pin_code => '2342$32&',
                              :org_env => 'bmxcn.allenvs',
                              :cluster_name => 'fg-cl01',
                              :port => 10022,
                              :interval => 20
)

#agent.work
#agent.work
#agent.check_global_config_change
#puts agent.migrate
# agent.timezone
# agent.device_and_category(:mgmt)
# agent.total_log_number :mgmt
#logs = agent.logs_start_with_length(:mgmt, 1, 50)

# logs.each do |log|
#   puts agent.logs_is_new_than(log, Time.now - 30)
# end

agent.work
puts agent.migrate
