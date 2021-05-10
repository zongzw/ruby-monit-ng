require_relative '../lib/base/get/sshget2'

get = SshGet2.new({:username => 'root', :password => '3+[B8U$2RY55SFg', :ip_address => '172.17.0.60'}) # OK
get = SshGet2.new({:username => 'networkguest', :password => 'sw6tuswu4rUc', :ip_address => '10.20.2.31'}) # OK
# in `next_packet': connection closed by remote host (Net::SSH::Disconnect)
get = SshGet2.new({:username => 'networkguest', :password => 'sw6tuswu4rUc', :ip_address => '10.20.2.21'}) # OK


cmdout = ''
get.deal('show ip route') do |out|
  puts "=================================#{out}"
end

get.deal('show run view full') do |out|
  puts "=================================#{out}"
end
