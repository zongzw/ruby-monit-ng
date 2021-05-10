require 'net/http'
require "uri"

require_relative '../agent'

class QrWeb < Agent
  def initialize(option)
    super
    @url = @option[:weburl]
  end

  def work
    @logger.info("#{self.class.name} is working ...")
    @result = -1
    cmd = "curl -m 5 -k -s -o /dev/null -w '%{http_code}' #{@url}"
    output = `#{cmd}`
    @result = 1 if output == '200'
  end

  # ibm.allenvs.qradar.web_access
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]

    info = {
        :sn => timestamp,
        :target => targetprefix + ".web_access",
        :instance => @url,
        :status => @result,
        :details => '',
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    merged = Metrics.merge(metrics_list)
    merged
  end
end
