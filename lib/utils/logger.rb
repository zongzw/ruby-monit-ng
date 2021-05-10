require_relative "../utils/constant"

require 'singleton'
require 'logger'

class MultiIO
  def initialize(*targets)
    @targets = targets
  end

  def write(*args)
    @targets.each {|t| t.write(*args)}
  end

  def close
    @targets.each(&:close)
  end
end

class MonitLogger
  include Singleton

  attr_reader :logger
  def initialize
    @logger = Logger.new(File.join(Constant.get_logs_folder, "monit-ng.log"), shift_age = 7, shift_size = 1048576*128)
    #@logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG

    # log to both stdout and file
    # log_file = File.open(File.join(Constant.get_logs_folder, "monit-fg.log"), "a")
    # @logger = Logger.new MultiIO.new(STDOUT, log_file)
    # @logger.level = Logger::DEBUG
  end

end

class MyLogger < Logger

  @@DEBUG = false

  def initialize(logdev, shift_age = 7, shift_size = 1048576*128)
    super
    @logger = Logger.new(logdev, shift_age, shift_size)
  end

  def debug(program=nil, &block)
    @logger.debug(program, &block)
    puts "#{program}" if @@DEBUG
  end

  def error(program=nil, &block)
    @logger.error(program, &block)
    puts "#{program}" if @@DEBUG
  end

  def warn(program=nil, &block)
    @logger.warn(program, &block)
    puts "#{program}" if @@DEBUG
  end

  def info(program=nil, &block)
    @logger.info(program, &block)
    puts "#{program}" if @@DEBUG
  end

  def fatal(program=nil, &block)
    @logger.fatal(program, &block)
    puts "#{program}" if @@DEBUG
  end

  def unknown(program=nil, &block)
    @logger.unknown(program, &block)
    puts "#{program}" if @@DEBUG
  end

end
