require_relative '../../agents/agent'
require_relative '../../base/get/sshget2'
require_relative '../../base/metrics'

class SwPolicyNexus < Agent

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
    @origin = -1
    
    @exlist = %w(ping traceroute dir )
    @excmd = ''
    @exlist.each do |item|
      @excmd += " | grep -v #{item}"
    end
  end

  def work
    @logger.info("#{self.class.name} is working.")

    @result = ''
    lastindex = -1

    @ssh.deal('show accounting log last-index') do |out|
      if /^accounting-log last-index : -?(\d+)$/.match(out).nil?
        raise RuntimeError, "cannot find the last index of accounting log."
      end
      lastindex = $1.to_i
      lastindex = (lastindex <= 0) ? 1 : lastindex
    end

    if @origin == -1
      @origin = lastindex
      @result = ''
    else
      @result =
      cmd = "show accounting log start-seqnum #{@origin} | grep ':update:' #{@excmd}"
      @logger.debug(cmd)
      @ssh.deal(cmd) do |out|
        @result = out
      end
      @origin = lastindex
    end
  end

  # ibm.allenvs.switch.<ip>.policy_changed
  def migrate
    metrics_list = []
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

end