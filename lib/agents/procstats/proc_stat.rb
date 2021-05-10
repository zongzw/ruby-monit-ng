require_relative '../../agents/agent'
require_relative '../../../lib/base/get/sshget2'

class ProcStat < Agent
  def initialize(options)
    super
    @option = options
    @sshget = SshGet2.new(:ip_address => options[:ip_address], :username => options[:username], :password => options[:password])
    @procname = @option[:name]
    @procptrn = @option[:matches]
  end

  def work()
    @logger.info("#{self.class.name} is working...")

    @result = {}

    detectcmd = "ps -ef | grep -v grep "
    for n in @procptrn
      match = n.sub '-', '\\-'
      detectcmd += '| grep "%s" ' % match
    end

    begin
      @sshget.deal(detectcmd) do |out|
        outmsg = out
        if (outmsg == nil)
          @result[:detail] = "%s not found with patterns: #{@procptrn}." % @procname
          @result[:status] = -1
          @logger.info("%s not found with patterns: #{@procptrn}." % @procname)
        else
          @result[:detail] = outmsg
          @result[:status] = 0
          @logger.info("process info: #{outmsg}")
        end
      end
    rescue RuntimeError => e
      @result[:detail] = "%s not found with patterns: #{@procptrn}." % @procname
      @result[:status] = -1
      @logger.info("%s not found with patterns: #{@procptrn}." % @procname)
    end
  end

  # ibm.allenvs.process.ticket.process-name
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    info = {
        :sn => @procname + timestamp,
        :target => targetprefix + ".#{@procname}",
        :instance => @procname,
        :status => @result[:status],
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :details => "#{@result[:detail]}",
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    merged = Metrics.merge(metrics_list)

    merged
  end
end