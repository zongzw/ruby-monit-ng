require_relative '../../agents/agent'
require_relative '../../base/get/sshget2'
require_relative '../../base/metrics'

class SwPolicyC2960 < Agent

  # option = {
  #     :ip_address => ip,
  #     :community => community,
  #     :interval => @monit_items[item],
  #     :basetarget => base_target,
  #     :pin_code => @pin_code,
  #     :org_env => @org_env,
  #     :username => username,
  #     :password => password,
  # }

  attr_reader :result

  def initialize(option)
    super

    @ssh = SshGet2.new(:ip_address => option[:ip_address], :username => option[:username], :password => option[:password])
    @result = ''
    @origin = ''
  end

  def work
    @logger.info "#{self.class.name} is working"
    updated = ''

    @ssh.deal(['show run view full']) do |out|
      #! Last configuration change at 16:09:21 CST Mon May 16 2016 by bjwangjq
      lines = out.split("\r\n")
      lines.each do |line|
        if ! /^! Last configuration change at (.*)$/.match(line).nil?
          time = $1.split('by ')[0]
          who = $1.split('by ')[1]
          updated = "#{time} - #{who}"
          break
        end
      end

      if @origin.empty? || @origin == updated
        @origin = updated
        @result = ''
      else
        @result = @origin = updated
      end
    end
  end

  # ibm.allenvs.switch.<ip>.policy_changed
  def migrate
    metrics_list = []
    timestamp = Time.now.to_i.to_s
    ipstring = @option[:ip_address].gsub '.', '-'

    status = (@result.empty?) ? 0 : 1
    detail = @result

    info = {
        :sn => ipstring,
        :target => @option[:org_env] + "." + @option[:basetarget] +
            ".#{ipstring}.policy_changed",
        :instance => ipstring,
        :status => status,
        :details => detail,
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }

    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    merged = Metrics.merge(metrics_list)
  end

  def post_grafana

  end
end