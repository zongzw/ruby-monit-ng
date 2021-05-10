
require_relative '../lib/base/get/snmpget'

oids = {:cpu_usage         => "1.3.6.1.4.1.12356.101.4.1.3.0",     # cpu usage
        :mem_usage         => "1.3.6.1.4.1.12356.101.4.1.4.0",     # mem usage
        :mem_capacity      => "1.3.6.1.4.1.12356.101.4.1.5.0",     # mem capacity
        :disk_used         => "1.3.6.1.4.1.12356.101.4.1.6.0",     # disk used
        :disk_capacity     => "1.3.6.1.4.1.12356.101.4.1.7.0",     # disk capacity
        :low_mem_usage     => "1.3.6.1.4.1.12356.101.4.1.9.0",     # low mem usage
        :low_mem_capacity  => "1.3.6.1.4.1.12356.101.4.1.10.0",    # low mem capacity
}

oids = {:temperature                  => '1.3.6.1.4.1.14179.2.3.1.13',
        :t1                           => '1.3.6.1.4.1.9.9.13.1.3.1.6.1',
        :ciscoTcpMIBTraps             => '1.3.6.1.4.1.9.9.6.2.0',
        :ciscoEnvMonFanStatusIndex    => '1.3.6.1.4.1.9.9.13.1.4.1.1.0',
        :ccmSystemVersion             => '1.3.6.1.4.1.9.9.156.1.5.29.0',
        :sysUptime                    => '1.3.6.1.2.1.1.3.0',
        :ifInOctet                    => '1.3.6.1.2.1.2.2.1.10.0',
        :ifInOctets                    => '1.3.6.1.2.1.2.2.1.10.1',
        :ciscoEnvMonTemperatureThreshold => '1.3.6.1.4.1.9.9.13.1.3.1.4.1',
        :ciscoMemoryPoolUsed          => "1.3.6.1.4.1.9.9.48.1.1.1.5.0",
        :ciscoMemoryPoolUsed          => "1.3.6.1.4.1.9.9.48.1.1.1.5.1",
        :ciscoEnvMonVoltageStatusIndex=> "1.3.6.1.4.1.9.9.13.1.2.1.1.0",
        :ciscoEnvMonVoltageStatusIndex1=> "1.3.6.1.4.1.9.9.13.1.2.1.1.1",
        :ciscoEnvMonVoltageStatusIndex2=> "1.3.6.1.4.1.9.9.13.1.2.1.1.2"
}

ip = "10.20.2.21"
cm = "monit_sw"

get = SnmpGet.new(:ip_address => ip, :community => cm)

get.deal(oids.values) do |varbind|
  puts varbind
end


SNMP::Manager.open(:Host => ip, :Version => :SNMPv2c,
                   :Community => cm) do |manager|
  manager.walk(['1.3.6.1.2.1.2.2.1.1'])  do |index|
         puts "#{index}"
  end
end

# "ciscoEnvMonTemperatureStatusEntry"                "1.3.6.1.4.1.9.9.13.1.3.1"
# "ciscoEnvMonTemperatureStatusIndex"                "1.3.6.1.4.1.9.9.13.1.3.1.1"
# "ciscoEnvMonTemperatureStatusDescr"                "1.3.6.1.4.1.9.9.13.1.3.1.2"
# "ciscoEnvMonTemperatureStatusValue"                "1.3.6.1.4.1.9.9.13.1.3.1.3"
# "ciscoEnvMonTemperatureThreshold"                "1.3.6.1.4.1.9.9.13.1.3.1.4"
# "ciscoEnvMonTemperatureLastShutdown"                "1.3.6.1.4.1.9.9.13.1.3.1.5"
# "ciscoEnvMonTemperatureState"                "1.3.6.1.4.1.9.9.13.1.3.1.6"
# root@886a5f42-634d-4200-a230-33df0df0785d:~# snmpwalk -v 2c -c monit_sw 10.20.2.21 1.3.6.1.4.1.9.9.13.1 2>/dev/null
# iso.3.6.1.4.1.9.9.13.1.1.0 = INTEGER: 13
# iso.3.6.1.4.1.9.9.13.1.3.1.2.1006 = STRING: "SW#1, Sensor#1, GREEN "
# iso.3.6.1.4.1.9.9.13.1.3.1.3.1006 = Gauge32: 32
# iso.3.6.1.4.1.9.9.13.1.3.1.4.1006 = INTEGER: 68
# iso.3.6.1.4.1.9.9.13.1.3.1.5.1006 = INTEGER: 0

# "ciscoMgmt"                "1.3.6.1.4.1.9.9"
# "ciscoMemoryPoolMIB"                "1.3.6.1.4.1.9.9.48"
# "ciscoMemoryPoolObjects"                "1.3.6.1.4.1.9.9.48.1"
# "ciscoMemoryPoolNotifications"                "1.3.6.1.4.1.9.9.48.2"
# "ciscoMemoryPoolConformance"                "1.3.6.1.4.1.9.9.48.3"
# "ciscoMemoryPoolTable"                "1.3.6.1.4.1.9.9.48.1.1"
# "ciscoMemoryPoolUtilizationTable"                "1.3.6.1.4.1.9.9.48.1.2"
# "ciscoMemoryPoolEntry"                "1.3.6.1.4.1.9.9.48.1.1.1"
# "ciscoMemoryPoolType"                "1.3.6.1.4.1.9.9.48.1.1.1.1"
# "ciscoMemoryPoolName"                "1.3.6.1.4.1.9.9.48.1.1.1.2"
# "ciscoMemoryPoolAlternate"                "1.3.6.1.4.1.9.9.48.1.1.1.3"
# "ciscoMemoryPoolValid"                "1.3.6.1.4.1.9.9.48.1.1.1.4"
# "ciscoMemoryPoolUsed"                "1.3.6.1.4.1.9.9.48.1.1.1.5"
# "ciscoMemoryPoolFree"                "1.3.6.1.4.1.9.9.48.1.1.1.6"
# "ciscoMemoryPoolLargestFree"                "1.3.6.1.4.1.9.9.48.1.1.1.7"
# root@886a5f42-634d-4200-a230-33df0df0785d:~# snmpwalk -v 2c -c monit_sw 10.20.2.21 1.3.6.1.4.1.9.9.48 2>/dev/null
# iso.3.6.1.4.1.9.9.48.1.1.1.2.1 = STRING: "Processor"
# iso.3.6.1.4.1.9.9.48.1.1.1.2.2 = STRING: "I/O"
# iso.3.6.1.4.1.9.9.48.1.1.1.2.20 = STRING: "Driver text"
# iso.3.6.1.4.1.9.9.48.1.1.1.3.1 = INTEGER: 0
# iso.3.6.1.4.1.9.9.48.1.1.1.3.2 = INTEGER: 0
# iso.3.6.1.4.1.9.9.48.1.1.1.3.20 = INTEGER: 0
# iso.3.6.1.4.1.9.9.48.1.1.1.4.1 = INTEGER: 1
# iso.3.6.1.4.1.9.9.48.1.1.1.4.2 = INTEGER: 1
# iso.3.6.1.4.1.9.9.48.1.1.1.4.20 = INTEGER: 1
# iso.3.6.1.4.1.9.9.48.1.1.1.5.1 = Gauge32: 45052876
# iso.3.6.1.4.1.9.9.48.1.1.1.5.2 = Gauge32: 12544080
# iso.3.6.1.4.1.9.9.48.1.1.1.5.20 = Gauge32: 748804
# iso.3.6.1.4.1.9.9.48.1.1.1.6.1 = Gauge32: 397812184
# iso.3.6.1.4.1.9.9.48.1.1.1.6.2 = Gauge32: 4233136
# iso.3.6.1.4.1.9.9.48.1.1.1.6.20 = Gauge32: 299772
# iso.3.6.1.4.1.9.9.48.1.1.1.7.1 = Gauge32: 375983312
# iso.3.6.1.4.1.9.9.48.1.1.1.7.2 = Gauge32: 4182348
# iso.3.6.1.4.1.9.9.48.1.1.1.7.20 = Gauge32: 299768
#
# 1.3.6.1.2.1.2.1.0
# 网络接口的数目
# IfNumber
#
# 1.3.6.1.2.1.2.2.1.2
# 网络接口信息描述
# IfDescr

# 1.3.6.1.2.1.2.2.1.10
# 接口收到的字节数
# IfInOctet
#
# 1.3.6.1.2.1.2.2.1.16
# 接口发送的字节数
# IfOutOctet

# 1.3.6.1.2.1.2.2.1.8
# 接口当前操作状态[up|down]
# IfOperStatus

# 获取过去5秒的CPU load (cpu繁忙的百分比)
# snmpwalk -v 2c -c Pub_PCon9-CT 192.168.232.25 1.3.6.1.4.1.9.2.1.56.0
# 获取过去1分钟的CPU load (cpu繁忙的百分比)
# snmpwalk -v 2c -c Pub_PCon9-CT 192.168.232.25 1.3.6.1.4.1.9.2.1.57.0
# 获取过去5分钟的CPU load (cpu繁忙的百分比)
# snmpwalk -v 2c -c Pub_PCon9-CT 192.168.232.25 1.3.6.1.4.1.9.2.1.58.0

# vtpVlanTable 1.3.6.1.4.1.9.9.46.1.3.1
#Object	vtpVlanIfIndex
#OID	1.3.6.1.4.1.9.9.46.1.3.1.1.18
#
# snmpwalk -c public@1 crumpy .1.3.6.1.2.1.31.1.1.1.1
#
# ifMIB.ifMIBObjects.ifXTable.ifXEntry.ifName.1 = VL1
# ifMIB.ifMIBObjects.ifXTable.ifXEntry.ifName.2 = Fa0/1
# ifMIB.ifMIBObjects.ifXTable.ifXEntry.ifName.3 = Fa0/2
# ifMIB.ifMIBObjects.ifXTable.ifXEntry.ifName.4 = Fa0/3