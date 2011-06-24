#!/usr/bin/env bash

REPO="https://github.com/cskau/EP121-fixes-for-Ubuntu-11.04-Natty/raw/master/"
BINDIR="$HOME/bin/ep121/"
INIT="/etc/gdm/Init/"
GDM="/var/lib/gdm/"
HOMDIR=$HOME

## Fix Bluetooth applet/service
# note: on board bluetooth seems to still lacks kernel driver .. or something ..
read -p "Replace bluez 4.91 with 4.60 (y/n)? " A
if [ "$A" = y ]; then
    # replace buggy bluez 4.91 with 4.60
    sudo apt-get purge bluez
    wget http://archive.ubuntu.com/ubuntu/pool/main/b/bluez/bluez_4.60-0ubuntu8_amd64.deb
    sudo dpkg -i ./bluez_4.60-0ubuntu8_amd64.deb
    # reinstall applet
    sudo apt-get install gnome-bluetooth
    # prevent bluez from upgrading
    echo "bluez hold" | sudo dpkg --set-selections
fi

## Choose which onscreen keyboard user requests.
read -p "Which onscreen keyboard would you like.  Florence or Onboard (f/o)?" B
if [ "$B" = f ]; then
    # Installs Florence and creates softlink to driver.
    touch ${BINDIR}Default
    sudo apt-get install florence
    sudo cp ${BINDIR}Default ${INIT}Default |sed ' /^exit/ i\exec florence &' ${INIT}Default > ${BINDIR}Default
    sudo cp ${BINDIR}Default ${INIT}Default |sed ' /^exec florence &/ i\exec python ${GDM}ep121_drv &' ${INIT}Default > ${BINDIR}Default
    rm ${BINDIR}Default
    sudo ln -s ${HOMDIR}/bin/ep121/ep121_drv.py ${GDM}
    echo "Florence will not start before you log in."
else
    # Creates softlink to driver and loads onboard pre-login.
    touch ${BINDIR}Default
    echo "Onboard comes with Ubuntu.  No installation needed.  Writing boot script..."
    sudo cp ${BINDIR}Default ${INIT}Default |sed ' /^exit/ i\exec onboard &' ${INIT}Default > ${BINDIR}Default
    sudo cp ${BINDIR}Default ${INIT}Default |sed ' /^exec onboard &/ i\exec python ${GDM}ep121_drv &' ${INIT}Default > ${BINDIR}Default
    rm ${BINDIR}Default
    sudo ln -s ${HOMDIR}/bin/ep121/ep121_drv.py ${GDM}
    echo "Onboard will now start before you log in."
fi

## Fix touch screen

# overrule evdev driver for the touch screen - replace with ignore rule
wget --no-check-certificate ${REPO}09-ep121.conf
sudo cp -i ./09-ep121.conf /usr/share/X11/xorg.conf.d/
# install "driver" in user's bin folder (should already be in PATH)
wget --no-check-certificate ${REPO}ep121_drv.py
sudo cp -i ./ep121_drv.py ${BINDIR}
wget --no-check-certificate ${REPO}_xautpy.so
sudo cp -i ./_xautpy.so ${BINDIR}
wget --no-check-certificate ${REPO}xaut.py
sudo cp -i ./xaut.py ${BINDIR}
# makes driver executable
chmod +x ${BINDIR}/ep121_drv.py
# grant the driver read access to input devices
# TODO: this should be narrowed down to only the two files we actually use
if [ -z "`grep \"SUBSYSTEM==\\\"input\\\", MODE=\\\"644\\\"\" \"/etc/udev/rules.d/85-ep121.rules\"`" ]; then
    echo "Adding read access rule to /etc/udev/rules.d/85-ep121.rules"
    echo "SUBSYSTEM==\"input\", MODE=\"644\"" | sudo tee -a /etc/udev/rules.d/85-ep121.rules
fi
# make sure the driver runs at login
if [ -e "$HOME/.bash_login" ]; then
    if [ -z "`grep \"ep121_drv.py &\" \"$HOME/.bash_login\"`" ]; then
        echo "Adding ep121_drv.py to $HOME/.bash_login"
        echo "ep121_drv.py &" >> $HOME/.bash_login
    fi
elif [ -e "$HOME/.bash_profile" ]; then
    if [ -z "`grep \"ep121_drv.py &\" \"$HOME/.bash_profile\"`" ]; then
        echo "Adding ep121_drv.py to $HOME/.bash_profile"
        echo "ep121_drv.py &" >> $HOME/.bash_profile
    fi
elif [ -e "$HOME/.profile" ]; then
    if [ -z "`grep \"ep121_drv.py &\" \"$HOME/.profile\"`" ]; then
        echo "Adding ep121_drv.py to $HOME/.profile"
        echo "ep121_drv.py &" >> $HOME/.profile
    fi
else
    echo "WARNING: Could not find login or profile script."
    echo "Adding .profile to home folder. Please make sure this is the right thing to do."
    if [ -z "`grep \"ep121_drv.py &\" \"$HOME/.profile\"`" ]; then
        echo "ep121_drv.py &" >> $HOME/.profile
    fi
fi

## Add hot keys
#
# We might want to fiddle with this at some point
# would be nice to get proper keybindings for them

# Rotation
#echo "0xF5 prog1" >> /lib/udev/keymaps/asus
# Screen
#echo "0xF6 f21 # Toggle touchpad" >> /lib/udev/keymaps/asus
# Keyboard
#echo "0xF7 bluetooth" >> /lib/udev/keymaps/asus
