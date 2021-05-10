require_relative '../agent'
require_relative '../../base/get/tcpget'
require_relative '../../../data/qradar-hostname-ip-mapping'
require 'json'

class QrAlert < Agent
  include QRADARHOSTNAMEIPMAPPING

  def initialize(option)
    super
    check_option

    @tcpget = TcpGet.new(@option)
    @lock = Mutex.new
    @rate_interval = @option[:rate_interval]
    @ratecnt = @rate_interval

    @alertcnt = {}
    clear_alertcnt
      
    @update = []
    @tcpget.deal do |data|
      @lock.lock
      @update << data
      @lock.unlock
    end
  end

  def clear_alertcnt
    Envs.each do |env|
      @alertcnt[env] = 0
    end
  end

  def work
    @logger.info("#{self.class.name} is working...")
    @result = []

    @lock.lock
    @update.each do |data|
      begin
        host, message = data.split(',',2)
         
        alert = JSON.parse(message)
        eps = HostEnvMapping[host]
        raise "No fullMatchCustomRuleNames in alert message." if alert["fullMatchCustomRuleNames"].to_s == ''
        raise "No sev in alert message." if alert["sev"].to_s == ''
        raise "Message not from EPSs." if not eps
        info = {
          :eps => eps,
          :name => alert["fullMatchCustomRuleNames"],
          :details => JSON.pretty_generate({
            "payload" => alert["payload"],
            "host" => alert["logSourceIdentifier"],
            "host_ip" => alert["dst"],
            "category" => alert["category"]
          }),
          :sev => alert["sev"]
        }
        @result << info
        @alertcnt[eps] += 1
      rescue => e
        @logger.warn "QrAlert agent:"
        @logger.warn "  #{e.message}"
        @logger.warn "  Wrong data format: #{data}"
      end
    end

    @update = []
    @lock.unlock

  end

  def migrate
    metrics_list = []
    sn = Time.now.to_i.to_s
    timestamp = Time.now.to_i * 1000
    
    if @ratecnt != 1
      @ratecnt -= 1
    else
      @ratecnt = @rate_interval

      rate_info = {
          :sn => sn,
          :target => "#{option[:org_env]}.#{option[:basetarget]}.alert_rate",
          :details => "Alert rate per #{@rate_interval} minutes",
          :timestamp => timestamp,
          :duration => 0,
          :attachments => []
      }

      Envs.each do |env|
        rate_info[:instance] = env
        rate_info[:status] = @alertcnt[env]
        metrics = Metrics.new(@option[:pin_code], rate_info)
        metrics_list << metrics
      end
      
      clear_alertcnt
    end

    @result.each do |rlt|
      info = {
          :sn => sn,
          :target => "bmxcn.#{rlt[:eps]}.#{option[:basetarget]}.alert",
          :instance => rlt[:name],
          :status => rlt[:sev],
          :details => rlt[:details],
          :timestamp => timestamp,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    Metrics.merge(metrics_list)
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:basetarget, :pin_code, :org_env, :tcp_port, :interval, :rate_interval].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end
end
