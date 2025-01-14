#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

userConfPath="/etc/sftp-users.conf"
userConfFinalPath="/var/run/sftp-users.conf"

function printHelp() {
    echo "Add users as command arguments, STDIN or mounted in $userConfPath"
    echo "Syntax: user:pass[:e][:uid[:gid[:dir1[,dir2]...]]] ..."
    echo "Use --readme for more information and examples."
}

function printReadme() {
    cat /README.md
    echo "TIP: Read this in HTML format here: https://github.com/atmoz/sftp"
}

function createUser() {
    IFS=':' read -a param <<< $@
    user="${param[0]}"
    pass="${param[1]}"

    if [ "${param[2]}" == "e" ]; then
        chpasswdOptions="-e"
        uid="${param[3]}"
        gid="${param[4]}"
        dir="${param[5]}"
    else
        uid="${param[2]}"
        gid="${param[3]}"
        dir="${param[4]}"
    fi

    if [ -z "$user" ]; then
        echo "FATAL: You must at least provide a username."
        exit 1
    fi

    if $(cat /etc/passwd | cut -d: -f1 | grep -q "^$user:"); then
        echo "WARNING: User \"$user\" already exists. Skipping."
        return 0
    fi

    useraddOptions="--no-user-group"

    if [ -n "$uid" ]; then
        useraddOptions="$useraddOptions --non-unique --uid $uid"
    fi

    if [ -n "$gid" ]; then
        if ! $(cat /etc/group | cut -d: -f3 | grep -q "$gid"); then
            groupadd --gid $gid "group_$gid"
        fi

        useraddOptions="$useraddOptions --gid $gid"
    fi

    useradd $useraddOptions $user
    mkdir -p /home/$user
    chown root:root /home/$user
    chmod 755 /home/$user

    if [ -n "$pass" ]; then
        echo "$user:$pass" | chpasswd $chpasswdOptions
    else
        usermod -p "*" $user # disabled password
    fi

    # Add SSH keys to authorized_keys with valid permissions
    if [ -d /home/$user/.ssh/keys ]; then
        cat /home/$user/.ssh/keys/* >> /home/$user/.ssh/authorized_keys
        chown $user /home/$user/.ssh/authorized_keys
        chmod 600 /home/$user/.ssh/authorized_keys
    fi

    # Make sure dirs exists and has correct permissions
    if [ -n "$dir" ]; then
        IFS=',' read -a dirParam <<< $dir
        for dirPath in ${dirParam[@]}; do
            dirPath=/home/$user/$dirPath
            echo "Creating and/or setting permissions on $dirPath"
            mkdir -p $dirPath
            chown -R $user:users $dirPath
        done
    fi
}

if [[ $1 =~ ^--help$|^-h$ ]]; then
    printHelp
    exit 0
fi

if [ "$1" == "--readme" ]; then
    printReadme
    exit 0
fi

# Create users only on first run
if [ ! -f "$userConfFinalPath" ]; then

    # Append mounted config to final config
    if [ -f "$userConfPath" ]; then
        cat "$userConfPath" | grep -v -e '^$' > "$userConfFinalPath"
    fi

    # Append users from arguments to final config
    if [ ! -z "$USER" ]; then
      for user in "$USER"; do
          echo "$user" >> "$userConfFinalPath"
      done
    fi

    # Append users from STDIN to final config
    if [ ! -t 0 ]; then
        while IFS= read -r user || [[ -n "$user" ]]; do
            echo "$user" >> "$userConfFinalPath"
        done
    fi

    # Check that we have users in config
    if [ "$(cat "$userConfFinalPath" | wc -l)" == 0 ]; then
        echo "FATAL: No users provided!"
        printHelp
        exit 3
    fi

    # Import users from final conf file
    while IFS= read -r user || [[ -n "$user" ]]; do
        createUser "$user"
    done < "$userConfFinalPath"

    # Generate unique ssh keys for this container, if needed
    if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then
        ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' < /dev/null
    fi
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N '' < /dev/null
    fi
fi

# Source custom scripts, if any
if [ -d /etc/sftp.d ]; then
    for f in /etc/sftp.d/*; do
        if [ -x "$f" ]; then
            echo "Running $f ..."
            $f
        fi
    done
    unset f
fi

echo "Running server"

exec /usr/sbin/sshd -D -e