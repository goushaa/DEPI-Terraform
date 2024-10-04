provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "kady-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "kady-public-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "kady-internet-gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "kady-public-route-table"
  }
}

resource "aws_route" "public_internet_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_rt_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "k3s_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 30000
    to_port     = 30000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k3s-sg"
  }
}

resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

variable "ubuntu_ami" {
  default = "ami-0e86e20dae9224db8" # Ubuntu ISO in us-east-1 | Use Data Source Instead
}

resource "aws_instance" "k3s" {
  ami                         = var.ubuntu_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.k3s_sg.id]
  key_name                    = "k3sPair.pem"
  user_data                   = <<-EOF
                #!/bin/bash
                exec > >(tee /var/log/user-data.log) 2>&1

                apt update
                apt install -y curl

                curl -sfL https://get.k3s.io | sh -
                chmod 644 /etc/rancher/k3s/k3s.yaml
                chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml

                curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
                chmod 700 get_helm.sh
                ./get_helm.sh

                # Set KUBECONFIG environment variable for the current session
                export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

                # Add KUBECONFIG export to the user's bashrc for future sessions
                echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/ubuntu/.bashrc

                helm repo add kubegemsapp https://charts.kubegems.io/kubegemsapp
                helm install nginx kubegemsapp/nginx --version 9.3.4 --namespace nginx --create-namespace --set resources.limits.cpu=500m,resources.limits.memory=500Mi,resources.requests.cpu=100m,resources.requests.memory=128Mi,service.nodePorts.http=30000

                sudo -u ubuntu helm repo add kubegemsapp https://charts.kubegems.io/kubegemsapp
                EOF

  tags = {
    Name = "k3s"
  }
}



resource "aws_instance" "jenkins" {
  ami                         = var.ubuntu_ami
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  user_data                   = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log) 2>&1

              # Update package lists and install necessary packages
              apt update
              apt install -y curl software-properties-common unzip

              # Add Ansible PPA and install Ansible
              add-apt-repository --yes --update ppa:ansible/ansible
              apt install -y ansible

              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install

              # Download the Ansible playbook for Docker and Jenkins installation
              groupadd docker
              usermod -aG docker ubuntu
              groupadd jenkins
              usermod -aG docker jenkins
              newgrp docker

              ansible-galaxy install iam-surya369.java-jenkins-docker
              curl -O https://raw.githubusercontent.com/goushaa/DEPI-Ansible/refs/heads/main/role_docker_jenkins.yaml
              ansible-playbook role_docker_jenkins.yaml
              EOF

  tags = {
    Name = "jenkins"
  }
}

resource "aws_ecr_repository" "my_repository" {
  name                 = "kady-docker-repo"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "kady-ecr-repo"
  }
}

## Another way to deploy k3s, but needs t2.small instance which is not in the free tier
# resource "aws_instance" "k3sbig" {
#   ami                         = var.ubuntu_ami
#   instance_type               = "t2.small"
#   subnet_id                   = aws_subnet.public_subnet.id
#   associate_public_ip_address = true
#   vpc_security_group_ids      = [aws_security_group.k3s_sg.id]
#   user_data                   = <<-EOF
#                 #!/bin/bash
#                 exec > >(tee /var/log/user-data.log) 2>&1

#                 apt update
#                 apt install -y curl

#                 curl -sfL https://get.k3s.io | sh -
#                 chmod 644 /etc/rancher/k3s/k3s.yaml
#                 chown ubuntu:ubuntu /etc/rancher/k3s/k3s.yaml

#                 curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
#                 chmod 700 get_helm.sh
#                 ./get_helm.sh

#                 # Set KUBECONFIG environment variable for the current session
#                 export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

#                 # Add KUBECONFIG export to the user's bashrc for future sessions
#                 echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/ubuntu/.bashrc

#                 helm repo add bitnami https://charts.bitnami.com/bitnami
#                 helm repo update
#                 helm install nginx bitnami/nginx

#                 sudo -u ubuntu helm repo add bitnami https://charts.bitnami.com/bitnami
#                 sudo -u ubuntu helm repo update
#                 EOF


#   tags = {
#     Name = "k3sBIG"
#   }
# }