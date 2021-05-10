
obj = {
    'type' => 'fortigate',
    'option1' => 'value1'
}

regfile = "../../lib/server/registrars/#{obj['type']}.rb"
raise RuntimeError, "not such file to require: #{regfile}" if ! File.exist? regfile
require_relative "#{regfile[0..-4]}"
classname = obj['type'].capitalize
methodname = "register_agents"
k = Kernel.const_get(classname).new(obj)
raise RuntimeError, "class #{classname} doesn't implement #{methodname}" if !k.respond_to? methodname
k.send(methodname)
