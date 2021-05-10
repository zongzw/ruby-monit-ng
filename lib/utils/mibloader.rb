require 'snmp'
require_relative '../utils/constant'
require_relative '../utils/logger'

module MibLoader
  logger = MonitLogger.instance.logger
  logger.info "loading mibs ..."
  Constant.get_mibs_files.each do |file|
    SNMP::MIB.import_module(file)
    logger.info "loaded: #{file}"
  end

  #puts SNMP::MIB.instance_methods
  #puts SNMP::MIB.list_imported
  #mib = SNMP::MIB.new
  #mib.load_module("FORTINET-FORTIGATE-MIB")
  #mib.load_module("FORTINET-CORE-MIB")
  #mib.load_module("INET-ADDRESS-MIB")

  #SNMP::Manager.open(:host => '10.20.2.41',
  #                   :version => :SNMPv2c,
  #                   :community => 'monit_fg') do |manager|
    #puts manager.class.instance_methods
    #manager.load_module("FORTINET-FORTIGATE-MIB")
    #puts manager.mib.load_module("APACHE-MIB")
    #manager.load_module("FORTINET-CORE-MIB")
    #manager.walk(['fnAdminIndex']) do |varbind|
    #  puts varbind
    #end
  #end
end