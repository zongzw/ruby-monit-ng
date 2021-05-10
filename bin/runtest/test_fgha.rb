
require 'snmp'
require_relative '../lib/agents/fortigate/fg_ha'

ha_agent = FgHa.new(:ip_address => '9.112.242.20',
                    :community => "monit_fg",
                    :serial_number => 'asdf',
                    :interval => 20,
                    :basetarget => 'fg',
                    :pin_code => 'sdf',
                    :cluster_name => 'sdf',
                    :org_env => 'ibm.allenvs')

ha_agent.work
puts ha_agent.migrate
ha_agent.work
puts ha_agent.migrate

exit 0

# oids: [oid1..oidn]
def get(host, community, oids)
  SNMP::Manager.open(:Host => host, :Version => :SNMPv2c,
                     :Community => community) do |manager|
    response = manager.get(oids)
    response.each_varbind do |varbind|
      yield varbind
    end
  end
end

# oids: [oid1..oidn, 0, 10]
def bulk(host, community, oids)
  non_repeaters = oids.pop
  max_repetitions = oids.pop
  SNMP::Manager.open(:Host => host, :Version => :SNMPv2c,
                     :Community => community) do |manager|
    response = manager.get_bulk(non_repeaters, max_repetitions, oids)
    response.each_varbind do |varbind|
      yield varbind
    end
  end
end

host = '9.112.242.20'
host = '10.20.2.41'
community = 'monit_fg'
fgHaSystemMode = ['1.3.6.1.4.1.12356.101.13.1.1']

get(host, community, fgHaSystemMode) do |varbind|
  puts varbind
end

puts "========="
fgHaStatsprefix = '1.3.6.1.4.1.12356.101.13.2.1.1'
fgHastats = []
Array(1..16).each do |n|
  fgHastats << "#{fgHaStatsprefix}.#{n}"
end

puts fgHastats

bulk(host, community, fgHastats + [200, 1]) do |varbind|
  puts varbind
end

