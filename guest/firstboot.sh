#!/bin/bash
#
# firstboot.sh - Run first setup commands inside the guest system
#
# Author: Lord Kator <lordkator@swgemu.com>
#
# Created: Wed Dec 23 19:14:02 EST 2015
#

pushd $(dirname ${BASH_SOURCE[0]}) > /dev/null
export ME=$(pwd -P)'/'$(basename ${BASH_SOURCE[0]})
popd > /dev/null

(
    msg() {
	local hd="+-"$(echo "$1"|sed 's/./-/g')"-+"
	echo -e "$hd\n| $1 |\n$hd"
    }

    msg "START $ME (git: "$(git describe --always)" md5:"$(md5sum $ME)")"

    msg "Unpack Tarballs"

    for i in $(dirname $ME)'/tarballs/'*
    do
	msg "unpack $i"
	(umask 0;cd ~vagrant;tar xpvf $i)
    done

    msg "Cusomize system"

    usermod -c "vagrant" vagrant

    msg "Update Packages"

    # Add Googles's chrome repo to sources
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list

    # Make sure we don't prompt with confusing things
    unset UCF_FORCE_CONFFOLD
    export UCF_FORCE_CONFFNEW=YES
    ucf --purge /boot/grub/menu.lst

    export DEBIAN_FRONTEND=noninteractive

    # Get latest repo locations
    apt-get update

    # Upgrade whatever we can
    apt-get -y -o Dpkg::Options::="--force-confnew" dist-upgrade

    msg "Install Base Packages"

    apt-get -y install dkms build-essential linux-headers-$(uname -r) xfce4 xfce4-goodies lightdm eclipse google-chrome-stable

    apt-get -y autoremove

    msg "Apply Patches"

    for i in $(dirname ${BASH_SOURCE[0]})'/patches/'*
    do
	msg "Apply patch $i"
	(cd /;patch -p0 -Nft) < "$i"
    done

) 2>&1 | logger -i -t firstboot -s 2>&1

logger -i -t firstboot -s "** $0 COMPLETE AFTER $SECONDS SECOND(S)"

exit 0