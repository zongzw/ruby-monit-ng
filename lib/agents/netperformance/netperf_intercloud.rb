# monitoring network bandwidth between cloud using iperf
# test it with
# 1. ruby ./test_netperfInterCloud.rb
#        OR
# 2. ruby monit-ng.rb --config ../config/monit2.yml -l ./ --module netperformance
require_relative '../agent'
require_relative '../../utils/constant'
require_relative '../../base/metrics'
require_relative '../../base/get/sshget2'#required for net/ssh

class NetPerfInterCloud < Agent
  def initialize(option)
    super
    check_option
    init_result
    @put = false
    @exec_time = '' #this agent starts when time hits @option[:monit_time], this var indicates the time to start monitoring
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:hosts, :username, :password, :iperf_port, :iperf_time, :basetarget, :pin_code,
     :org_env, :interval, :monit_time].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

=begin
#example result format for config
  hosts:
  - cluster_name: YS
    ip_address: [172.17.0.50]
  - cluster_name: YP
    ip_address: [172.17.4.50]
  - cluster_name: Dedi01
    ip_address: [172.17.8.40]

  @result = {  "172.17.0.50"=>{
          :cluster_name=>"YS",
          :dest=>{
              :"172.17.4.50"=>{
                  :cluster_name=>"YP",
                  :speed=>""
              },
              :"172.17.8.40"=>{
                  :cluster_name=>"Dedi01",
                  :speed=>""}
          }
      },
      "172.17.4.50"=>{:cluster_name=>"YP", :dest=>{:"172.17.0.50"=>{:cluster_name=>"YS", :speed=>""}, :"172.17.8.40"=>{:cluster_name=>"Dedi01", :speed=>""}}},
      "172.17.8.40"=>{:cluster_name=>"Dedi01", :dest=>{:"172.17.0.50"=>{:cluster_name=>"YS", :speed=>""}, :"172.17.4.50"=>{:cluster_name=>"YP", :speed=>""}}}}
=end

  def init_result
    @result = {}
    @ssh_states={}
    #init src in @result which is the key
    @option[:hosts].each do |host|
      ip_array = host['ip_address']
      @result[ip_array[0]] = {
          :cluster_name => host['cluster_name'],
          :dest => {}
      }
      @ssh_states[ip_array[0]] = {
          :session => nil,
          :iperf_server_pid => nil
      }
    end
    #init each of the dest in @result[:dest]
    @result.each_pair do |key,record|
      @option[:hosts].each do |host|
        next if host['ip_address'][0].to_s == key.to_s
        record[:dest][:"#{host['ip_address'][0]}"] = {
            :cluster_name => host['cluster_name'],
            :speed => nil,
            :lastUpdated => nil
        }
      end
    end
  end

  def start_ssh_connections
    puts "#{self.class.name}.#{__method__}, starting ssh connections to hosts..." if @put
    @logger.info("#{self.class.name}.#{__method__}, starting ssh connections to hosts...")
    @result.each_key do |host|
      begin
        @ssh_states[host][:session] = Net::SSH.start(host, @option[:username],
                                                     {:password => @option[:password],
                                                      :timeout => 60,
                                                      :auth_methods => [ 'password' ],
                                                      :number_of_password_prompts => 2})
        #If the username and/or password given to start are incorrect, authentication will fail.
        #If authentication fails, a Net::SSH::AuthenticationFailed exception will be raised.
      rescue => e
        puts "#{self.class.name}.#{__method__}, #{e.message}" if @put
        @logger.error "netperf_interCloud agent:"
        @logger.error "  #{self.class.name}.#{__method__}, #{e.message}"
        @logger.error "  #{e.backtrace.inspect}"
      else
        puts "#{self.class.name}.#{__method__}, started ssh connection to '#{host}' with session id '#{@ssh_states[host][:session]}'" if @put
        @logger.info("#{self.class.name}.#{__method__}, started ssh connection to '#{host}' with session id '#{@ssh_states[host][:session]}'")
      end
    end
  end

  def stop_ssh_connections
    puts "#{self.class.name}.#{__method__}, closing ssh connections to hosts..." if @put
    @logger.info("#{self.class.name}.#{__method__}, closing ssh connections to hosts...")
    @ssh_states.each_pair do |host,state|
      begin
        raise "#{self.class.name}.#{__method__}, No ssh session found to #{host}" if state[:session].nil?
        state[:session].close
      rescue => e
        puts "  #{e.message}" if @put
        @logger.error "netperf_interCloud agent:"
        @logger.error "  #{self.class.name}.#{__method__}, #{e.message}"
        @logger.error "  #{e.backtrace.inspect}"
      else
        puts "#{self.class.name}.#{__method__}, closed ssh connection to '#{host}' with session id '#{state[:session]}'" if @put
        @logger.info("#{self.class.name}.#{__method__}, close ssh connection to '#{host}' with session id '#{state[:session]}'")
      ensure
        state[:session] = nil
      end
    end
  end

  def ssh_exec!(ssh, command)
    output = {
        :stdout => "",
        :stderr => "",
        :exit_code => 1,
        :exit_signal => nil
    }
    begin
      ssh.open_channel do |channel|
        channel.exec(command) do |ch, success|
          unless success
            raise "#{self.class.name}.#{__method__}, FAILED: couldn't execute command (ssh.channel.exec)"
          end
          channel.on_data do |ch,data|
            output[:stdout]+=data
          end
          channel.on_extended_data do |ch,type,data|
            output[:stderr]+=data
          end
          channel.on_request("exit-status") do |ch,data|
            output[:exit_code] = data.read_long
          end
          channel.on_request("exit-signal") do |ch, data|
            output[:exit_signal] = data.read_string
          end
        end
      end
      ssh.loop
    rescue => e
      puts "  #{e.message}" if @put
      @logger.error "netperf_interCloud agent:"
      @logger.error "  #{e.message}"
      @logger.error "  #{e.backtrace.inspect}"
    else
      output
    end
  end

  # def get_nohup_pid(str)
  #   str.to_s.split(/ /)[1]
  # end

  def stop_residual_iperf_server
    get_pid_cmd = "ps gaux | grep iperf | grep -v grep | awk '{print $2}'"
    puts "#{self.class.name}.#{__method__}, checking residual iperf server on hosts..."  if @put
    @logger.info("#{self.class.name}.#{__method__}, checking residual iperf server on hosts...")
    @ssh_states.each_pair do |host,state|
      begin
        raise "#{self.class.name}.#{__method__}, Abort checking residual iperf server on #{host}, No ssh connection to #{host}" if state[:session].nil?

        pid_output = ssh_exec!(state[:session], get_pid_cmd)
        raise "#{self.class.name}.#{__method__}, unable to exec command '#{get_pid_cmd}' on '#{host}'" if pid_output[:exit_code] != 0
        if pid_output[:stdout].to_s.empty?
          puts "#{self.class.name}.#{__method__}, no residual iperf server found on '#{host}'" if @put
          @logger.info("#{self.class.name}.#{__method__}, no residual iperf server found on '#{host}'")
        else
          puts "#{self.class.name}.#{__method__}, found residual iperf server on '#{host}' with pid '#{pid_output[:stdout].chomp.to_i}', trying to kill..." if @put
          @logger.info("#{self.class.name}.#{__method__}, found residual iperf server on '#{host}' with pid '#{pid_output[:stdout].chomp.to_i}', trying to kill...")
          kill_cmd = "kill #{pid_output[:stdout].chomp.to_i}"
          kill_output = ssh_exec!(state[:session], kill_cmd)
          raise "#{self.class.name}.#{__method__}, ERROR in killing residual iperf server on '#{host}' with pid '#{pid_output[:stdout].chomp.to_i}'" if kill_output[:exit_code] != 0
          puts "#{self.class.name}.#{__method__}, killed residual iperf server on '#{host}' with pid '#{pid_output[:stdout].chomp.to_i}'..." if @put
          @logger.info("#{self.class.name}.#{__method__}, killed residual iperf server on '#{host}' with pid '#{pid_output[:stdout].chomp.to_i}'")
        end
      rescue => e
        puts "  #{e.message}" if @put
        @logger.error "netperf_interCloud agent:"
        @logger.error "  #{e.message}"
        @logger.error "  #{e.backtrace.inspect}"
      end
    end
  end

  def start_iperf_server
    cmd = "iperf -s -p #{@option[:iperf_port]}"
    nohup_cmd = "nohup #{cmd} > /dev/null 2>&1 &"
    get_pid_cmd = "ps gaux | grep iperf | grep -v grep | awk '{print $2}'"
    puts "#{self.class.name}.#{__method__}, trying to start iperf servers on each hosts with command '#{nohup_cmd}'..." if @put
    @logger.info("#{self.class.name}.#{__method__}, starting iperf servers on each hosts with command '#{nohup_cmd}'...")
    @ssh_states.each_pair do |host,state|
      begin
        puts "#{self.class.name}.#{__method__}, starting iperf server on '#{host}'..." if @put
        @logger.info("#{self.class.name}.#{__method__}, starting iperf server on '#{host}'...")

        raise "#{self.class.name}.#{__method__}, Abort starting iperf server on '#{host}', No ssh connection to #{host}" if state[:session].nil?

        iperf_out = ssh_exec!(state[:session], nohup_cmd) #return of exec
        raise "#{self.class.name}.#{__method__}, FAIL to start iperf server on '#{host}', unable to exec command '#{get_pid_cmd}'" if iperf_out[:exit_code] != 0

        pid_out = ssh_exec!(state[:session], get_pid_cmd)
        raise "#{self.class.name}.#{__method__}, FAIL to exec command #{get_pid_cmd} on '#{host}'" if pid_out[:exit_code] != 0
        raise "#{self.class.name}.#{__method__}, iperf server NOT started on '#{host}', return '#{pid_out[:stdout].to_s}' when exec command '#{get_pid_cmd}' on '#{host}'" if pid_out[:stdout].to_s.empty? or pid_out[:stdout].to_s.include?("Done")

        state[:iperf_server_pid] = pid_out[:stdout].chomp.to_i
        puts "#{self.class.name}.#{__method__}, started iperf server on '#{host}' with pid '#{state[:iperf_server_pid]}'..." if @put
        @logger.info("#{self.class.name}.#{__method__}, started iperf server on '#{host}' with pid '#{state[:iperf_server_pid]}'...")
      rescue => e
        puts "  #{e.message}" if @put
        @logger.error "netperf_interCloud agent:"
        @logger.error "  #{e.message}"
        @logger.error "  #{e.backtrace.inspect}"
      end
      #for test
      # if host == '172.17.0.50'
      #   state[:iperf_server_pid] = nil
      # end
    end
  end

  def stop_iperf_server
    cmd = "kill"
    puts "#{self.class.name}.#{__method__}, stopping iperf servers on each hosts..." if @put
    @logger.info("#{self.class.name}.#{__method__}, stopping iperf servers on each hosts...")
    @ssh_states.each_pair do |host,state|
      begin
        raise "#{self.class.name}.#{__method__}, Abort stopping iperf, No ssh connection to #{host}" if state[:session].nil?

        raise "#{self.class.name}.#{__method__}, Abort stopping iperf, iperf server not started on '#{host}'" if state[:iperf_server_pid].nil?

        stop_cmd = "#{cmd} #{state[:iperf_server_pid]}"
        puts "#{self.class.name}.#{__method__}, stopping iperf server on '#{host}' with command '#{stop_cmd}'..." if @put
        @logger.info("#{self.class.name} stopping iperf server on '#{host}' with command '#{stop_cmd}'...")

        stop_output = ssh_exec!(state[:session], stop_cmd)
        raise "#{self.class.name}.#{__method__}, ERROR stopping iperf server on '#{host}' with pid '#{state[:iperf_server_pid]}'" if stop_output[:exit_code] != 0

        puts "#{self.class.name}.#{__method__}, stopped iperf server on '#{host}' with pid '#{state[:iperf_server_pid]}'" if @put
        @logger.info("#{self.class.name}.#{__method__}, stopped iperf server on '#{host}' with pid '#{state[:iperf_server_pid]}'")
      rescue => e
        puts "  #{e.message}" if @put
        @logger.error "netperf_interCloud agent:"
        @logger.error "  #{e.message}"
        @logger.error "  #{e.backtrace.inspect}"
      ensure
        state[:iperf_server_pid] = nil
      end
    end
  end

  def start_iperf_monitoring
    puts "#{self.class.name}.#{__method__}, start monitoring network speed..." if @put
    @logger.info("#{self.class.name}.#{__method__}, start monitoring network speed...")
    @result.each_pair do |src,record|
      record[:dest].each_pair do |dest, value|
        begin
          raise "#{self.class.name}.#{__method__}, Abort monitoring from '#{src}' to '#{dest}', No ssh connection to #{src}" if @ssh_states[src.to_s][:session].nil?
          raise "#{self.class.name}.#{__method__}, Abort monitoring from '#{src}' to '#{dest}', No iperf server on '#{dest}'" if @ssh_states[dest.to_s][:iperf_server_pid].nil?

          cur = Time.now.to_i
          puts "#{self.class.name}.#{__method__}, monitoring network speed from '#{src}' (ssh session #{@ssh_states[src][:session]}) to '#{dest}' with iperf server pid '#{@ssh_states[dest.to_s][:iperf_server_pid]}'..." if @put
          @logger.info("#{self.class.name}.#{__method__}, monitoring network speed from '#{src}' (ssh session #{@ssh_states[src][:session]}) to '#{dest}' with iperf server pid '#{@ssh_states[dest.to_s][:iperf_server_pid]}'...")
          iperf_cmd = "iperf -c #{dest} -p #{@option[:iperf_port]} -f m -i #{@option[:iperf_time]}"

          iperf_output = ssh_exec!(@ssh_states[src][:session], iperf_cmd)
          raise "#{self.class.name}.#{__method__}, ERROR exec '#{iperf_cmd}' on '#{src}' to '#{dest}'" if iperf_output[:exit_code] != 0
          raise "#{self.class.name}.#{__method__}, ERROR: return '#{iperf_output[:stdout]}' when exec '#{iperf_cmd}' from '#{src}' to '#{dest}'" if iperf_output[:stdout].to_s.include? "connect failed"

          puts "#{self.class.name}.#{__method__}, return '#{iperf_output[:stdout].inspect}' when exec '#{iperf_cmd}' from '#{src}' to '#{dest}'" if @put
          @logger.info("#{self.class.name}.#{__method__}, return '#{iperf_output[:stdout].inspect}' when exec '#{iperf_cmd}' from '#{src}' to '#{dest}'")
          speed = iperf_output[:stdout].to_s.split(/\n/)[-1].split(/ /)[-2]
          puts "#{self.class.name}.#{__method__}, iperf reports #{speed} Mbits/s from '#{src}' to '#{dest}'" if @put
          @logger.info("#{self.class.name}.#{__method__}, iperf reports #{speed} Mbits/s from '#{src}' to '#{dest}'")
          value[:speed] = speed.to_i * 1024 * 1024
        rescue => e
          puts "  #{e.message}" if @put
          value[:speed] = -1
          @logger.error "netperf_interCloud agent:"
          @logger.error "  #{e.message}"
          @logger.error "  #{e.backtrace.inspect}"
        ensure
          value[:lastUpdated] = cur
        end
      end

    end
  end

  def check_time
    @exec_time = ''
    cur = Time.new.getlocal("+08:00") #convert to CST Time Zone
    @exec_time = cur.strftime('%H:%M:%S') if @option[:monit_time].any? {|t| cur.strftime('%H:%M').eql?(t)}
  end

  def work
    check_time
    if !@exec_time.empty?
      puts "#{self.class.name}.#{__method__}, Time #{@exec_time} in #{@option[:monit_time].inspect}, start monitoring..." if @put
      @logger.info("#{self.class.name}.#{__method__}, Time #{@exec_time} in #{@option[:monit_time].inspect}, start monitoring...")
      @logger.info("#{self.class.name} is working with configuration #{@option}...")
      puts "***********************************" if @put
      start_ssh_connections
      stop_residual_iperf_server
      start_iperf_server
      start_iperf_monitoring
      stop_iperf_server
      stop_ssh_connections
      puts @result if @put
      @logger.info("Result: #{@result}")
      puts "***********************************" if @put
    else
      puts "#{self.class.name} waits, not meet exec time #{@option[:monit_time].inspect} requirement" if @put
      @logger.info("#{self.class.name} waits, not meet exec time #{@option[:monit_time].inspect} requirement")
    end
  end

  def migrate
    metrics_list = []
    if !@exec_time.empty?
      puts "#{self.class.name}.#{__method__}, agent started monitoring at #{@exec_time}, now begin to migrate..." if @put
      @logger.info("#{self.class.name}.#{__method__}, agent started monitoring at #{@exec_time}, now begin to migrate...")
      timestamp = Time.now.to_i.to_s
      targetprefix = @option[:org_env] + "." + @option[:basetarget] + ".interCloud"

      @result.each_pair do |src,record|
        src_cluster = record[:cluster_name]
        record[:dest].each_pair do |dest, dest_record|
          dest_cluster = dest_record[:cluster_name]
          info = {
              :sn => @option[:basetarget] + "-" + timestamp + "-interCloud",
              :target => targetprefix,
              :instance => src_cluster.to_s + "->" + dest_cluster.to_s,
              :status => dest_record[:speed].to_s,
              :details => "Avg network speed in #{@option[:iperf_time]} seconds from #{src_cluster.to_s} (#{src}) to #{dest_cluster} (#{dest}) in unit bits/second",
              :timestamp => dest_record[:lastUpdated]*1000,
              :duration => 0,
              :attachments => []
          }
          metrics = Metrics.new(@option[:pin_code], info)
          metrics_list << metrics
        end
      end
    end
    puts metrics_list if @put
    merged = Metrics.merge(metrics_list)
  end


end


