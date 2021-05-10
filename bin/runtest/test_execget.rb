require_relative '../lib/base/get/execget'

cmd = LocalCmdGet.new(nil)

cmd.deal(['dc']) do |sin, sout, serr|
  sin.puts('5')
  sin.puts('5')
  sin.puts('+')
  sin.puts('p')
  puts sout.gets()
end

cmd.deal(['asfawe']) do |sin, sout, serr|
  puts serr.gets
  puts sout.gets
end

cmd.deal(['dc']) do |sin, sout, serr|
  sin.puts('sasdfsafsdfaa')
  sin.puts('p')
  puts serr.gets()
end