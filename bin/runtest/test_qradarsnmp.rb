
port = 8001
iplist = %W(
  172.16.11.11
  172.17.0.130
  172.17.0.38
  172.17.0.73
  172.17.4.26
  172.17.8.35
  172.16.11.14
)

iplist.each do |ip|
  puts ip
  info = `snmpwalk -v 2c -c public #{ip}:8001 .1.3.6.1.2.1.1.3.0`
  puts info
end

halist = {
    '172.16.11.11' => %W(172.16.11.12 172.16.11.13),
    '172.16.11.14' => %W(172.16.11.15 172.16.11.16)
}

#puts "#{iplist}"
#puts halist

oidlist = {
    :ssCpuRawUser => '1.3.6.1.4.1.2021.11.50.0',
    :ssCpuRawNice => '1.3.6.1.4.1.2021.11.51.0',
    :ssCpuRawSystem => '1.3.6.1.4.1.2021.11.52.0',
    :ssCpuRawIdle => '1.3.6.1.4.1.2021.11.53.0',
    :ssCpuRawWait => '1.3.6.1.4.1.2021.11.54.0',
    :ssCpuRawKernel => '1.3.6.1.4.1.2021.11.55.0',
    :ssCpuRawInterrupt => '1.3.6.1.4.1.2021.11.56.0',
    :ssCpuRawSoftIRQ => '1.3.6.1.4.1.2021.11.61.0',
    :ssCpuRawSteal => '1.3.6.1.4.1.2021.11.64.0',
    :ssCpuRawGuest => '1.3.6.1.4.1.2021.11.65.0',
    :ssCpuRawGuestNice => '1.3.6.1.4.1.2021.11.66.0',

    # there's no oid can be used to figure out
    # 1. how many total virtual memory
    # 2. how many total virtual memory are used or free.
    # 3. memBuffer and memCached are memory that just be cached or buffered, not really used.
    # 4. memBuffer and memCached are both referring not only real memory but also virtual memory.

    # The total amount of real/physical memory installed on this host.
    :memTotalReal => '1.3.6.1.4.1.2021.4.5.0',

    # The amount of real/physical memory currently unused or available.
    :memAvailReal => '1.3.6.1.4.1.2021.4.6.0',

    # The total amount of memory free or available for use on this host.
    # This value typically covers both real memory and swap space or virtual memory.
    :memTotalFree => '1.3.6.1.4.1.2021.4.11.0',

    # The total amount of real or virtual memory currently allocated for use as memory buffers.
    # This object will not be implemented on hosts where the
    #      underlying operating system does not explicitly identify
    #      memory as specifically reserved for this purpose.
    :memBuffer => '1.3.6.1.4.1.2021.4.14.0',

    # The total amount of real or virtual memory currently allocated for use as cached memory.
    # This object will not be implemented on hosts where the
    #      underlying operating system does not explicitly identify
    #      memory as specifically reserved for this purpose.
    :memCached => '1.3.6.1.4.1.2021.4.15.0',

    # snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.4.1.2021.4.5.0
    # UCD-SNMP-MIB::memTotalReal.0 = INTEGER: 65572956 kB
    # snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.4.1.2021.4.6.0
    # UCD-SNMP-MIB::memAvailReal.0 = INTEGER: 3671624 kB
    # snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.4.1.2021.4.11.0
    # UCD-SNMP-MIB::memTotalFree.0 = INTEGER: 28837444 kB
    # snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.4.1.2021.4.14.0
    # UCD-SNMP-MIB::memBuffer.0 = INTEGER: 448764 kB
    # snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.4.1.2021.4.15.0
    # UCD-SNMP-MIB::memCached.0 = INTEGER: 36669048 kB
}
# Used memory = memTotalReal + "Total Virtual memory" - memTotalFree - memBuffer - memCached
# Usage = "Used memory"/(memTotalReal + "Total Virtual memory")
usage = 100 * (65572956 + 90738776 - 28837444 - 448764 - 36669048) / (65572956 + 90738776)
#puts usage  57

# snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.2.1.25.2.3.1.3
# HOST-RESOURCES-MIB::hrStorageDescr.1 = STRING: Physical memory
# HOST-RESOURCES-MIB::hrStorageDescr.3 = STRING: Virtual memory
# HOST-RESOURCES-MIB::hrStorageDescr.6 = STRING: Memory buffers
# HOST-RESOURCES-MIB::hrStorageDescr.7 = STRING: Cached memory
# HOST-RESOURCES-MIB::hrStorageDescr.10 = STRING: Swap space
#
# snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.2.1.25.2.3.1.5
# HOST-RESOURCES-MIB::hrStorageSize.1 = INTEGER: 65572956
# HOST-RESOURCES-MIB::hrStorageSize.3 = INTEGER: 90738776
# HOST-RESOURCES-MIB::hrStorageSize.6 = INTEGER: 65572956
# HOST-RESOURCES-MIB::hrStorageSize.7 = INTEGER: 36682872
# HOST-RESOURCES-MIB::hrStorageSize.10 = INTEGER: 25165820
#
# snmpwalk -v 2c -c public 172.16.11.11:8001 1.3.6.1.2.1.25.2.3.1.6
# HOST-RESOURCES-MIB::hrStorageUsed.1 = INTEGER: 61676100
# HOST-RESOURCES-MIB::hrStorageUsed.3 = INTEGER: 61676100
# HOST-RESOURCES-MIB::hrStorageUsed.6 = INTEGER: 448756
# HOST-RESOURCES-MIB::hrStorageUsed.7 = INTEGER: 36683300
# HOST-RESOURCES-MIB::hrStorageUsed.10 = INTEGER: 0

oidslist = {
    :hrStorageDescr => '1.3.6.1.2.1.25.2.3.1.3',
    :hrStorageType => '1.3.6.1.2.1.25.2.3.1.2',
    :hrStorageSize => '1.3.6.1.2.1.25.2.3.1.5',
    :hrStorageUsed => '1.3.6.1.2.1.25.2.3.1.6'
}

