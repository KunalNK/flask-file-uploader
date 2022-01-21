#!/bin/bash
# USERLIST=$(cat /tmp/userdata | tr 'A-Z' 'a-z')
# for USER in $USERLIST
# do 
sudo useradd $USER
sudo echo "$USER:$USER_PASS" | sudo chpasswd 
echo " $USER user is added "
