# E-Commerce DevOps Mini Project

This repository contains a complete DevOps pipeline that deploys an e-commerce application on AWS using Terraform, Ansible, Docker, and GitHub Actions.

## Project structure

- `terraform/` - AWS infrastructure as code
- `ansible/` - automated server configuration and deployment
- `.github/workflows/pipeline.yml` - CI/CD pipeline definition
- `app/` - simple Node.js e-commerce application

## Prerequisites

- AWS account with `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION`
- Existing AWS EC2 key pair name in the selected region
- GitHub repository with GitHub Actions enabled
- SSH private key stored in GitHub Secrets as `EC2_KEY`

## Required GitHub Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `EC2_KEY`

## Terraform setup

The Terraform configuration launches:

- VPC and public subnet
- Internet gateway and route table
- Application Load Balancer
- EC2 instance(s) with public IP
- Security groups for SSH and HTTP

### Configure Terraform variables

Set values in `terraform/terraform.tfvars` or pass them during apply:

```hcl
aws_region = "us-east-1"
key_name   = "my-ec2-keypair"
instance_type = "t3.micro"
instance_count = 1
```

## Ansible deployment

The Ansible playbook installs Docker and Docker Compose, copies the application and `docker-compose.yml` to the EC2 host, and launches the app using PM2 inside the Node.js container.

## GitHub Actions pipeline

The pipeline defined in `.github/workflows/pipeline.yml`:

1. Runs Terraform to provision AWS resources
2. Exports EC2 public IPs for Ansible
3. Runs Ansible to deploy the Docker stack
4. Optionally destroys infrastructure on manual dispatch

## Run locally

1. Initialize Terraform:

   ```bash
   cd terraform
   terraform init
   ```

2. Plan and apply:

   ```bash
   terraform plan -out=tfplan
   terraform apply -auto-approve tfplan
   ```

3. Copy the generated EC2 public IP into `ansible/inventory.ini` or use the GitHub Actions pipeline.

## Expected result

After deployment, visiting the ALB DNS name should show the e-commerce store with sample products.
