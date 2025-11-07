provider "aws" {
      region = var.aws_region
    }

    # --- VPC ---
    resource "aws_vpc" "main" {
      cidr_block           = "10.0.0.0/16"
      enable_dns_hostnames = true
      enable_dns_support   = true
      tags = {
        Name = "${var.project_name}-vpc"
      }
    }

    resource "aws_internet_gateway" "main" {
      vpc_id = aws_vpc.main.id
      tags = {
        Name = "${var.project_name}-igw"
      }
    }

    resource "aws_subnet" "public" {
      vpc_id            = aws_vpc.main.id
      cidr_block        = "10.0.1.0/24"
      map_public_ip_on_launch = true
      availability_zone = "${var.aws_region}a" # Example AZ, adjust as needed
      tags = {
        Name = "${var.project_name}-public-subnet"
      }
    }

    resource "aws_route_table" "public" {
      vpc_id = aws_vpc.main.id
      route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
      }
      tags = {
        Name = "${var.project_name}-public-rt"
      }
    }

    resource "aws_route_table_association" "public" {
      subnet_id      = aws_subnet.public.id
      route_table_id = aws_route_table.public.id
    }

    # --- Security Groups ---
    resource "aws_security_group" "ssh_sg" {
      name        = "${var.project_name}-ssh-sg"
      description = "Allow SSH inbound traffic"
      vpc_id      = aws_vpc.main.id

      ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # WARNING: In production, restrict to known IPs!
      }
      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      tags = {
        Name = "${var.project_name}-ssh-sg"
      }
    }

    resource "aws_security_group" "web_app_sg" {
      name        = "${var.project_name}-web-app-sg"
      description = "Allow HTTP inbound traffic to web app (port 5000)"
      vpc_id      = aws_vpc.main.id

      ingress {
        from_port   = 5000
        to_port     = 5000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # WARNING: In production, restrict to known IPs!
      }
      egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
      tags = {
        Name = "${var.project_name}-web-app-sg"
      }
    }

    resource "aws_security_group" "monitoring_sg" {
      name        = "${var.project_name}-monitoring-sg"
      description = "Allow Prometheus and Grafana access"
      vpc_id      = aws_vpc.main.id

      ingress {
        from_port   = 9090 # Prometheus UI
        to_port     = 9090
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # WARNING: In production, restrict to known IPs!
      }
      ingress {
        from_port   = 3000 # Grafana UI
        to_port     = 3000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] # WARNING: In production, restrict to known IPs!
      }
      # Allow Node Exporter (default 9100) and Prometheus scrape targets
      ingress {
        from_port   = 9100 # Node Exporter
        to_port     = 9100
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
        Name = "${var.project_name}-monitoring-sg"
      }
    }

    # --- EC2 Instance ---
    resource "aws_key_pair" "generated_key"{
      key_name   = "${var.project_name}-key"
      public_key = file(var.public_key_path) # Use the public key from your local SSH key pair
    }

    data "aws_ami" "ubuntu" {
      most_recent = true
      filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
      }
      filter {
        name   = "virtualization-type"
        values = ["hvm"]
      }
      owners = ["099720109477"] # Canonical
    }

    resource "aws_instance" "app_server"{
      ami           = data.aws_ami.ubuntu.id
      instance_type = "t3.micro"
      subnet_id     = aws_subnet.public.id
      vpc_security_group_ids = [
        aws_security_group.ssh_sg.id,
        aws_security_group.web_app_sg.id,
        aws_security_group.monitoring_sg.id
      ]
      key_name      = aws_key_pair.generated_key.key_name
      associate_public_ip_address = true

      tags = {
        Name        = "${var.project_name}-app-server"
        Project     = var.project_name
      }
    }
