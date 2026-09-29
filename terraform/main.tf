terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Existing VPC
resource "aws_vpc" "devops_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = false

  tags = {
    Name = "devops-vpc"
  }
}

# Existing public subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-public-subnet-1"
  }
}

# Existing public subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.public_subnet_2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "devops-public-subnet-2"
  }
}

# Existing private subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.private_subnet_1_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "devops-private-subnet-1"
  }
}

# Existing private subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.devops_vpc.id
  cidr_block              = var.private_subnet_2_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "devops-private-subnet-2"
  }
}