require 'yaml'
require 'erb'

yml = ERB.new(File.read(ARGV[0])).result

puts yml