# Terraform AWS Infrastructure

This repository contains Terraform code to set up an AWS infrastructure that includes a VPC, a public subnet, an Internet Gateway, and EC2 instances running Ubuntu. It also includes an Amazon ECR repository for Docker images.

## Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) installed on your local machine.
- An AWS account with the necessary permissions to create the resources specified in the Terraform code.
- AWS CLI configured with your credentials. You can configure it using:

    ```bash
    aws configure
    ```

## Infrastructure Overview

The following AWS resources are created:

- A VPC (`kady-vpc`) with a CIDR block of `10.0.0.0/16`.
- A public subnet (`kady-public-subnet`) within the VPC.
- An Internet Gateway (`kady-internet-gateway`) to allow Internet access.
- A route table for public routing (`kady-public-route-table`) associated with the public subnet.
- Two EC2 instances:
  - `k3s`: A Kubernetes lightweight instance.
  - `jenkins`: An instance for Jenkins.
- An Amazon ECR repository (`kady-docker-repo`) for storing Docker images.

## Deployment Steps

1. **Clone the Repository**

   Clone this repository to your local machine:

   ```bash
   git clone <repository_url>
   cd <repository_directory>
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

