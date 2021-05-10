# 2017.10.19 https://github.com/abates/ruby_expect/issues/7

require_relative 'get'
require 'ruby_expect'

class ExpectGet < Get
  def initialize(option)
    puts option
    @ip_address = option[:ip_address]
    @username = option[:username]
    @password = option[:password]
    @sshport = option[:sshport].nil? ? 22 : option[:sshport]

  end

  def deal(arg)
    exp = RubyExpect::Expect.spawn("ssh  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no #{@username}@#{@ip_address} -p #{@sshport}", :debug=>true, :timeout => 10)
    password = @password

    exp.procedure do
      retval = 0
      while (retval != 2)
        retval = any do
          expect /Are you sure you want to continue connecting \(yes\/no\)\?/ do
            send 'yes'
          end

          expect /^.*assword:\s*$/ do
            puts "this is the match: #{exp.match}"
            send password
          end

          expect /^.*[#|\$]\s*$/ do
            puts "this is the match in execute: #{exp.match}"
            send arg
          end
        end
      end

      # Expect each of the following
      each do
        # expect /show/ do
        #   puts "this is match in exec2: #{exp.match}"
        #
        # end
        expect /^.*[#|\$]\s+$/ do # shell prompt
          yield exp.before
          send 'exit'
        end
      end
    end
  end

end