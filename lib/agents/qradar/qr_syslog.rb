require 'net/http'
require "uri"

require_relative '../agent'

class QrSyslog < Agent
  include QRADARHOSTNAMEIPMAPPING
  
  def initialize(option)
    super
  end

  def work
    @logger.info("#{self.class.name} is working ...")
    @result = {}
    IPServerMapping.each do |ip, host|
      cmd = "nc -zw3 #{ip} 514 && echo '1' || echo '-1'"
      @result[host] = `#{cmd}`
    end
  end

  # ibm.allenvs.qradar.web_access
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    IPServerMapping.values.each do |host|
      info = {
        :sn => timestamp,
        :target => targetprefix + ".syslog.#{host}",
        :instance => host,
          :status => @result[host],
          :details => '',
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    merged = Metrics.merge(metrics_list)
    merged
  end
end
