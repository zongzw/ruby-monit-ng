require_relative '../agent'
require_relative '../../base/get/snmpget'
require_relative '../../base/get/snmpbulk'
require_relative '../../base/get/snmpwalk'

class QrHwStat < Agent
  def initialize(option)
    super
    check_option

    @snmpget = SnmpGet.new(@option)
    @snmpbulk = SnmpBulk.new(@option)
    @snmpwalk = SnmpWalk.new(@option)

    @sysNameOid = '1.3.6.1.2.1.1.5.0'

    @@cpuoids = {
        :ssCpuRawUser => '1.3.6.1.4.1.2021.11.50.0',
        :ssCpuRawNice => '1.3.6.1.4.1.2021.11.51.0',
        :ssCpuRawSystem => '1.3.6.1.4.1.2021.11.52.0',
        :ssCpuRawIdle => '1.3.6.1.4.1.2021.11.53.0',
        :ssCpuRawWait => '1.3.6.1.4.1.2021.11.54.0',
        :ssCpuRawKernel => '1.3.6.1.4.1.2021.11.55.0',
        :ssCpuRawInterrupt => '1.3.6.1.4.1.2021.11.56.0',
        :ssCpuRawSoftIRQ => '1.3.6.1.4.1.2021.11.61.0',
        :ssCpuRawSteal => '1.3.6.1.4.1.2021.11.64.0',
        :ssCpuRawGuest => '1.3.6.1.4.1.2021.11.65.0',
        :ssCpuRawGuestNice => '1.3.6.1.4.1.2021.11.66.0',
    }

    @@memoids = {
        # there's no oid can be used to figure out
        # 1. how many total virtual memory
        # 2. how many total virtual memory are used or free.
        # 3. memBuffer and memCached are memory that just be cached or buffered, not really used.
        # 4. memBuffer and memCached are both referring not only real memory but also virtual memory.

        # The total amount of real/physical memory installed on this host.
        :memTotalReal => '1.3.6.1.4.1.2021.4.5.0',

        # The amount of real/physical memory currently unused or available.
        :memAvailReal => '1.3.6.1.4.1.2021.4.6.0',

        # The total amount of memory free or available for use on this host.
        # This value typically covers both real memory and swap space or virtual memory.
        :memTotalFree => '1.3.6.1.4.1.2021.4.11.0',

        # The total amount of real or virtual memory currently allocated for use as memory buffers.
        # This object will not be implemented on hosts where the
        #      underlying operating system does not explicitly identify
        #      memory as specifically reserved for this purpose.
        :memBuffer => '1.3.6.1.4.1.2021.4.14.0',

        # The total amount of real or virtual memory currently allocated for use as cached memory.
        # This object will not be implemented on hosts where the
        #      underlying operating system does not explicitly identify
        #      memory as specifically reserved for this purpose.
        :memCached => '1.3.6.1.4.1.2021.4.15.0'
    }

    @@diskoids = {
        :hrStorageDescr => '1.3.6.1.2.1.25.2.3.1.3',
        :hrStorageSize => '1.3.6.1.2.1.25.2.3.1.5',
        :hrStorageUsed => '1.3.6.1.2.1.25.2.3.1.6'
    }

    @cpuorig = {}
    @result = {}
  end

  def work
    @logger.info("#{self.class.name} is working...")

    @systemName = @option[:ip_address]
    @snmpget.deal(@sysNameOid) do |varbind|
      @systemName = varbind.value.to_s
    end

    cpu_usage

    @vdmetrics = []
    @snmpwalk.deal(@@diskoids.values) do |vdlist|
      metric = []
      vdlist.each do |vd|
        metric << {:name => vd.name.to_s, :value => vd.value.to_s}
      end
      @vdmetrics << metric
    end

    mem_usage
    disk_usage
  end

  # ibm.allenvs.qradar.hwstat.<ipstring>.[cpu_usage/mem_usage/disk_usage]
  def migrate
    metrics_list = []

    timestamp = Time.now.to_i.to_s
    targetprefix = @option[:org_env] + "." + @option[:basetarget]
    sysname = @systemName.gsub('.', '-')

    [:cpu_usage, :mem_usage].each do |item|
      info = {
          :sn => timestamp,
          :target => targetprefix + ".hwstat.#{sysname}.#{item.to_s}",
          :instance => @option[:ip_address],
          :status => @result[item],
          :details => '',
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    end

    @result[:disk_usage].each_key { |key|
      info = {
          :sn => timestamp,
          :target => targetprefix + ".hwstat.#{sysname}.disk_usage",
          :instance => key,
          :status => @result[:disk_usage][key],
          :details => '',
          :timestamp => Time.now().to_i() * 1000,
          :duration => 0,
          :attachments => []
      }
      metrics = Metrics.new(@option[:pin_code], info)
      metrics_list << metrics
    }
    merged = Metrics.merge(metrics_list)
    merged
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :basetarget, :pin_code, :org_env, :community, :snmpport, :interval, :disk_check].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

  def mem_usage
    @vdmetrics.each do |line|
      if line[0][:value] == 'Virtual memory'
        @memTotalVirtual = line[1][:value].to_i
        break
      end
    end

    @snmpget.deal(@@memoids.values) do |vd|
      if @@memoids[:memTotalReal].end_with? vd.name.to_s.split('.')[-2..-1].join('.')
        @memTotalReal = vd.value.to_i
      end
      if @@memoids[:memTotalFree].end_with? vd.name.to_s.split('.')[-2..-1].join('.')
        @memTotalFree = vd.value.to_i
      end
      if @@memoids[:memBuffer].end_with? vd.name.to_s.split('.')[-2..-1].join('.')
        @memBuffer = vd.value.to_i
      end
      if @@memoids[:memCached].end_with? vd.name.to_s.split('.')[-2..-1].join('.')
        @memCached = vd.value.to_i
      end
    end

    # Used memory = memTotalReal + "Total Virtual memory" - memTotalFree - memBuffer - memCached
    # Usage = "Used memory"/(memTotalReal + "Total Virtual memory")
    #puts "(#{@memTotalReal} + #{@memTotalVirtual} - #{@memTotalFree} - #{@memBuffer} - #{@memCached}) / (#{@memTotalReal} + #{@memTotalVirtual})"
    @result[:mem_usage] = 100 * (@memTotalReal + @memTotalVirtual - @memTotalFree - @memBuffer - @memCached) / (@memTotalReal + @memTotalVirtual)
  end

  def cpu_usage
    @result[:cpu_usage] = 0
    used = 0
    idle = 0
    @snmpget.deal(@@cpuoids.values) do |vd|
      if vd.value.to_s == 'noSuchObject'
        next
      end
      if @@cpuoids[:ssCpuRawIdle].end_with? vd.name.to_s.split('.')[-2..-1].join('.')
        idle = vd.value.to_i
      else
        used += vd.value.to_i
      end
    end

    if @cpuorig.empty?
      @result[:cpu_usage] = 0
    else
      total = used + idle - @cpuorig[:used] - @cpuorig[:idle]
      if total == 0
        @result[:cpu_usage] = 0
      else
        @result[:cpu_usage] = 100 * (used - @cpuorig[:used])/total
      end

    end

    @cpuorig = {
        :used => used,
        :idle => idle
    }
  end

  def disk_usage
    @result[:disk_usage] = {}
    @vdmetrics.each do |line|
      if line[0][:value].start_with?('/') && @option[:disk_check].include?(line[0][:value])
        @result[:disk_usage][line[0][:value]] = 100 * line[2][:value].to_i / line[1][:value].to_i
      end
    end
  end
end