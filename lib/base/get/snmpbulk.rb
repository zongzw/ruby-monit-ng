require 'snmp'
require_relative '../get/get'

class SnmpBulk < Get
  def initialize(option)
    super
    @option[:snmpport] = 161 if @option[:snmpport].nil?
  end

  def deal(arg)
    @logger.info "#{self.class.name} start to deal ..."
    max_repetitions = arg.pop
    non_repeaters = arg.pop
    #puts "max_repetitions: #{max_repetitions}, non_repeaters: #{non_repeaters}"
    #puts "handling oid: #{arg}"
    SNMP::Manager.open(:Host => @option[:ip_address], :Version => :SNMPv2c,
                       :Community => @option[:community], :port => @option[:snmpport]) do |manager|
      response = manager.get_bulk(non_repeaters, max_repetitions, arg)
      #puts "Get response #{response.varbind_list}"
      #puts response.class.instance_methods
      response.each_varbind do |varbind|
        yield varbind
      end
    end
  end
end