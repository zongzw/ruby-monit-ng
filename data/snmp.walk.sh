#!/bin/bash
snmpwalk -c monit_sw -v 2c 10.20.2.$1 $2  2> /dev/null