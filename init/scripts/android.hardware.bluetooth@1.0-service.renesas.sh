#!/vendor/bin/sh
for i in $(/vendor/bin/ls "/sys/class/rfkill");
do
	i="/sys/class/rfkill/"$i"/state"
	if test -f $i; then /vendor/bin/chcon u:object_r:sysfs_bluetooth_writable:s0 $i; fi
done
