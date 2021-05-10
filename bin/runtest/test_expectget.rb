require_relative '../../lib/base/get/expectget'
#
# get = ExpectGet.new({:ip_address => '10.20.2.21', :username => 'networkguest', :password => 'sw6tuswu4rUc'})
# #
# get.deal('show ip host') do |out|
#   puts "|#{out}|"
# end

get = ExpectGet.new({:ip_address => '172.17.0.143', :username => 'root', :password => 'password'})
get.deal('ls /opt/deployUCD') do |out|
  puts "|#{out}|"
end

get = ExpectGet.new({:ip_address => '10.20.2.41', :username => 'networkguest', :password => 'sw6tuswu4rUc', :sshport => 10022 })
get.deal('get system status') do |out|
  puts "|#{out}|"
end