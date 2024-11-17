#!/bin/bash
# Log all output
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

# Update system
apt-get update
apt-get upgrade -y

# Install required packages for EFS
apt-get install -y \
    nfs-common \
    amazon-efs-utils

# Create mount directory
mkdir -p /mnt/efs

# Mount EFS
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns_name}:/ /mnt/efs

# Make mount permanent
echo "${efs_dns_name}:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport 0 0" >> /etc/fstab

# Set permissions
chown -R ubuntu:ubuntu /mnt/efs

# Download and extract Factorio
cd /mnt/efs
wget -O linux64.tar.xz https://factorio.com/get-download/stable/headless/linux64
tar -xf linux64.tar.xz

echo "Setup completed at $(date)" > /tmp/setup-completed.txt