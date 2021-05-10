require_relative '../lib/agents/procstats/proc_stat'

options = {
    :ipaddress => '172.17.0.37',
    :basetarget => 'procstats.yfboshcli',
    :username => 'monitor',
    :password => 'M0nitor00@ibm',
    :interval => 20,
    :pin_code => 'xyz',
    :org_env => 'bmxcn.allenvs',
    :name => 'worker',
    :matches => ['java', 'monitor', 'worker-args']
}


process = ProcStat.new(options)
process.work

puts process.migrate

options = {
    :ipaddress => '172.17.0.37',
    :basetarget => 'procstats.yfboshcli',
    :username => 'monitor',
    :password => 'M0nitor00@ibm',
    :interval => 20,
    :pin_code => 'xyz',
    :org_env => 'bmxcn.allenvs',
    :name => 'worker',
    :matches => ['java', 'monitssor', 'worker-args']
}


process = ProcStat.new(options)
process.work

puts process.migrate

