require 'net/scp'
require_relative '../get/get'

class ScpGet < Get
  def deal(arg)
    @logger.info "#{self.class.name} start to deal ..."
    Net::SCP.start(@option[:ip_address], @option[:username],
                   @option[:options]) do |scp|
      arg.each do |item|
        data = scp.download!(item)
        yield data
      end
    end
  end
end
