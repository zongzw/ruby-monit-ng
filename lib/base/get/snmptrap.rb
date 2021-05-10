require 'snmp'
require 'socket'
require_relative 'get'

class SnmpTrap < Get
  @@trapListeners = {}
  @@lock = Mutex.new

  def initialize(option)
    super

    port = (@option[:trapport].nil?) ? 162 : @option[:trapport]
    ip = local_ip('64.32.143.45') # random ip address

    @logger.info("getting local ip ... #{ip}")
    #puts ip

    @@lock.lock
    if @@trapListeners["#{ip}:#{port}"].nil?
      m = SNMP::TrapListener.new(:host => ip,
                                 :port => port,
                                 :community => @option[:community])
      @@trapListeners["#{ip}:#{port}"] = m
    end
    @@lock.unlock

    @listener = @@trapListeners["#{ip}:#{port}"]
  end

  def deal
    @listener.on_trap_default do |trap|
      yield trap
    end
  end

  def local_ip(target)
    orig, Socket.do_not_reverse_lookup = Socket.do_not_reverse_lookup, true  # turn off reverse DNS resolution temporarily

    UDPSocket.open do |s|
      s.connect target, 1
      s.addr.last
    end
  ensure
    Socket.do_not_reverse_lookup = orig
  end
end
