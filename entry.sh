#!/bin/bash

addgroup sftp-test 
adduser --disabled-password --gecos '' sftpuser
mkdir -p /var/sftp/
mkdir -p /var/sftp/sftpdata
chown root:root /var/sftp
chmod 755 /var/sftp
chown sftpuser:sftpuser /var/sftp/sftpdata
service ssh restart

#pip3 install -r requirements.txt
/usr/bin/python3 app.py                  