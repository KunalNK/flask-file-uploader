#!/bin/bash
USERLIST=$(cat userlist | cut -d ',' -f1,2 | tr ',' ':')
# //running loop  to add users
for LIST in $USERLIST
do
USER=$(echo $LIST| cut -d':' -f 1)
       echo $USER
       echo "$USER:admin123" | sudo chpasswd
done

