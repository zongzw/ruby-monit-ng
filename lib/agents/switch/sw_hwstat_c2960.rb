require_relative '../../agents/agent'
require_relative '../../base/get/snmpwalk'
require_relative '../../base/get/snmpget'
require_relative '../../base/metrics'

class SwHwstatC2960 < Agent

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

  def initialize(option)
    super

    @cpuoids = {
        :busyPer                              => '1.3.6.1.4.1.9.2.1.56.0',
        :avgBusy1                             => '1.3.6.1.4.1.9.2.1.57.0',
        :avgBusy5                             => '1.3.6.1.4.1.9.2.1.58.0'
    }

    @tmoids = {
        :ciscoEnvMonTemperatureStatusValue    => "1.3.6.1.4.1.9.9.13.1.3.1.3",
        :ciscoEnvMonTemperatureThreshold      => "1.3.6.1.4.1.9.9.13.1.3.1.4"
    }

    @memoids = {
        :ciscoMemoryPoolName                  => '1.3.6.1.4.1.9.9.48.1.1.1.2',
        :ciscoMemoryPoolUsed                  => "1.3.6.1.4.1.9.9.48.1.1.1.5",
        :ciscoMemoryPoolFree                  => "1.3.6.1.4.1.9.9.48.1.1.1.6"
    }

    @walk = SnmpWalk.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @get = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])

  end

  def work
    @logger.debug("#{self.class.name} is working")
    @result = {}

    @walk.deal(@tmoids.values) do |row|
      @result[:tmcur] = row[0].value.to_i
      @result[:tmthh] = row[1].value.to_i
    end

    @result[:mem] = {}
    @walk.deal(@memoids.values) do |row|
      @result[:mem][row[0].value.to_s] = [row[1].value.to_i, row[2].value.to_i]
    end

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

    info = {
        :sn => ipstring + "-" + timestamp,
        :target => @option[:org_env] + "." + @option[:basetarget] +
            ".#{ipstring}.temperature",
        :instance => ipstring,
        :status => 100 * @result[:tmcur] / @result[:tmthh],
        :details => "CurrentTemperature: #{@result[:tmcur]} / TemperatureThreshold:#{@result[:tmthh]}",
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics

    @result[:mem].each do |key, value|
      info = {
          :sn => ipstring + timestamp,
          :target => @option[:org_env] + "." + @option[:basetarget] +
              ".#{ipstring}.memoryusage",
          :instance => key,
          :status => 100 * value[0] / (value[0]+value[1]),
          :details => "[used: #{value[0]}, free: #{value[1]}]",
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

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

end