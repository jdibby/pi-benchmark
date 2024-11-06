#!/bin/bash

TMPFILE=/tmp/benchmarking.tmp
rm -rf $TMPFILE 

### ADDING CAPABILITIES OF BOLD FONTS
BOLD=$(tput bold)
NORMAL=$(tput sgr0)

### MUST BE ROOT / SUDO
WHOAREYOU=$(whoami)
if [ "$WHOAREYOU" != "root" ]; then
   echo "#######################################################################"
   echo "##############${BOLD} YOU MUST BE ROOT OR ELSE SUDO THIS SCRIPT ${NORMAL}##############"
   echo "#######################################################################"
   exit 1
fi

### CHECK FOR RASPBERRY PI
if [ -f /proc/device-tree/model ]; then
    RPIVER=$(grep -a "Raspberry" /proc/device-tree/model | awk '{print $3}')
    if [ ! `which sysbench` ]; then
       apt-get install -y sysbench
    fi
    if [ ! `which hdparm` ]; then
       apt-get install -y hdparm
    fi
    if [ ! `which speedtest-cli` ]; then
       apt-get install -y speedtest-cli
    fi
else
   echo "#######################################################################"
   echo "##############${BOLD} UNSUPPORTED OPERATING SYSTEM ${NORMAL}##############"
   echo "#######################################################################"
   exit 1
fi

clear

# Show current hardware

echo "#######################################################################"
echo "##############${BOLD} CURRENT HARDWARE INFORMATION ${NORMAL}##############"
echo "#######################################################################"
vcgencmd measure_temp
vcgencmd get_config int | grep arm_freq
vcgencmd get_config int | grep core_freq
vcgencmd get_config int | grep sdram_freq
vcgencmd get_config int | grep gpu_freq

echo -e -n "\n" 

echo "#######################################################################"
echo "##############${BOLD} RUNNING CPU BENCHMARK ${NORMAL}##############"
echo "#######################################################################"
sysbench cpu --num-threads=4 --validate=on --cpu-max-prime=5000 run | grep -Ei "total time|min|avg:|max" | tr -s " "
vcgencmd measure_temp

echo -e -n "\n" 

echo "#######################################################################"
echo "##############${BOLD} RUNNING THREADS BENCHMARK ${NORMAL}##############"
echo "#######################################################################"
sysbench threads --num-threads=4 --validate=on --thread-yields=5000 --thread-locks=5 run | grep -Ei "total time|min|avg:|max" | tr -s " "
vcgencmd measure_temp

echo -e -n "\n" 

echo "#######################################################################"
echo "##############${BOLD} RUNNING MEMORY BENCHMARK ${NORMAL}##############"
echo "#######################################################################"
sysbench memory --num-threads=4 --validate=on --memory-block-size=1K --memory-total-size=3G --memory-access-mode=seq run | grep 'Operations\|transferred\|total time:\|min:\|avg:\|max:' | tr -s [:space:]
vcgencmd measure_temp

echo -e -n "\n" 

echo "#######################################################################"
echo "##############${BOLD} RUNNING HARDDRIVE BENCHMARK ${NORMAL}##############"
echo "#######################################################################"
hdparm -t /dev/mmcblk0 | grep Timing
vcgencmd measure_temp

echo -e -n "\n" 

echo "#######################################################################"
echo "##############${BOLD} RUNNING WRITE BENCHMARK ${NORMAL}##############"
echo "#######################################################################"
sync && dd if=/dev/zero of=$TMPFILE bs=1M count=512 conv=fsync 2>&1 | grep -v records
vcgencmd measure_temp

echo -e -n "\n" 

echo "#######################################################################"
echo "##############${BOLD} RUNNING READ BENCHMARK ${NORMAL}##############"
echo "#######################################################################"
echo -e 3 > /proc/sys/vm/drop_caches && sync && dd if=$TMPFILE of=/dev/null bs=1M 2>&1 | grep -v records
vcgencmd measure_temp
rm -rf $TMPFILE

echo -e -n "\n"
