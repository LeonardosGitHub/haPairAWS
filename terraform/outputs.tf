

output "A_Public_IP_for_BIGIP_a" {
  value = aws_eip.elastic_ip-a.public_ip
}
output "B_Mgmt_IP_for_BIGIP_a" {
  value = aws_network_interface.mgmt-a.private_ip
}
output "C_External_IP_for_BIGIP_a" {
  value = aws_network_interface.public-a.private_ip
}
output "D_Internal_IP_for_BIGIP_a" {
  value = aws_network_interface.private-a.private_ip
}

output "A_Public_IP_for_BIGIP_b" {
  value = aws_eip.elastic_ip-b.public_ip
}
output "B_Mgmt_IP_for_BIGIP_b" {
  value = aws_network_interface.mgmt-b.private_ip
}
output "C_External_IP_for_BIGIP_b" {
  value = aws_network_interface.public-b.private_ip
}
output "D_Internal_IP_for_BIGIP_b" {
  value = aws_network_interface.private-b.private_ip
}

/*
output "vpc-id" {
  value = aws_vpc.terraform-vpc.id
}
output "vpc-public-id" {
  value = aws_subnet.public.id
}
output "restrictedSrcAddress" {
  value = var.restrictedSrcAddress
}
output "vpc-private-id" {
  value = aws_subnet.private.id
}
output "sshKey" {
  value = var.aws_keypair
}
output "SecurityGroupforWebServers" {
  value = aws_security_group.instance.id
}
output "ssl_certificate_id" {
  value = aws_iam_server_certificate.elb_cert.arn
}
output "aws_alias" {
  value = var.aws_alias
}
output "vpc-public" {
  value = aws_subnet.public-a.cidr_block
}
output "vpc-private" {
  value = aws_subnet.private-a.cidr_block
}
*/
