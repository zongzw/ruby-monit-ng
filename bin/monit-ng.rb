require_relative '../lib/utils/config'
require_relative '../lib/utils/constant'
require_relative '../lib/server/agent-engine'
require_relative '../lib/utils/logger'
require 'optparse'
require 'pathname'

stop = false
logger = MonitLogger.instance.logger

[:INT, :EXIT, :HUP, :TERM].each { |sig|
  Signal.trap(sig) {
    stop = true
    puts "received stop signal: #{sig}. will stop.."
  }
}

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"
  opts.on("-f CONFIGFILE", "--config CONFIGFILE", "config file for procstats monitoring") do |v|
    options[:config] = v
    logger.info("config file: %s" % v)
  end
  opts.on("-l LOGDIR", "--logdir LOGDIR", "log directory where to puts the logs.") do |v|
    options[:logdir] = v
    logger.info("log directory: #{options[:logdir]}")
  end
  opts.on("-m MODULE", "--module MODULE", "the module to monit, valid module name: [fortigate switch procstats ntp]") do |v|
    options[:module] = v
    logger.info("modules to monit: #{options[:module]}")
  end
end.parse!

if ! ARGV.empty?
  logger.error("unrecognized parameters: #{ARGV}")
  exit(1)
end

options[:logdir] = Pathname.new(__FILE__).realpath.dirname.to_s + "/../logs" if options[:logdir].nil?

YmlConfig.init(options[:config])
cfg = YmlConfig.get_config
logger.info("monit procstats starts with configuration: #{cfg}")
server = AgentsServer.instance

begin
  # noinspection RubyInterpreterInspection
  server.set_marmot_info(cfg['marmot_info'])
  server.set_monit_intervals(cfg['monit_intervals'])

  cfg['monit_objects'].each do |obj|
    if obj['type'].nil?
      logger.error("unrecognized monitor objects: nil")
      next
    end

    next if options[:module] != obj['type']

    pth = Pathname.new(__FILE__).realpath
    regfile = File.dirname(pth) + "/../lib/server/registrars/#{obj['type']}.rb"
    logger.info("register file: #{regfile}")
    raise RuntimeError, "not such file to require: #{regfile}" if ! File.exist? regfile
    require_relative "#{regfile[0..-4]}"

    classname = obj['type'].capitalize
    methodname = "register_agents"

    obj[:logdir] = options[:logdir]
    k = Kernel.const_get(classname).new(obj)
    raise RuntimeError, "class #{classname} doesn't implement #{methodname}" if ! k.respond_to? methodname
    k.send(methodname)

  end
rescue => e
  logger.fatal("configuration fault, check the configuration file: #{e.message}, %s" % e.backtrace.join("\n"))
  exit 2
end

server.launch_post
server.launch_get

while (!stop) do
  Thread.current['name'] = "main"
  logger.debug("---------- the working thread info: ")
  Thread.list.each { |thr|
    logger.debug("|-#{thr['name']}-| ")
  }
  30.times do
    sleep 1 if !stop
  end
end
