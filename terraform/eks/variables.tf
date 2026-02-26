variable "region" {
  type    = string
  default = "eu-central-1"
}

variable "cluster_name" {
  type    = string
  default = "gitops-argocd"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "my_ip_cidr" {
  type        = string
  description = "CIDR allowed to access EKS public endpoint (e.g. x.x.x.x/32)"
}

variable "node_instance_type" {
  type    = string
  default = "t3.small"
}
