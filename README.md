# Terraform AWS Infrastructure

This repository contains Terraform code to set up an AWS infrastructure, including a VPC, a public subnet, an Internet Gateway, and EC2 instances for k3s (Kubernetes) and Jenkins. It also provisions security groups, IAM roles, and an Amazon ECR repository for managing Docker images.

![AWS Infrastructure Diagram](Project%20Architecture.png)

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- An AWS account with the necessary permissions to create the resources specified in the Terraform code.
- AWS CLI configured with your credentials. You can configure it using:

    ```bash
    aws configure
    ```

## Infrastructure Overview

The following AWS resources are created using Terraform:

- A provider configuration for AWS in the `us-east-1` region.
- A VPC (`kady-vpc`) with a CIDR block of `10.0.0.0/16`.
- A public subnet (`kady-public-subnet`) with a CIDR block of `10.0.1.0/24`, in availability zone `us-east-1a`, and with public IP assignment on launch.
- An Internet Gateway (`kady-internet-gateway`) for Internet access.
- A public route table (`kady-public-route-table`) with a route for all traffic (`0.0.0.0/0`) via the Internet Gateway.
- Two security groups:
  - `k3s-sg`: Allows SSH (port 22) and Kubernetes HTTP (port 30000) access.
  - `jenkins-sg`: Allows SSH (port 22) and Jenkins HTTP (port 8080) access.
- IAM roles and policies:
  - `k3s` IAM role: Allows EC2 and ECR access for Kubernetes operations.
  - `jenkins` IAM role: Allows EC2 and ECR access for Jenkins.
  - Instance profiles assigned to EC2 instances for role-based permissions.
- Two EC2 instances:
  - `k3s` (t2.micro): Runs k3s (Kubernetes), with Helm and Nginx installed via user data.
  - `jenkins` (t2.micro): Runs Jenkins, with Docker and Ansible installed via user data.
- An Amazon ECR repository (`kady-docker-repo`) for storing Docker images for the project.

## Deployment Steps

1. **Clone the Repository**

   Clone this repository to your local machine:

   ```bash
   git clone https://github.com/goushaa/DEPI-Terraform.git
   cd DEPI-Terraform
   ```

2. **Initialize Terraform**

   Initialize the Terraform workspace:

   ```bash
   terraform init
   ```

3. **Plan the Deployment**

   Create an execution plan to see what resources will be created:

   ```bash
   terraform plan
   ```   

4. **Apply the Deployment**

   Deploy the infrastructure by applying the plan:

   ```bash
   terraform apply
   ```    
   Review the output and type `yes` when prompted to confirm.

## Managing Resources

### Destroying the Infrastructure

To delete all resources created by this Terraform configuration, run:

```bash
terraform destroy
```
After reviewing the output, type `yes` when prompted to confirm.

### Updating Resources

If you need to make changes to your configuration, edit the `.tf` files and run:

```bash
terraform apply
```

## Note

- The `ubuntu_ami` variable is set to a specific AMI ID. Ensure that this AMI ID is valid in the `us-east-1` region. You can update it in the `variables.tf` file if needed.
- Ensure that your AWS account has the required permissions to create the resources specified in this configuration.

