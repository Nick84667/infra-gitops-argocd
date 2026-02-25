variable "region" { type = string, default = "eu-central-1" }

variable "project" { type = string, default = "gitops-argocd" }

variable "name" { type = string, default = "devops-bastion" }

variable "my_ip_cidr" { type = string } # es: x.x.x.x/32

variable "ssh_public_key" { type = string } # contenuto della tua .pub

variable "oidc_provider_arn" {
  type        = string
  description = "Existing GitHub OIDC provider ARN"
}

variable "github_org" { type = string, default = "Nick84667" }
variable "github_repo" { type = string, default = "infra-gitops-argocd" }

variable "vpc_cidr" { type = string, default = "10.50.0.0/16" }

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.50.0.0/24", "10.50.1.0/24"]
}
