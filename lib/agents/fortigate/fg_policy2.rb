# DEPRECATED
# This class is originally used for collect changes of policies.
# Now it was replaced by fg_config.rb

require 'differ'

require_relative '../agent'
require_relative '../../../lib/base/get/scpget'
require_relative '../../../lib/base/get/snmpbulk'
require_relative '../../../lib/base/get/snmpget'
require_relative '../../../lib/base/metrics'

class FgPolicy2 < Agent

=begin
    policy2_agent = FgPolicy2.new(:ip_address => ip_address,
                                    :community => 'monit_fg',
                                    :username => 'admin',
                                    :password => 'landing',
                                    :serial_number => serial_number,
                                    :basetarget => base_target,
                                    :pin_code => marmotinfo['pin_code'],
                                    :org_env => marmotinfo['org_env'])
=end

  attr_accessor :origin, :diff
  def initialize(option)
    super
    check_option

    @get = ScpGet.new(:ip_address => @option[:ip_address], :username => @option[:username],
                      :options => {:password => @option[:password], :port => @option[:port]})
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :username, :password, :cluster_name, :basetarget, :pin_code, :org_env, :community, :port].each do |key|
      if !keyset.include? key
        missing << key
      end
    end
    if !missing.empty?
      raise ArgumentError, "Missing the following arguments: #{missing.to_s}"
    end
  end

  def work
    @logger.info("#{self.class.name} is working ...")

    @diff = {}
    data = ''
    @get.deal(['sys_config']) do |out|
      data = out
    end

    if data.nil?
      @logger.error "No sysconfig content gotten."
      raise RuntimeError, "No sysconfig content gotten."
    end

    updated = parse_fgt_config(data)

    if @origin.nil?
      @origin = updated
      @logger.info("initial policy content: #{@origin}")
    else
      begin
        Differ.format = :ascii
        updated.each_pair do |key, value|
          if ! @origin[key].eql? updated[key]
            diffline = Differ.diff_by_line(updated[key], @origin[key]).to_s
            @diff[key] = "Policy Changed for #{key}: #{diffline}, original: #{@origin[key]}, target: #{updated[key]}"
            @logger.info("#{@diff[key]}")
          end
        end
      ensure
        @origin = updated
      end
    end
  end

  # ibm.allenvs.fortigate.fg300c.policy_changed
  def migrate
    timestamp = Time.now.to_i.to_s
    metrics_list = []

    status = 0
    details = ''

    @diff.each_pair do |key, value|
      if ! value.empty?
        status = 1
        details += value
      end
    end

    info = {
        :sn => @option[:cluster_name] + timestamp,
        :target => @option[:org_env] + "." + @option[:basetarget] +
            ".#{@option[:cluster_name]}.policy_changed",
        :instance => @option[:cluster_name],
        :status => status,
        :details => details,
        :timestamp => Time.now().to_i() * 1000,
        :duration => 0,
        :attachments => []
    }
    metrics = Metrics.new(@option[:pin_code], info)
    metrics_list << metrics
    merged = Metrics.merge(metrics_list)
  end

  def find_vdoms(data)
    m = /^config vdom$/.match(data)
    start = m.begin(0)
    m = /^end$/.match(data)
    over = m.end(0)

    progress = over
    vdominfo = data[start..over]

    postmatch = vdominfo
    vdomlist = []
    loop {
      m = /^edit (\S+)$/.match(postmatch)
      break if m.nil?
      vdomlist += m.captures

      postmatch = m.post_match
    }

    @logger.info("vdom list: #{vdomlist}")
    @logger.debug("sys_config working point: #{progress}")
    return vdomlist, progress
  end

  def find_policies(vdomlist, data, startfrom)
    vdompolicy = {}
    postmatch = data[startfrom..-1]
    vdomlist.each do |vd|
      m = /^config vdom$/.match(postmatch)
      raise RunTimeError, "no vdom configuration found." if m.nil?

      m = /^edit #{vd}$/.match(postmatch)
      postmatch = m.post_match
      m = /^config firewall policy$/.match(postmatch)
      start = m.begin(0)
      postmatch = postmatch[start..-1]
      m = /^end$/.match(postmatch)
      over = m.end(0)

      vdompolicy[vd] = postmatch[0..over]

      postmatch = m.post_match
    end

    vdompolicy
  end

  def parse_fgt_config(data)
    vl, starts = find_vdoms(data)
    vdompolicy = find_policies(vl, data, starts)
    vdompolicy
  end

end
