# Factorio Server on AWS

This project deploys a Factorio game server on AWS using Terraform. It sets up a fully managed environment with automatic secrets management and persistent storage using EFS.

## Overview

The infrastructure includes:
- EC2 instance running Ubuntu 22.04 LTS
- EFS for persistent game data storage
- VPC with public subnet
- Security groups for both EC2 and EFS
- IAM roles for secrets management
- Automatic server configuration using user data script

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version 1.0.0 or later)
- A secret in AWS Secrets Manager containing:
  ```json
  {
    "FACTORIO_USERNAME": "your_factorio_username",
    "FACTORIO_PASSWORD": "your_factorio_password",
    "GAME_PASSWORD": "your_game_server_password"
  }
  ```

## Directory Structure

```
.
├── main.tf          # Main Terraform configuration
├── scripts/
│   └── user_data.sh # EC2 instance configuration script
└── variables.tf     # (not shown) Define your variables here
```

## Usage

1. Initialize Terraform:
```bash
terraform init
```

2. Review the planned changes:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

4. After deployment, get the server IP:
```bash
terraform output public_ip
```

## Connecting to the Server

- The Factorio server runs on port 34197 (UDP)
- Use the game password specified in your AWS Secrets Manager secret
- Connect using the public IP provided in the Terraform output

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Security Notes

- The server is accessible from any IP (0.0.0.0/0) on ports 22 (SSH) and 34197 (Factorio)
- Game credentials are stored securely in AWS Secrets Manager
- EFS is encrypted at rest
- All resources are tagged for easy identification

## Monitoring

- Check EC2 instance logs: `/var/log/user-data.log`
- Server setup completion marker: `/tmp/setup-completed.txt`
- Game data is stored in `/mnt/efs/factorio`