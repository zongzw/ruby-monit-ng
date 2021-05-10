
require_relative '../lib/utils/mibloader'
require_relative '../lib/base/get/snmpwalk'

columns = ['ifDescr']

get = SnmpWalk.new(:ip_address => "9.112.242.20", :community => "monit_fg")

get.deal(columns) do |varbind|
  puts varbind
end

