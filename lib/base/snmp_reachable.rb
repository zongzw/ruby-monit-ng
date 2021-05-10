require_relative 'get/snmpget'

class SnmpReachable
  attr_reader :result, :option
  def initialize(option)
    @option = option
    check_option
    @snmpget = SnmpGet.new(@option)
    @testoids = '1.3.6.1.2.1.1.3.0' # sysUpTime
    @result = {}
  end

  def check_option
    missing_arg = []
    [:ip_address, :community, :snmpport].each do |opt|
      if @option[opt].nil?
        missing_arg << opt
      end
    end

    if ! missing_arg.empty?
      raise ArgumentError, "Missing arguments: #{missing_arg}"
    end
  end

  def work
    @result = {
        :option => @option
    }
    begin
      @snmpget.deal([@testoids]) do |vb|
        @result[:status] = 0
        @result[:details] = vb.value.to_s
        @result[:exception] = ''
      end
    rescue => e
      @result[:status] = 1
      @result[:details] = "#{e.message}"
      @result[:exception] = "#{e.backtrace}"
    end
  end
end