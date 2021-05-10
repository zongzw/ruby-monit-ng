require 'socket'
require_relative '../get/get'

class TcpGet < Get
  def initialize(option)
    super
    @option[:tcp_port] = 25777 if @option[:tcp_port].nil?
  end

  def deal()
    @logger.info "#{self.class.name} start to deal ..."
    server = TCPServer.new(@option[:tcp_port])
    Thread.new do
      Thread.current['name'] = "QradarAlertServer"
      while (connection = server.accept)
        Thread.new(connection) do |conn|
          port, host = conn.peeraddr[1,2]
          @logger.info "#{host}:#{port} is connected."
          begin
            loop do
              data = conn.readline
              @logger.info "#{host} says: #{data}"
              yield "#{host},#{data}"
            end
          rescue EOFError
            conn.close
          end
        end
      end
    end
  end
end
