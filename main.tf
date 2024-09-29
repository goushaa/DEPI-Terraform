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
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
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

variable "ubuntu_ami" {
  default = "ami-0e86e20dae9224db8" # Ubuntu ISO in us-east-1
}

resource "aws_instance" "k3s" {
  ami           = var.ubuntu_ami
  instance_type = "t2.micro" 
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true

  tags = {
    Name = "k3s"
  }
}

resource "aws_instance" "jenkins" {
  ami           = var.ubuntu_ami
  instance_type = "t2.micro" 
  subnet_id     = aws_subnet.public_subnet.id
  associate_public_ip_address = true

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
