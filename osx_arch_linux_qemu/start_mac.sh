systemctl start firewalld
echo -e '\x1B[01;93m[*] firewalld service start!'
systemctl start libvirtd
echo -e '\x1B[01;93m[*] libvirtd deamon start!'

ip tuntap add dev tap0 mode tap > /dev/null 2>&1
ip link set tap0 up promisc on > /dev/null 2>&1

echo -e '\033[0;32m[+] tap0 interface is ready'

if ! (/usr/bin/ethtool virbr0 | grep -q "Link detected: no") > /dev/null 2>&1 ; then
	echo -e '\x1B[01;93m[!] WAITING FOR "virbr0" ...'
fi

while :
 do
  if (/usr/bin/ethtool virbr0 | grep -q "Link detected: no") > /dev/null 2>&1 ; then
   echo -e '\033[0;32m[+] virbr0 interface is ready.'
   brctl addif virbr0 tap0  > /dev/null 2>&1
   echo -e '\033[0;32m[+] virbr0 bridge success!'
   
   break
  fi
done 

/usr/bin/qemu-system-x86_64 -enable-kvm -m 8192 -cpu core2duo,kvm=off -machine pc-q35-2.4 -smp 4,cores=2 -usb -device usb-kbd -device usb-mouse -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -kernel "/media/VMS-HDD/OSX/enoch_rev2839_boot" -smbios type=2 -daemonize -hda "/media/VMS-HDD/OSX/OSX-Capitan.qcow2" -netdev tap,id=net0,ifname=tap0,script=no,downscript=no -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27  > /dev/null 2>&1
echo -e '\033[0;32m[+] Mac Start Success!'
