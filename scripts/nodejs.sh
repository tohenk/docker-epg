#!/bin/bash

LOG=/var/log/nodejs.log

# install nodejs
APT_OPTS="-o DPkg::Lock::Timeout=-1"
NODE_MAJOR=${NODE_VERSION:-20}
apt-get install $APT_OPTS -y ca-certificates curl gnupg>>$LOG
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | \
  gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
cat <<EOF > /etc/apt/sources.list.d/nodesource.list
deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main
EOF
apt-get update $APT_OPTS>>$LOG
apt-get install $APT_OPTS -y nodejs>>$LOG
