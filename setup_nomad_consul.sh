#!/bin/sh
set -e

sudo chmod -R 775 /tmp/script-app/

echo 'Installing Scripts Nomad-Consul...'
/tmp/script-app/nomad/install-nomad/install-nomad --version "${NOMAD_VERSION}"
/tmp/script-app/consul/install-consul/install-consul --version "${CONSUL_VERSION}"

echo 'Installing Docker...'
curl -fsSL https://get.docker.com | sudo bash

echo 'Installing DataDog...'
sudo apt update -y
sudo apt-get install -y apt-transport-https curl gnupg

sudo sh -c "echo 'deb [signed-by=/usr/share/keyrings/datadog-archive-keyring.gpg] https://apt.datadoghq.com/ stable 7' > /etc/apt/sources.list.d/datadog.list"
sudo touch /usr/share/keyrings/datadog-archive-keyring.gpg
sudo chmod a+r /usr/share/keyrings/datadog-archive-keyring.gpg

curl https://keys.datadoghq.com/DATADOG_APT_KEY_CURRENT.public | sudo gpg --no-default-keyring --keyring /usr/share/keyrings/datadog-archive-keyring.gpg --import --batch
curl https://keys.datadoghq.com/DATADOG_APT_KEY_382E94DE.public | sudo gpg --no-default-keyring --keyring /usr/share/keyrings/datadog-archive-keyring.gpg --import --batch
curl https://keys.datadoghq.com/DATADOG_APT_KEY_F14F620E.public | sudo gpg --no-default-keyring --keyring /usr/share/keyrings/datadog-archive-keyring.gpg --import --batch

sudo apt update
echo 'Installing DataDog Provider...'
sudo apt-get -y install datadog-agent=1:${DATADOG_VERSION}-1 datadog-signing-keys
echo 'Completed DataDog installation...'