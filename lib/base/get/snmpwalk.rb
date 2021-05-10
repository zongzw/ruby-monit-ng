require 'snmp'
require_relative '../get/get'

class SnmpWalk < Get
  def initialize(option)
    super
    @option[:snmpport] = 161 if @option[:snmpport].nil?
  end

  # walk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])
  def deal(arg)
    @logger.info "#{self.class.name} start to deal ..."
    SNMP::Manager.open(:Host => @option[:ip_address], :Version => :SNMPv2c,
                       :Community => @option[:community], :port => @option[:snmpport]) do |manager|
      manager.walk(arg) do |row|
        yield row
      end
    end
  end
end