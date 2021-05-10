require 'snmp'

m = SNMP::TrapListener.new(:Host => '9.112.153.232', :Port => 1062, :Community => 'monit_fg') do |manager|
  manager.on_trap_default { |trap| p "default: #{trap}" }
  manager.on_trap_v2c { |trap| p "2c: #{trap}" }
end
m.join