#!/bin/bash
# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update system
apt update
apt upgrade -y

# Install required packages for EFS
apt install -y nfs-common jq awscli git binutils rustc cargo pkg-config libssl-dev


# Add the Player Monitoring Script
wget https://raw.githubusercontent.com/mittonface/factorio-server-manager/refs/heads/main/terraform/scripts/player_monitor.py
chmod +x player_monitor.py
mv player_monitor.py /usr/local/bin/factorio-player-monitor.py


# Manually installed EFS Utils
git clone https://github.com/aws/efs-utils
cd efs-utils
./build-deb.sh
apt install -y ./build/amazon-efs-utils*deb

# Create mount directory
mkdir -p /mnt/efs

# Mount EFS using efs-utils
echo "${efs_dns_name}:/ /mnt/efs efs _netdev,tls,iam 0 0" >> /etc/fstab
mount -a

# Fetch secrets and set environment variables
SECRET_JSON=$(aws secretsmanager get-secret-value \
    --secret-id ${secret_arn} \
    --region ${aws_region} \
    --query SecretString \
    --output text)

# Extract the values from the secret
FACTORIO_USERNAME=$(echo "$SECRET_JSON" | jq -r '.FACTORIO_USERNAME')
FACTORIO_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.FACTORIO_PASSWORD')
GAME_PASSWORD=$(echo "$SECRET_JSON" | jq -r '.GAME_PASSWORD')

# Create the env file with the actual values
cat << EOF > /etc/profile.d/factorio-env.sh
export FACTORIO_USERNAME=$FACTORIO_USERNAME
export FACTORIO_PASSWORD=$FACTORIO_PASSWORD
export GAME_PASSWORD=$GAME_PASSWORD
EOF

# Make it executable
chmod a+x /etc/profile.d/factorio-env.sh

# Set permissions
chown -R ubuntu:ubuntu /mnt/efs

# Setup log directory
mkdir -p /var/log/factorio
chown ubuntu:ubuntu /var/log/factorio


# Download and extract Factorio
cd /mnt/efs
wget -O linux64.tar.xz https://factorio.com/get-download/stable/headless/linux64
tar -xf linux64.tar.xz
wget https://raw.githubusercontent.com/mittonface/factorio-server-manager/refs/heads/main/terraform/scripts/server-settings.json
wget https://raw.githubusercontent.com/mittonface/factorio-server-manager/refs/heads/main/terraform/scripts/map-gen-settings.json
wget https://raw.githubusercontent.com/mittonface/factorio-server-manager/refs/heads/main/terraform/scripts/map-settings.json

# Replace the variables in server-settings.json with actual values
sed -i "s/\$FACTORIO_USERNAME/$FACTORIO_USERNAME/g" server-settings.json
sed -i "s/\$FACTORIO_PASSWORD/$FACTORIO_PASSWORD/g" server-settings.json
sed -i "s/\$GAME_PASSWORD/$GAME_PASSWORD/g" server-settings.json

chown -R ubuntu:ubuntu /mnt/efs
find /mnt/efs -type d -exec chmod 755 {} \;
find /mnt/efs -type f -exec chmod 644 {} \;
chmod +x /mnt/efs/factorio/bin/x64/factorio

cd ./factorio
# Create initial save if it doesn't exist
if [ ! -f saves/boy-save.zip ]; then
    ./bin/x64/factorio --create saves/boy-save.zip --map-gen-settings /mnt/efs/map-gen-settings.json --map-settings /mnt/efs/map-settings.json
fi


# Create systemd service for Factorio
cat << 'EOF' > /etc/systemd/system/factorio.service
[Unit]
Description=Factorio Server
After=network-online.target remote-fs.target
Wants=network-online.target
RequiresMountsFor=/mnt/efs

[Service]
Type=simple
User=ubuntu
Group=ubuntu
WorkingDirectory=/mnt/efs
ExecStart=/mnt/efs/factorio/bin/x64/factorio --start-server-load-latest --server-settings /mnt/efs/server-settings.json
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/factorio/factorio.log
StandardError=append:/var/log/factorio/factorio-error.log

[Install]
WantedBy=multi-user.target
EOF

# Create service for player monitor
cat << 'EOF' > /etc/systemd/system/factorio-player-monitor.service
[Unit]
Description=Factorio Player Monitor
After=factorio.service
Requires=factorio.service

[Service]
Type=simple
User=ubuntu
Group=ubuntu
ExecStart=/usr/local/bin/factorio-player-monitor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# make sure hte permissions are correct before trying to start the service
chown -R ubuntu:ubuntu /mnt/efs

# Enable and start Factorio service
systemctl daemon-reload
systemctl enable factorio.service
systemctl start factorio.service

# Write a cloud-init success file
cat << EOF > /var/lib/cloud/instance/success.txt
success: $(date)
EOF

# Instead of rebooting, just source the environment file
source /etc/profile.d/factorio-env.sh

echo "Setup completed at $(date)" > /tmp/setup-completed.txt