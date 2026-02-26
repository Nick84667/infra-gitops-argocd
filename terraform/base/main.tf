provider "aws" {
  region = var.region
}

data "aws_availability_zones" "azs" {}


# --- SG SSH only from your IP ---
resource "aws_security_group" "bastion_sg" {
  name   = "${var.project}-bastion-sg"
  vpc_id = aws_vpc.this.id

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- KeyPair from your public key ---
resource "aws_key_pair" "bastion" {
  key_name   = "${var.project}-bastion-key"
  public_key = var.ssh_public_key
}

# --- EC2 IAM role (no access keys on instance) ---
resource "aws_iam_role" "ec2_role" {
  name = "${var.project}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
}

# Lab fast (poi la restringiamo)
resource "aws_iam_role_policy_attachment" "ec2_admin" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# --- Ubuntu 22.04 AMI ---
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter { 
    name = "name" 
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"] 
  }
}

# --- EC2 Bastion ---
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.ubuntu_2204.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.bastion.key_name
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = { Name = var.name }
}

# --- Existing GitHub OIDC provider ---
data "aws_iam_openid_connect_provider" "github" {
  arn = var.oidc_provider_arn
}

# --- Dedicated role for this repo (switch AWS_ROLE_ARN to this later) ---
resource "aws_iam_role" "gha_role" {
  name = "${var.project}-gha-terraform-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Federated = data.aws_iam_openid_connect_provider.github.arn },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        },
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "gha_admin" {
  role       = aws_iam_role.gha_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
