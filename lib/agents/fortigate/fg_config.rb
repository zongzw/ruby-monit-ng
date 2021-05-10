require_relative '../agent'
require_relative '../../base/get/sshget'
require_relative '../../base/get/snmpget'
require_relative '../../base/get/snmpbulk'

require_relative '../../../data/fortigate-log-filter'
require_relative '../../../data/fortigate-timezones'

class FgConfig < Agent

  def initialize(option)
    super
    check_option

    @fgVdEntName      = ['1.3.6.1.4.1.12356.101.3.2.1.1.2']   # vdom name
    @fgVdNumber       = ['1.3.6.1.4.1.12356.101.3.1.1.0']     # vdom number

    @sshget = SshGet.new(:ip_address => @option[:ip_address], :username => @option[:username],
                      :options => {:password => @option[:password], :port => @option[:port]})
    @snmpget = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @snmpbulk = SnmpBulk.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @filterout = FortigateLogFilter::FILTEROUT
    @filterin  = FortigateLogFilter::FILTERIN

    #
    # @result = {
    #     :vdoms => [:vdomname1, :vdomname2, :...]
    #     :<vdomname1> => [],
    #     :<vdomname2> => [logentry1, logentry2, ..],
    #     :..
    # }
    @result = {
        :vdoms => []
    }
    @orig_global_config = ""
  end

  def work
    @logger.info("#{self.class.name} is working ...")

    # to check if there is the change of adding/deleting vdoms
    @vdomchanges = {}
    vdoms = vdomlist
    @vdoms_k = []
    vdoms.each do |vd|
      @vdoms_k << vd.to_sym
    end

    if @result[:vdoms].empty?
      @vdomchanges = {}
      @result[:vdoms] = @vdoms_k
    else
      if ! @vdoms_k == @result[:vdoms]
        @vdomchanges = {
            :orig => @result[:vdoms],
            :last => @vdoms_k
        }
        @result[:vdoms] = @vdoms_k
      end
    end

    # get time zone
    timezone
    curtime = Time.now
    lnpertime = 200

    # for each vdom, check the vdom's log
    @vdoms_k.each do |vdk|
      @result[vdk] = []

      # get device index and category index
      device_and_category(vdk)
      # get total log number
      total_log_number(vdk)

      # collecting all recent logs
      logs = []
      times = 0
      while true
        logs += logs_start_with_length(vdk, lnpertime * times + 1, lnpertime)

        if (logs.length == 0 || logs.length == @totallognumber)
          break
        end

        if logs_is_new_than(logs[-1], curtime - @option[:interval])
          times += 1
        else
          break
        end
      end

      # check logs and select only the configuration logs
      logs.each do |logentry|
        if logs_is_new_than(logentry, curtime - @option[:interval])
          matched = false
          @filterin.each_pair do |key, value|
            value.each do |mstr|
              if /#{key}="?#{mstr}/.match logentry
                matched = true
                break
              end
            end
          end
          @result[vdk] << logentry if matched
        end
      end
    end
    #puts @result
  end

  # bmxcn.allenvs.fortigate.<cluster name>.config_changed
  def migrate
    timestamp = Time.now.to_i.to_s
    metrics_list = []

    status = 0
    details = []
    if ! @vdomchanges.empty?
      status = 1
      details << "vdom changes: from: #{@vdomchanges[:orig]}, to: #{@vdomchanges[:last]}"
    end

    @result[:vdoms].each do |vd|
      if ! @result[vd].empty?
        status = 1
        details << "#{vd} configuration change: \n#{@result[vd].join("\n")}\n"
      end
    end

    info = {
        :sn => @option[:cluster_name] + timestamp,
        :target => @option[:org_env] + "." + @option[:basetarget] +
            ".#{@option[:cluster_name]}.config_changed",
        :instance => @option[:cluster_name],
        :status => status,
        :details => details.join("\n"),
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics
    merged = Metrics.merge(metrics_list)
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :username, :password, :cluster_name,
     :basetarget, :pin_code, :org_env, :community, :port, :interval].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

  def vdomlist
    vdom_number = 0
    @snmpget.deal(@fgVdNumber) do |varbind|
      vdom_number = varbind.value.to_i
    end

    vdoms = []
    @snmpbulk.deal(@fgVdEntName + [0, vdom_number]) do |vditem|
      vdIndex = vditem.name.to_s.split('.')[-1].to_i
      vdoms << vditem.value.to_s
    end

    @logger.info "vdom list: #{vdoms}"
    vdoms
  end

  def timezone
    cmd = [
        'config global',
        'show | grep timezone',
        'end'
    ]

    @timezone = "+08:00"
    @sshget.deal(cmd) do |out|
      out.split("\n").each do |line|
        m = /\s*set timezone (\d+).*/.match(line)
        if ! m.nil?
          timezoneno = m[1]
          @timezone = FortigateTimeZone::TIMEZONE[timezoneno]
          @logger.info("timezone: #{@timezone}")
          #puts @timezone
        end
      end
    end
  end

  def device_and_category(vdomkey)
    # get disk index and event index, only event log on disk be considered.
    @diskindex = -1
    @eventindex = -1
    @sshget.deal(['config vdom',
                  "edit #{vdomkey.to_s}",
                  'execute log filter device',
                  'execute log filter category',
                  'end']) do |out|
      out.split("\n").each do |line|
        m = /^\s+(\d+): disk$/.match(line)
        if ! m.nil?
          @diskindex = m[1]
        end

        m = /^\s+(\d+): event$/.match(line)
        if ! m.nil?
          @eventindex = m[1]
        end
      end
    end
    raise RunTimeError, "no disk log found." if @diskindex == -1
    raise RunTimeError, "no event log found." if @eventindex == -1
  end

  def total_log_number(vdomkey)
    cmd = [
        'config vdom',
        "edit #{vdomkey.to_s}",
        "execute log filter device #{@diskindex}",
        "execute log filter category #{@eventindex}",
        "execute log display",
        'end'
    ]

    @totallognumber = 0
    @sshget.deal(cmd) do |out|
      m = /(\d+) logs found/.match(out)
      if ! m.nil?
        @totallognumber = m[1].to_i
      end
    end

    @logger.info("total log number for #{vdomkey} is #{@totallognumber}")
    #puts "total number: #{@totallognumber}"
  end

  def logs_start_with_length(vdomkey, startline, viewlines)
    raise ArgumentError, "viewlines cannot be larger than 1000 or less than 5" if (viewlines > 1000 || viewlines < 5)
    cmd = [
        'config vdom',
        "edit #{vdomkey.to_s}",
        "execute log filter device #{@diskindex}",
        "execute log filter category #{@eventindex}",
        "execute log filter start-line #{startline}",
        "execute log filter view-lines #{viewlines}",
        "execute log display",
        'end'
    ]

    logs = []
    @sshget.deal(cmd) do |out|
      out.split("\n").each do |line|
        if /^\d+: .*$/.match(line)
          logs << line
        end
      end
    end

    logs
  end

  def logs_is_new_than(logentry, giventime)
    m = /^\d+: date=(\d{4})-(\d{2})-(\d{2}) time=(\d{2}):(\d{2}):(\d{2}) .*/.match(logentry)
    raise RuntimeError, "invalid log entry: #{logentry}" if m.nil?

    (Time.new(m[1], m[2], m[3], m[4], m[5], m[6], @timezone) > giventime) ? true : false
  end
end