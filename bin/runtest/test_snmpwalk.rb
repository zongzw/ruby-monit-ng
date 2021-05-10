require_relative '../lib/base/get/snmpwalk'

get = SnmpWalk.new(:ip_address => "9.112.242.20", :community => "monit_fg")

#list = ["ifIndex", "ifDescr", "ifInOctets", "ifOutOctets", "ifSpeed"]
list = ["sysUpTime", "sysServices", 'ifNumber', 'ipOutRequests', 'ifName']
list = ['ifName']
list = ['fgVdEntIndex', 'fgVdEntName']
get.deal(list) do |row|
  puts row
end