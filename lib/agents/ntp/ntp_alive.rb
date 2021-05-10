require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'

class NtpAlive < Agent

  def initialize(options)
    super
    check_option
    @result = {}
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :cluster_name, :basetarget, :pin_code, :org_env, :query_timeout].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
    #check length of ip_address and cluster_name, should match
    if @option[:ip_address].length != @option[:cluster_name].length
      raise ArgumentError, "Length of ip_address and cluster_name in ntp config should match"
    end
  end

  def work
    @logger.info("#{self.class.name} is working ...")

    @result = {}

    @option[:ip_address].each_with_index do |ip,idx|
      instance_name = @option[:cluster_name][idx] + ":" + ip
      #puts instance_name
      @result[instance_name] = {}
      cmd= "sntp -t #{@option[:query_timeout]} #{ip}"
      @result[instance_name][:details] = `#{cmd}`
      @result[instance_name][:status] = $?.exitstatus
    end
  end

  def migrate
    metrics_list = []
    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    @result.each_pair do |instance,value|
      info = {
          :sn => @option[:basetarget] + "-alive-" + timestamp,
          :target => targetprefix + ".alive",
          :instance => instance,
          :status => value[:status],
          :details => value[:details],
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }

      metrics = Metrics.new(@option[:pin_code], info)
      #puts metrics
      metrics_list << metrics
    end
    merged = Metrics.merge(metrics_list)
  end




end