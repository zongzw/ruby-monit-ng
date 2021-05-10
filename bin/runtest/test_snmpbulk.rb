require_relative '../lib/base/get/snmpbulk'
require_relative '../lib/base/get/snmpget'

=begin
def deal(arg)
  puts "#{self.class.name} start to deal ..."
  SNMP::Manager.open(:Host => '10.20.2.41', :Version => :SNMPv2c,
                     :Community => 'monit_fg') do |manager|
    response = manager.get_bulk(0, 10, arg)
    response.each_varbind do |varbind|
      yield varbind
    end
  end
end


testoids = {:runtest => '1.3.6.1.4.1.12356.101.3.2.1.1.2'}

deal(testoids.values) do |varbind|
  puts varbind
end

puts SNMP::Manager.instance_methods
SNMP::Manager.open(:Host => '10.20.2.41', :Version => :SNMPv2c,
                   :Community => 'monit_fg') do |manager|
  #puts manager.to_yaml
  puts manager.to_s
end
=end

bulk = SnmpBulk.new(:ip_address => '10.20.2.41', :community => 'monit_fg')
get = SnmpGet.new(:ip_address => '10.20.2.41', :community => 'monit_fg')

fgIntfEntVdom    = ['1.3.6.1.4.1.12356.101.7.2.1.1.1']
fgVdEntName      = ['1.3.6.1.4.1.12356.101.3.2.1.1.2']
fgVdNumber       = ['1.3.6.1.4.1.12356.101.3.1.1.0']

vdom_number = 0
get.deal(fgVdNumber) do |varbind|
  vdom_number = varbind.value.to_i
end

bulk.deal(fgVdEntName + [0, vdom_number]) do |vditem|
  puts vditem
  #vdIndex = vditem.name.to_s.split('.')[-1].to_i
  #@vddata[vdIndex] = vditem.value.to_s
end

#oids = {:fgIntfEntVdom => '1.3.6.1.4.1.12356.101.7.2.1.1.1'}
oids = {:fgVdEntName => '1.3.6.1.4.1.12356.101.3.2.1.1.2'}

get = SnmpBulk.new(:ip_address => "10.20.2.41", :community => "monit_fg")

get.deal(oids.values + [0, 10]) do |varbind|
  puts varbind
end
