#!/bin/bash

LOG=/var/log/adduser.log

[ -n "$X_USER" ] && {
  adduser --disabled-password --shell /bin/bash --gecos $X_USER --quiet $X_USER>>$LOG
  for F in $(cd /etc/skel; ls .[a-z]*); do
    if [ ! -f /home/$X_USER/$F ]; then
      cp -p /etc/skel/$F /home/$X_USER/$F>>$LOG
      chown $X_USER:$X_USER /home/$X_USER/$F>>$LOG
    fi
  done

  [ -d /etc/sudoers.d ] && {
    cat << EOF > /etc/sudoers.d/$X_USER
$X_USER ALL=(ALL) NOPASSWD: ALL
EOF
    chmod 0440 /etc/sudoers.d/$X_USER>>$LOG
  }
}
