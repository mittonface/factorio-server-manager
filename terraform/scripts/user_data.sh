#!/bin/bash
# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1


# Update system
apt update
apt upgrade -y

# Install required packages for EFS
apt install -y nfs-common jq awscli

# Create mount directory
mkdir -p /mnt/efs

# Mount EFS
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns_name}:/ /mnt/efs

# Make mount permanent
echo "${efs_dns_name}:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab

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

# Download and extract Factorio
cd /mnt/efs
wget -O linux64.tar.xz https://factorio.com/get-download/stable/headless/linux64
tar -xf linux64.tar.xz

wget https://raw.githubusercontent.com/mittonface/factorio-server-manager/refs/heads/main/terraform/scripts/server-settings.json
wget https://raw.githubusercontent.com/mittonface/factorio-server-manager/refs/heads/main/terraform/scripts/map-gen-settings.json
wget https://raw.githubusercontent.com/mittonface/factorio-server-manager/refs/heads/main/terraform/scripts/map-settings.json

echo "Setup completed at $(date)" > /tmp/setup-completed.txt

# Replace the variables in server-settings.json with actual values
sed -i "s/\$FACTORIO_USERNAME/$FACTORIO_USERNAME/g" server-settings.json
sed -i "s/\$FACTORIO_PASSWORD/$FACTORIO_PASSWORD/g" server-settings.json
sed -i "s/\$GAME_PASSWORD/$GAME_PASSWORD/g" server-settings.json

# this _should_ only be run the first time the instance is created. 
# feels like maybe still the wrong time to run it
./factorio/bin/x64/factorio --create saves/boy-save.zip --map-gen-settings ./mnt/efs/map-gen-settings.json --map-settings ./mnt/efs/map-settings.json

# reboot so the profile.d script we just created will be run
reboot