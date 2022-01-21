FROM ubuntu:20.04
 
WORKDIR /app

COPY . /app

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install tzdata

RUN apt-get install python3-pip -y

RUN pip3 install --no-cache-dir -r requirements.txt

# RUN apt-get update \
#  && apt-get install -y --no-install-recommends \
#     nano \
#     sudo \
#     openssh-server
 
COPY ssh_config /etc/ssh/ssh_config
COPY sshd_config /etc/ssh/sshd_config

# RUN addgroup sftp-test 
# RUN adduser --disabled-password --gecos '' sftpuser
# ARG USER=sftp-denvr
# ARG UID=1000
# ARG GID=1000
# ARG PW=docker
# RUN useradd -m ${USER} --uid=${UID} && echo "${USER}:${PW}" | \
#     chpasswd

# RUN  mkdir -p /var/sftp/
# RUN  mkdir -p /var/sftp/sftpdata
# RUN chown root:root /var/sftp
# RUN chmod 755 /var/sftp
# RUN chown sftp-denvr:sftp-denvr /var/sftp/sftpdata
# RUN service ssh restart

EXPOSE 5000 80 5443 22

ENV UPLOAD_FOLDER=data

ENTRYPOINT ["/app/entry.sh"]
# CMD ["python3","app.py"]
 
