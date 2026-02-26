# --- SG for VPC Interface Endpoints ---
resource "aws_security_group" "vpce_sg" {
  name        = "${var.project}-vpce-sg"
  description = "SG for VPC Interface Endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-vpce-sg" }
}

# --- Gateway Endpoint: S3 (needed for ECR layers, etc.) ---
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id]

  tags = { Name = "${var.project}-vpce-s3" }
}

# --- Interface Endpoints (no NAT) ---
locals {
  interface_endpoints = toset([
    "com.amazonaws.${var.region}.eks",
    "com.amazonaws.${var.region}.ecr.api",
    "com.amazonaws.${var.region}.ecr.dkr",
    "com.amazonaws.${var.region}.ec2",
    "com.amazonaws.${var.region}.sts",
    "com.amazonaws.${var.region}.logs"
  ])
}

resource "aws_vpc_endpoint" "iface" {
  for_each           = local.interface_endpoints
  vpc_id             = aws_vpc.this.id
  service_name       = each.value
  vpc_endpoint_type  = "Interface"

  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.vpce_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.project}-vpce-${replace(each.value, "com.amazonaws.${var.region}.", "")}"
  }
}
