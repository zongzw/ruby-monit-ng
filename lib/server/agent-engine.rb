require 'singleton'
require 'json'

require_relative '../base/metrics'
require_relative '../utils/netutil'
require_relative '../utils/logger'

class AgentsServer
  include Singleton

  attr_reader :org_env, :pin_code, :monit_intervals
  def initialize
    @metrics_lock = Mutex.new
    @metrics_list = []
    @agent_list = []
    @logger = MonitLogger.instance.logger
  end

  def register(agent)
    @logger.info "#{agent.class.name} registered .."
    @agent_list << agent
  end

  def launch_get
    @logger.info "server launching get ..."
      @agent_list.each do |agent|
        @logger.info "#{agent.class.name} start to work .."
        Thread.new do
          Thread.current['name'] = "#{agent.class.name}-#{agent.option[:id]}"
          while true
            begin
              agent.work
              push_metrics(agent.migrate)
            rescue => e
              @logger.error "agent #{Thread.current['name']} fails to get information"
              @logger.error "#{e.class.name}: #{e.message}; #{e.backtrace}"
              @logger.error $@
            ensure
              agent.rest
            end
          end
        end
      end
  end

  def launch_post
    @logger.info "server launching post ..."
    Thread.new do
      Thread.current['name'] = "PostMetrics"
      while true
        while metrics = pop_metrics
          begin
            @logger.info "new metrics to post ...#{metrics}"
            metrics.values.each do |value|
              NetUtil.post_json(@url, value.to_json)
            end
          rescue => e
            @logger.error "failed to post: #{e.message}"
            @logger.error "#{$@}"
            @logger.error "#{e.class.name}: #{e.backtrace}"
          end
        end
        sleep 1
      end
    end
  end

  def push_metrics(metrics)
    @metrics_lock.lock
    if !metrics.nil?
      @logger.info "add new metrics #{metrics}"
      if metrics.is_a? Array
        @metrics_list += metrics
      else
        @metrics_list << metrics
      end
    end
    @metrics_lock.unlock
    nil
  end

  def set_marmot_info(obj)
    raise ArgumentError, "Missing arguement: collector" if obj['collector'].nil?
    raise ArgumentError, "Missing arguement: pin_code" if obj['pin_code'].nil?
    raise ArgumentError, "Missing arguement: org_env" if obj['org_env'].nil?

    @url = "http://%s/MarmotCollector/api/v1/metrics" % obj['collector']
    #@url = "http://%s/MarmotCollector/api/v1/valid" % obj['collector']
    @pin_code = obj['pin_code']
    @org_env = obj['org_env']
  end

  def set_monit_intervals(obj)
    @monit_intervals = obj
  end

  def pop_metrics
    @metrics_lock.lock
    rlt = @metrics_list.pop
    if !rlt.nil?
      @logger.info "pop one metrics to handle"
    end
    @metrics_lock.unlock

    return rlt
  end
end