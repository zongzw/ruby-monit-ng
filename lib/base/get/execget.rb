
require 'open3'
require_relative 'get'

class LocalCmdGet < Get

  def deal(arg)
    arg.each do |cmd|
      stdin, stdout, stderr = Open3.popen3(cmd)
      yield stdin, stdout, stderr
    end
  end
end