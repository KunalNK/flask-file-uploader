#!/bin/bash
adduser $SFTP_USERS
echo '$SFTP_USERS:$SFTP_USERS_PASS' | sudo chpasswd