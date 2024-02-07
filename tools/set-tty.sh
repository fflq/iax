#!/usr/bin/sudo /bin/bash

echo "* run $0"
systemctl enable sshd
systemctl enable getty@ttyS0
systemctl enable getty@ttyS1
systemctl start sshd
systemctl start getty@ttyS0
systemctl start getty@ttyS1

#sudo stty -F /dev/ttyS0 ispeed 115200 ospeed 115200
sudo stty -F /dev/ttyS0 115200 
sudo stty -F /dev/ttyS1 115200 
