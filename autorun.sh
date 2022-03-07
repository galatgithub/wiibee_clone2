#! /bin/bash

# Bluetooth MAC, use: hcitool scan, or: python wiiboard.py
# Wiiboards="7:bleu/rouge 8: ?? 9:?? 10:??
BTADDR="00:25:A0:3F:11:3A"
# Bluetooth relays addresses
#BTRLADDR="85:58:0E:16:73:EF"

# Connexion cle 3G
# fix Huawei E3135 recognized as CDROM [sr0]
lsusb | grep 12d1:1f01 && sudo usb_modeswitch -v 0x12d1 -p 0x1f01 -M "55534243123456780000000000000a11062000000000000100000000000000"
# run DHCP client to get an IP
ifconfig -a | grep eth1 -A1 | grep inet || sudo dhclient eth1
sleep 10
lsusb | grep 12d1:1f01 && sudo usb_modeswitch -v 0x12d1 -p 0x1f01 -M "55534243123456780000000000000a11062000000000000100000000000000"
# run DHCP client to get an IP
ifconfig -a | grep eth1 -A1 | grep inet || sudo dhclient eth1
sleep 10

#sleep 12 # FIXME "wait" for dhcpd timeout
# if BT failed: sudo systemctl status hciuart.service
hciconfig hci0 || hciattach /dev/serial1 bcm43xx 921600 noflow -
# try /dev/ttyAMA0 or /dev/ttyS0 ?
# try to install raspberrypi-sys-mods
# try apt-get install --reinstall pi-bluetooth
# try rpi-update ?

# try remove miniuart from /boot/config added by wittyPi install ?
# https://www.raspberrypi.org/forums/viewtopic.php?f=28&t=141195
d0=$(date +%s)
until hciconfig hci0 up; do
    systemctl restart hciuart
    if [ $(($(date +%s) - d0)) -gt 20 ]; then
        echo "failed to bring up HCI, rebooting"
        /sbin/reboot
    fi
    sleep 1
done

logger "Simulate press red sync button on the Wii Board"

# Switch on bluetooth relay

######## SINGLE WIIBOARD ###############################################
##hcitool scan
##echo -ne "scan on" | bluetoothctl
##echo -ne "scan off" | bluetoothctl
##echo -ne "agent on" | bluetoothctl
##echo -ne "trust $BTRLADDR" | bluetoothctl
##echo -ne "pair $BTRLADDR" | bluetoothctl
#sudo rfcomm bind 0 $BTRLADDR
#sudo chmod o+rw /dev/rfcomm0
##ls -l /dev/rfcomm0
#echo -ne "\xA0\x01\x01\xA2" > /dev/rfcomm0 & pidbt=$!
#sleep 5
#kill $pidbt 2>/dev/null
#echo -ne "\xA0\x01\x00\xA1" > /dev/rfcomm0 & pidbt=$!
#sleep 5
#kill $pidbt 2>/dev/null
#########################################################################

######## MULTIPLE WIIBOARDs #############################################

# Detection des relais

##results=$(hcitool scan --numrsp=100)
#results=$(hcitool -i hci0 scan | grep "JDY-30") 
##echo $results
#sleep 20
#sudo systemctl restart bluetooth

nb_wiiboard=$(echo "$BTADDR" | wc -w)
nb_counted=0
try=0
until [ $nb_counted -eq $nb_wiiboard -o $try -eq 10 ]; do
    ((try++))
    results=$(hcitool -i hci0 scan | grep "JDY-30") 
    sleep 1
    nb_counted=$(echo $results | grep -o "JDY-30" | wc -l)
    echo $nb_counted
    [ $nb_counted -ne $nb_wiiboard ] && { echo "restart BT"; sudo systemctl restart bluetooth; sleep 10; }
done

if [ $try -eq 10 ]; then
    echo "Problems : 10 attempts to restart bluetooth without response from all wiiboards, check wiiboards alimentation" | mail -s "Wiibee_clone1 : Problem with wiiboard" guilhem.a@free.fr
fi

read -a strarr <<< "$results"

j=1
for i in $results; do
	if [ $((j++%2)) -eq 0 ]
	then
	  NAME+=("$i")
	else
	  MAC+=("$i")
	fi
done

BTRLADDR=""
j=0
for i in "${NAME[@]}"; do
	if [[ "$i" == *JDY-30* ]]
	then
	  BTRLADDR="$BTRLADDR ${MAC[$j]}"
	fi
	((j++))
done
BTRLADDR=${BTRLADDR:1}

echo "Relais detectes=${BTRLADDR[@]}"

# Switch on/off des relais

N=0
LOGFILE=""
for nbtrl in $BTRLADDR; do
#    echo $nbtrl
    FILE="/dev/rfcomm${N}"
    [ -f "$FILE" ] && { echo $(ls $FILE); } 
    [ ! -f "$FILE" ] && { echo "$FILE does not exist."; sudo rfcomm bind $N $nbtrl; sudo chmod o+rw /dev/rfcomm$N; }
    LOGFILE="$LOGFILE /dev/rfcomm$N"
    ((N++)) 
done

LOGFILE=${LOGFILE:1}
#echo "LOGFILE = ${LOGFILE[@]}"

open="\xA0\x01\x01\xA2"
for i in $LOGFILE; do
    echo "open $i"
    echo -e $open > "$i" & pidbt=$! &
done
sleep 5
kill $pidbt 2>/dev/null

close="\xA0\x01\x00\xA1"
for i in $LOGFILE; do
    echo "close $i"
    echo -e $close > "$i" & pidbt=$! &
done
sleep 5
kill $pidbt 2>/dev/null

((N--))
for i in `seq 0 $N`; do
    sudo rfcomm release $i
done

#########################################################################

logger "Start listening to the mass measurements"
# replace python by python3
python3 autorun.py $BTADDR >> wiibee.txt
logger "Stopped listening"
python txt2js.py wiibee < wiibee.txt > wiibee.js
python txt2js.py wiibee_battery < wiibee_battery.txt > wiibee_battery.js

# send alert  if one of the wb < 4.5 volts
flag_lowbat=($(awk -F " " 'END { for (i=2; i<=NF; i++) { print ($i<4.5) } }' wiibee_battery.txt))
arr=($BTADDR)
j=0
for i in ${flag_lowbat[@]}; do
    if [ $i -gt 0 ]
    then
        echo "Wiiboard ${arr[$j]} has low battery" | mail "Wiibee_clone2 : Problem with wiiboard" guilhem.a@free.fr
    fi
    ((j++))
done

#cp ~/wittypi/schedule.log /mnt/bee1/wiibee/

### git to github ##########################"

######## old
#git commit wiibee*.js -m"[data] $(date -Is)"
#git commit autorun.log -m"[data] $(date -Is)"
##git commit schedule.log -m"[data] $(date -Is)"
##git push origin master 2>A || cat A | mail -s "GIT a merdé sur Wiibee" guilhem.a@free.fr
#git push origin master 2>A
########

GIT=`which git`
REPO_DIR=/mnt/bee1/wiibee/
cd ${REPO_DIR}
${GIT} commit wiibee*.js wb_temperatures.txt autorun.log -m "[data] $(date -Is)"
${GIT} push origin master &>A
#${GIT} push git@github.com:galatgithub/wiibee_clone1.git master 2>A

#echo $WIIBEE_SHUTDOWN

[ -z "$WIIBEE_SHUTDOWN" ] && exit 0
logger "Shutdown WittyPi"
# shutdown Raspberry Pi by pulling down GPIO-4
gpio -g mode 4 out
gpio -g write 4 0  # optional
logger "Shutdown Raspberry"
shutdown -h now # in case WittyPi did not shutdown
