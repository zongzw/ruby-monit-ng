# DEPRECATED
# replaced by fg_policy2.rb

require 'differ'

require_relative '../agent'
require_relative '../../../lib/base/get/sshget'
require_relative '../../../lib/base/get/snmpbulk'
require_relative '../../../lib/base/get/snmpget'
require_relative '../../../lib/base/metrics'

class FgPolicy < Agent

=begin
    policy_agent = FgPolicy.new(:ip_address => ip_address,
                                    :community => 'monit_fg',
                                    :username => 'admin',
                                    :password => 'landing',
                                    :serial_number => serial_number,
                                    :basetarget => base_target,
                                    :pin_code => marmotinfo['pin_code'],
                                    :org_env => marmotinfo['org_env'])
=end

  def initialize(option)
    super
    check_option

    @fgVdEntName      = ['1.3.6.1.4.1.12356.101.3.2.1.1.2']   # vdom name
    @fgVdNumber       = ['1.3.6.1.4.1.12356.101.3.1.1.0']     # vdom number

    @get = SshGet.new(:ip_address => @option[:ip_address], :username => @option[:username],
                      :options => {:password => @option[:password]})
    @snmpbulk = SnmpBulk.new(:ip_address => @option[:ip_address], :community => @option[:community])
    @snmpget = SnmpGet.new(:ip_address => @option[:ip_address], :community => @option[:community])

    @origin = {}
  end

  def check_option
    keyset = @option.keys
    missing = []
    [:ip_address, :username, :password, :cluster_name, :basetarget, :pin_code, :org_env, :community].each do |key|
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

  def work
    @logger.info("#{self.class.name} is working ...")

    vdoms = vdomlist

    @get.deal(['config global', 'config system console', 'set output standard', 'end']) do |out|
      @logger.info "set the output mode to be standard."
    end

    @diff = {}
    vdoms.each do |vd|
      cmds = ['config vdom', "edit #{vd}", 'show firewall policy', 'end']
      data = ''
      @get.deal(cmds) do |out|
        data = out
      end

      Differ.format = :ascii
      if @origin[vd].nil? || @origin[vd].empty?
        @origin[vd] = data
        @logger.info "Original configuration for #{vd}: %s" % data
      else
        if data.eql? @origin[vd]
          @logger.info "No policy change for #{vd}"
          @diff[vd] = ''
        else
          diffline = Differ.diff_by_line(data, @origin[vd]).to_s
          @diff[vd] = "Policy Changed for #{vd}: #{diffline}, original: #{@origin[vd]}, target: #{data}"

          @origin[vd] = data
        end
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
end
