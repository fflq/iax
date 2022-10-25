#/usr/bin/sudo /bin/bash
set -x ;

name=$(date +%s)
mv /lib/modules/5.15.0-48-generic/updates /tmp/$name

depmod

