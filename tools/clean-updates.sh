#/usr/bin/sudo /bin/bash
set -x ;

name=$(date +%s)
mv /lib/modules/$(uname -r)/updates /tmp/$name

depmod
