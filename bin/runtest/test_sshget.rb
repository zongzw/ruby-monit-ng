require_relative '../lib/base/get/sshget'

=begin
cmd = RemoteCmdGet.new(:username => 'admin', :address => '10.20.2.41', :options => {:password => 'landing'})

cmd.deal(['config vdom && edit root']) do |rlt, msg|
  puts "return: #{rlt}, message: #{msg}"
end
=end

#cmd = RemoteCmdGet.new(:username => 'root', :address => '9.111.108.124', :options => {:password => 'zongzw123'})
#cmd.deal(['m=10', 'n=0', 'while [ $n -lt $m ]; do echo "$n:"`echo $n | md5sum`; n=`expr $n + 1`; done', 'pwd']) do |out|
#  puts "Get output : #{out}"
#end

#cmd.deal(['ls', 'pwd', 'cd /tmp', 'bosh deployments', 'pwd', 'bosh status', 'exit'])
#cmd.deal(['ls', 'pwd', 'sleep 10', 'cd /tmp', 'pwd', 'bosh status', 'exit'])

#cmd = RemoteCmdGet.new(:username => 'root', :address => '9.37.17.140', :options => {:password => 'zongzw123'})
#cmd.deal(['ls', 'pwd', 'sleep 10', 'pwd', 'exit'])

# cmd = SshGet.new(:username => 'admin', :ip_address => '10.20.2.41', :options => {:password => 'landing'})
# cmd.deal(['config vdom', 'edit root', 'show', 'end']) do |out|
#   File.open("/tmp/test_ssh_exec_in_session.txt", 'w') do |file|
#     file.puts out
#   end
# end
#
# cmd = SshGet.new(:username => 'networkguest', :ip_address => '10.20.2.41', :options => {:password => 'sw6tuswu4rUc', :port => 10022})
# cmd.deal(['get system status', 'config vdom', 'end']) do |out|
#   puts out
# end

cmd = SshGet.new(:username => 'networkguest', :ip_address => '10.20.2.21', :options => {:password => 'sw6tuswu4rUc'})
cmd.deal(['show clock']) do |out|
  puts out
end
