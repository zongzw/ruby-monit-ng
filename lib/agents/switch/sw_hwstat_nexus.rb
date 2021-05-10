require_relative '../../agents/agent'
require_relative '../../base/get/snmpwalk'
require_relative '../../base/get/snmpget'
require_relative '../../base/get/sshget2'
require_relative '../../base/metrics'

class SwHwstatNexus < Agent
  #
  # option = {
  #     :ip_address => ip,
  #     :community => community,
  #     :interval => @monit_items[item],
  #     :basetarget => base_target,
  #     :pin_code => @pin_code,
  #     :org_env => @org_env,
  #     :username => username,
  #     :password => password,
  # }
  #
  # case item
  #   when 'hwstat'
  #     hwstat_agent = SwHwstat.new(option)
  #     self.register(hwstat_agent)
  #   else
  #     @logger.error "unrecognized monitored item: #{item}"
  # end
  #

  attr_reader :result
  def initialize(option)
    super

    @cpuoids = {
        :cseSysCPUUtilization         => '1.3.6.1.4.1.9.9.305.1.1.1.0'
    }

    @walk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @get = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @ssh = SshGet2.new(:ip_address => option[:ip_address], :username => option[:username], :password => option[:password])
    @result = {}
  end


  def work
    @logger.debug("#{self.class.name} is working")
    @result = {}

    show_environment_temporature
    show_system_resources

    @result[:cpu] = []
    @get.deal(@cpuoids.values) do |varbind|
      @result[:cpu] << varbind.value.to_i
    end

    @logger.debug(@result)
  end

  # ibm.allenvs.switch.<ip>.temperature
  # ibm.allenvs.switch.<ip>.memoryusage
  # ibm.allenvs.switch.<ip>.cpuusage
  def migrate
    metrics_list = []
    timestamp = Time.now.to_i.to_s
    ipstring = @option[:ip_address].gsub '.', '-'

    @result[:temperature].each_pair do |key, value|
      info = {
          :sn => ipstring + "-" + timestamp + '-' + key,
          :target => @option[:org_env] + "." + @option[:basetarget] +
              ".#{ipstring}.temperature",
          :instance => key,
          :status => 100 * value[:t]/value[:m],
          :details => "Cur: #{value[:t]}.C, Max: #{value[:m]}",
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics

    end

    info = {
        :sn => ipstring + timestamp,
        :target => @option[:org_env] + "." + @option[:basetarget] +
            ".#{ipstring}.memoryusage",
        :instance => ipstring,
        :status => 100 * @result[:memory][:used] / @result[:memory][:total],
        :details => "[used: #{@result[:memory][:used]}, free: #{@result[:memory][:total]}]",
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    @cpuoids.keys.each_with_index do |key, index|
      info = {
          :sn => ipstring + timestamp,
          :target => @option[:org_env] + "." + @option[:basetarget] +
              ".#{ipstring}.cpuusage",
          :instance => key,
          :status => @result[:cpu][index],
          :details => "#{key}: #{@result[:cpu][index]}",
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    merged = Metrics.merge(metrics_list)
  end

  def show_environment_temporature
    @result[:temperature] = {}
    @logger.debug("begin show_environment_temporature")
    @ssh.deal('show environment temperature') do |out|
      @logger.debug("ssh get the output: #{out}")
      lines = out.split("\n")
      getline = false
      sensor = temper = status = minort = nil

      lines.each do |line|
        line = line.strip
        if line == '' || ! (line =~ /^-+$/).nil? || !(line.index('Celsius').nil?)
          next
        end

        if /^Module\s+Sensor\s+MajorThresh\s+MinorThres\s+CurTemp\s+Status$/.match(line)
          sensor = line.index('Sensor')...line.index('MajorThresh')
          temper = line.index('CurTemp')...line.index('Status')
          status = line.index('Status')...(line.index('Status')+'Status'.length)
          minort = line.index('MinorThres')...line.index('CurTemp')
          getline = true
          next
        end

        if getline
          se = line[sensor].strip
          te = line[temper].strip.to_i
          st = line[status].strip
          mt = line[minort].strip.to_i
          if st == 'ok' || st == 'Ok'
            @result[:temperature][se] = {:t => te, :m => mt}
          end
        end
      end
    end

    @logger.debug("end show_environment_temporature: #{@result[:temperature]}")
  end

  def show_system_resources
    @result[:memory] = {}
    @ssh.deal('show system resources') do |out|
      lines = out.split('\n')
      lines.each do |line|
        line = line.strip
        if /Memory usage:\s+(\d+)K total,\s+(\d+)K used,\s+(\d+)K free/.match(line)
          total = $1
          used = $2
          @result[:memory] = {:total => total.to_i, :used => used.to_i}
        end
      end
    end
  end
end