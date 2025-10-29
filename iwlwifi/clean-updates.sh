#/usr/bin/sudo /bin/bash
#set -x ;

echo "* clean modules updates"

src=/lib/modules/$(uname -r)/updates 
if [ -d $src ]; then
	sudo mv -f $src /tmp/modules-updates-$(date +%s)
fi

sudo depmod

echo "done"

