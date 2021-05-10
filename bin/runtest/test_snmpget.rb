
require_relative '../lib/base/get/snmpget'

oids = {:cpu_usage         => "1.3.6.1.4.1.12356.101.4.1.3.0",     # cpu usage
         :mem_usage         => "1.3.6.1.4.1.12356.101.4.1.4.0",     # mem usage
         :mem_capacity      => "1.3.6.1.4.1.12356.101.4.1.5.0",     # mem capacity
         :disk_used         => "1.3.6.1.4.1.12356.101.4.1.6.0",     # disk used
         :disk_capacity     => "1.3.6.1.4.1.12356.101.4.1.7.0",     # disk capacity
         :low_mem_usage     => "1.3.6.1.4.1.12356.101.4.1.9.0",     # low mem usage
         :low_mem_capacity  => "1.3.6.1.4.1.12356.101.4.1.10.0",    # low mem capacity
}

get = SnmpGet.new(:ip_address => "10.20.2.41", :community => "monit_fg")

arr = []
get.deal(oids.values) do |varbind|
  puts varbind
  arr << varbind
end

{}.each_pair do |key, vlaue|

end


testoids = {:runtest => '1.3.6.1.4.1.12356.101.3.2.1.1.2'}
get.deal(testoids.values) do |varbind|
  puts varbind
end
