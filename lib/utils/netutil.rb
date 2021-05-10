require_relative '../utils/logger'
require 'uri'
require 'net/http'

class NetUtil
  @@logger = MonitLogger.instance.logger

  def self.post_json(url, data)
    url = URI.parse(url)
    req = Net::HTTP::Post.new(url.path, {'Content-Type' => 'application/json'})
    req.body = data
    res = Net::HTTP.new(url.host, url.port).start{|http| http.request(req)}
    @@logger.info("posting data: ")
    @@logger.info("#{data}")
    @@logger.info("response: #{res.body}")
    #puts "posting data: "
    #puts data
    #puts "response: #{res.body}"
  end
end
