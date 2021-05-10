
require 'net/ssh'
require_relative '../get/get'

class SshGet < Get

  # sshget = SshGet.new(:ip_address => '..', :username => 'username', :options => {:password => 'password'})

  @@TIMEOUT = 60.0
  @@MARK = "c72691b-4109-4eaa-84bd-de2d7377302a"
  def initialize(option)
    super
    @ip_address = @option[:ip_address]
    @username = @option[:username]
    @options = @option[:options]
    @shell = {:out => ''}
    @mutex = Mutex.new
    @threads = []

  end

  def new_channel
    @threads << Thread.new do
      # Connect to the server
      begin
        Net::SSH.start(@ip_address, @username, @options) do |session|
          # Open an ssh channel
          session.open_channel do |channel|
            # send a shell request, this will open an interactive shell to the server
            channel.send_channel_request "shell" do |ch, success|
              if success
                # Save the channel to be used in the other thread to send commands
                @shell[:ch] = ch
                # Register a data event
                # this will be triggered whenever there is data(output) from the server
                ch.on_data do |ch, data|
                  @mutex.synchronize {
                    @shell[:out] += data
                    @shell[:out] += @@MARK
                  }
                end

                ch.on_extended_data do |ch, type, data|
                  @mutex.synchronize {
                    @shell[:out] += data
                    @shell[:out] += @@MARK
                  }
                end

                ch.on_close do |ch|
                  @logger.info "Execution channel is being closed."
                end
              end
            end
          end
        end
      rescue Net::SSH::HostKeyMismatch => e
        @logger.warn("#{e.class.name}: #{e.message}; #{e.backtrace}")
        e.remember_host!
        retry
      end
    end
  end

  def deal(arg)
    #start_channel
    #puts "#{arg}"
    @logger.info("#{arg}")
    new_channel

    # the commands thread
    arg << "exit"
    @threads << Thread.new do
      arg.each do |cmd|
        timeout = @@TIMEOUT
        loop do
          break if @shell[:out].end_with? @@MARK
          sleep 0.01
          timeout -= 0.01
          break if timeout < 0
        end
        if timeout > 0
          @shell[:ch].send_data "#{cmd}\n"
        else
          @logger.error "Executing cmd: #{cmd} timeout, quit."
          @shell[:ch].send_data "exit\n"
          break
        end
      end
    end

    @threads.each(&:join)
    @threads = []

    @shell[:out].gsub! @@MARK, ''
    yield @shell[:out]
    @shell[:out] = ''
  end
end

