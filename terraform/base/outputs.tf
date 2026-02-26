output "vpc_id" {
  value = aws_vpc.this.id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip
}
output "bastion_public_dns" {
  value = aws_instance.bastion.public_dns
}
output "ssh_command" {
  value = "ssh -i keydevops.pem ubuntu@${aws_instance.bastion.public_dns}"
}

output "gha_role_arn" {
  value = aws_iam_role.gha_role.arn
}
