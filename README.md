# Bunch of Nerds Factorio Server Control Panel

A web-based control panel for managing our private Factorio game server running on AWS infrastructure. This project uses spot instances to minimize costs while providing a reliable gaming experience for our group.

**Current Instance**: [https://factorio.mittn.ca](https://factorio.mittn.ca)

> **Note**: This project is specifically built for the Bunch of Nerds Factorio server and contains hardcoded values and configurations. It's not designed to be a reusable solution for other Factorio servers.

## Overview

This project provides our group with a simple web interface to start and stop our Factorio game server hosted on AWS. It includes features such as:

- Server status monitoring
- Current player tracking
- Graceful shutdown handling for spot instances
- Password-protected server controls
- Real-time status updates

## Technology Stack

### Frontend

- **Next.js 15.0** - React framework for the web interface
- **React 19.0** - UI component library
- **TailwindCSS 3.4** - Utility-first CSS framework
- **Lucide React** - Icon library
- **Geist Font** - Typography

### Backend

- **AWS SDK** - For interacting with AWS services
- **Python 3.9** - Lambda function runtime
- **Factorio RCON** - For game server communication

### AWS Services

- **ECS** - Container orchestration for the Factorio server
- **Lambda** - Serverless functions for status checks and shutdown handling
- **CloudFormation** - Infrastructure as Code
- **EventBridge** - Scheduled tasks and spot instance interruption handling
- **S3** - Storage for server status data
- **Secrets Manager** - Secure credential storage

### Infrastructure

- **Terraform** - Infrastructure as Code
- **Make** - Build automation

## Architecture

The system consists of several components:

1. **Web Interface**: A Next.js application that provides server controls and status monitoring
2. **Status Lambda**: Checks player status every minute and updates S3
3. **Shutdown Handler**: Gracefully handles spot instance interruptions
4. **CloudFormation Stack**: Manages the Factorio server infrastructure

## Local Development

1. Install dependencies:

```bash
npm install
```

2. Create a `.env` file with required AWS credentials and configuration:

   - SERVER_PASSWORD
   - ACCESS_KEY
   - SECRET_KEY
   - MY_IP

3. Start the development server:

```bash
npm run dev
```

## Lambda Functions

### Build Lambda Functions

```bash
make build-shutdown-lambda
make build-online-lambda
```

### Deploy Infrastructure

```bash
cd infrastructure
terraform init
terraform apply
```

## Security

- Server access is password-protected
- AWS credentials are managed through environment variables
- RCON password is stored in AWS Secrets Manager
- S3 bucket is configured with appropriate CORS and public access settings

## Important Note

This project contains hardcoded values specific to our setup, including:

- AWS account IDs
- Domain names (brent.click)
- Bucket names
- Secret ARNs
- Hosted zone IDs
