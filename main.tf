# Doc : https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
# Generate an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Doc : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = tls_private_key.example_ssh.public_key_openssh
}

# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "main-vpc"
    environment = "staging"
  }
}

# Doc : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
# Create a subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name        = "main-subnet"
    environment = "staging"
  }
}

# Doc : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "main-gateway"
    environment = "staging"
  }
}

# Doc : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# Create a route table
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "main-rt"
    environment = "staging"
  }
}

# Associate the subnet with the route table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# Create a security group
resource "aws_security_group" "sg" {
  name        = "allow-ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
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
    environment = "staging"
  }
}

# Doc : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
# Create an S3 bucket for logs (optional)
resource "random_id" "random" {
  byte_length = 8
}

resource "aws_s3_bucket" "boot_logs" {
  bucket = "vm-boot-logs-${random_id.random.hex}"
}

# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# Launch EC2 instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.main.id
  vpc_security_group_ids      = [aws_security_group.sg.id]
  key_name                    = aws_key_pair.deployer.key_name
  associate_public_ip_address = true

  tags = {
    Name        = var.instance_name
    environment = "staging"
  }
}

# Docs: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
