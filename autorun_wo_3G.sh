#! /bin/bash

# Relay PIN, see: http://pinout.xyz/pinout/wiringpi
GPIOS="2 4 5 6" # http://pinout.xyz/pinout/pin16_gpio23
# Bluetooth MAC, use: hcitool scan, or: python wiiboard.py
BTADDR="00:1e:35:fd:11:fc 00:22:4c:6e:12:6c 00:1e:35:ff:b0:04 00:23:31:84:7E:4C"

# fix Huawei E3135 recognized as CDROM [sr0]
# lsusb | grep 12d1:1f01 && sudo usb_modeswitch -v 0x12d1 -p 0x1f01 -M "55534243123456780000000000000a11062000000000000100000000000000"
# run DHCP client to get an IP
# ifconfig -a | grep eth1 -A1 | grep inet || sudo dhclient eth1

#sleep 12 # FIXME "wait" for dhcpd timeout
# if BT failed: sudo systemctl status hciuart.service
# hciconfig hci0 || hciattach /dev/serial1 bcm43xx 921600 noflow -
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
# http://wiringpi.com/the-gpio-utility/
for gpio in $GPIOS; do
    sudo gpio mode  $gpio out
    sudo gpio write $gpio 0
    sudo gpio write $gpio 1
done

logger "Start listenning to the mass measurements"
python autorun.py $BTADDR >> wiibee.txt
logger "Stoped listenning"
python txt2js.py wiibee < wiibee.txt > wiibee.js
# git commit wiibee.js -m"[data] $(date -Is)"
# git push origin master

# obexftp -b A0:CB:FD:F7:80:F1 -v -p wiibee.js
# cp ~/wittyPi/wittyPi.log /mnt/bee1/

[ -z "$WIIBEE_SHUTDOWN" ] && exit 0
logger "Shutdown WittyPi"
# shutdown Raspberry Pi by pulling down GPIO-4
gpio -g mode 4 out
gpio -g write 4 0  # optional
logger "Shutdown Raspberry"
shutdown -h now # in case WittyPi did not shutdown
