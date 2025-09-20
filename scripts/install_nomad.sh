#!/bin/bash
set -e

NOMAD_VERSION=$1
NOMAD_DOWNLOAD_URL=$2

echo "Updating packages..."
sudo apt-get update -y

echo "Installing dependencies..."
sudo apt-get install -y unzip curl jq docker.io

echo "Installing Nomad version $NOMAD_VERSION..."
cd /tmp
curl -O ${NOMAD_DOWNLOAD_URL}
unzip "nomad_${NOMAD_VERSION}_linux_amd64.zip"
sudo mv nomad /usr/local/bin/
sudo chmod +x /usr/local/bin/nomad

sudo useradd --system --home /etc/nomad.d --shell /bin/false nomad || true
sudo mkdir -p /etc/nomad.d /var/lib/nomad
sudo chown -R nomad:nomad /etc/nomad.d /var/lib/nomad
sudo chmod 700 /etc/nomad.d

cat <<EOF | sudo tee /etc/systemd/system/nomad.service
[Unit]
Description=Nomad Agent
Documentation=https://www.nomadproject.io/docs/
After=network.target

[Service]
User=nomad
Group=nomad
ExecStart=/usr/local/bin/nomad agent -config=/etc/nomad.d
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=process
Restart=on-failure
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

echo "Enabling and starting Nomad service..."
sudo systemctl daemon-reload
sudo systemctl enable nomad
sudo systemctl start nomad

echo "Applying basic security hardening..."
sudo passwd -l root
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

echo "Installation and configuration complete."
