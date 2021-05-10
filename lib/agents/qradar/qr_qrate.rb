require_relative '../agent'
require_relative '../../base/get/tcpget'
require_relative '../../../data/qradar-hostname-ip-mapping'
require 'json'

class QrQrate < Agent
  include QRADARHOSTNAMEIPMAPPING

  def initialize(option)
    super
    check_option

    @tcpget = TcpGet.new(@option)
    @lock = Mutex.new

    @update = []
    @result = {}
    @tcpget.deal do |data|
      @lock.lock
      @update << data
      @lock.unlock
    end
  end

  def work
    @logger.info("#{self.class.name} is working...")

    @lock.lock
    @update.each do |data|
      begin
        _, message = data.split(',',2)
         
        msg = JSON.parse(message)
        eps = HostIpMapping[msg["src"]]
        raise "Not ariel_query_times message." if msg["name"].to_s != "ariel_query_times"
        raise "Message not from EPSs." if not eps
        @result[eps] = msg["QUERY_CNT"]
        p @result
      rescue => e
        @logger.warn "QrQuery agent:"
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
    targetprefix = @option[:org_env] + "." + @option[:basetarget]
    timestamp = Time.now.to_i * 1000
    
    @result.keys.each do |eps|
      info = {
          :sn => sn,
          :target => targetprefix + ".query_rate.#{eps}",
          :instance => eps,
          :status => @result[eps],
          :details => "",
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
    [:basetarget, :pin_code, :org_env, :tcp_port, :interval].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end
end
