require 'net/ssh'
require_relative '../get/get'

class SshGet2 < Get
  def initialize(option)
    super

    @ip_address = option[:ip_address]
    @username = option[:username]
    @password = option[:password]
  end

  # used to execute a single command on the target host.
  def deal(cmd)
    output = ''
    retval = 255
    begin
      # , :verbose => :debug
      @logger.info("ssh inforamtion: #{@ip_address}, #{@username}, #{@password}")
      Net::SSH.start(@ip_address, @username, {:password => @password, :timeout => 30}) do |session|
        channel = session.open_channel do |ch|
          ch.exec cmd do |ch, success|
            raise "could not execute command" unless success

            # "on_data" is called when the process writes something to stdout
            ch.on_data do |c, data|
              output += data
            end

            # "on_extended_data" is called when the process writes something to stderr
            ch.on_extended_data do |c, type, data|
              @logger.error "Command '#{cmd}' executed: #{data}"
            end

            ch.on_request("exit-status") do |ch, data|
              retval = data.read_long
              if (retval == 0)
                yield output
              else
                raise RuntimeError, "exit-status: #{retval}: Failed to execute command: #{cmd}"
              end
            end

          end
        end
      end
    rescue Net::SSH::Disconnect => e
      if (retval == 0)
        @logger.info("normal disconnected: #{e.message}")
      else
        @logger.error("abnormal disconnected: #{e.message}")
        @logger.error("#{e.backtrace}")
      end
    rescue Net::SSH::HostKeyMismatch => e
      @logger.warn("#{e.class.name}: #{e.message}; #{e.backtrace}")
      e.remember_host!
      retry
    end
  end
end