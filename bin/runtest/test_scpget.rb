require_relative '../lib/base/get/scpget'

hr = ScpGet.new(:username => 'networkguest', :ip_address => '10.20.2.41', :options => {:password => 'sw6tuswu4rUc', :port => 10022})

hr.deal(['sys_config']) do |item|
  puts item
end

