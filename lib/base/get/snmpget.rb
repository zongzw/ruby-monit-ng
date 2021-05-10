require 'snmp'
require_relative '../get/get'

class SnmpGet < Get
  def initialize(option)
    super
    @option[:snmpport] = 161 if @option[:snmpport].nil?
  end

  def deal(arg)
    @logger.info "#{self.class.name} start to deal ..."
    SNMP::Manager.open(:Host => @option[:ip_address], :Version => :SNMPv2c,
                       :Community => @option[:community], :port => @option[:snmpport]) do |manager|
      response = manager.get(arg)
      response.each_varbind do |varbind|
        yield varbind
      end
    end
  end
end