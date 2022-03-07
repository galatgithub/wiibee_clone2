WiiBee
======

Manage beehives with RaspberryPi 3, Wii Fit Balance Board, and a WittyPi.

* http://www.uugear.com/product/wittypi2/
* http://www.uugear.com/portfolio/use-witty-pi-2-to-build-solar-powered-time-lapse-camera/
* https://www.leboncoin.fr/consoles_jeux_video/offres?q=wii+fit&pe=3

*[NOTE]* The **shutdown** command is located on the USB autorun script,
this way if you want to use the Raspberry, you can simply remove the USB drive,
you will have 5 minutes to login and disable schedule script with:
`sudo /home/pi/wittyPi/wittyPi.sh`


INSTALL
-------

First, install WittyPi2, see: http://www.uugear.com/product/wittypi2
```
cd; wget http://www.uugear.com/repo/WittyPi2/installWittyPi.sh
sudo sh installWittyPi.sh
```

Then install wiibee (plug an empty USB stick in your Raspberry)
```
cd; wget http://pierriko.com/wiibee/install.sh
sudo sh install.sh
```

Edit `/mnt/bee1/wiibee/autorun.sh`, add the Bluetooth address of each Wii Fit
balance board and the GPIO PIN number of each relay.

You can get the Bluetooth MAC address using `hcitool scan` or
`python /mnt/bee1/wiibee/wiiboard.py` after pressing the red sync button.

Electric wiring coming soon.

For GitHub integration, fork the wiibee repo, add a ssh key, edit the remote in
`/mnt/bee1/wiibee`, and setup GitHub pages:
* https://help.github.com/articles/generating-an-ssh-key/
* https://help.github.com/articles/configuring-a-publishing-source-for-github-pages/

TODO
----

Studdy the Wii Fit Balance Board electric wiring,
find how can we read mass directly from the strain gauges.

* https://www.ifixit.com/Guide/Disassembling+Wii+Balance+Board/6474#s27965
* https://www.ifixit.com/Guide/Wii+Balance+Board+Frame+Replacement/30899
* https://www.raspberrypi.org/documentation/usage/gpio-plus-and-raspi2/

Display data with https://github.com/firehol/netdata


STATS
-----

A data row contains: `time cpu_temp temp mass*`, example:
`1474272540.431 39.50 10.00 20.00 21.00 22.00 23.00`, a row contains 51 bytes
for 4 beehives (75 for 8).

If we do 5 measurements per boot and boot every hour, this means:
```
51 * 5 * 24 = 6120 # bytes per day
6120 * 30 / 1024 = 179 # KB per month
```

A Wii Fit balance power consumtion is around 160mW.

| mode \\ voltage |  6V  |  5V  |
| --------------- | ---- | ---- |
|    stream       | 27mA | 32mA |
|    status       | 25mA | 30mA |
# wiibee_clone2
