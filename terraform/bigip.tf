provider "aws" {
  region = var.aws_region
}

########################################
# BUILDING THE VPC FOR THE ENVIRONMENT #
########################################

resource "aws_vpc" "terraform-vpc" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  enable_classiclink   = "false"

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform"
  }
}

#################################################
# BUILDING SUBNETS FOR VPC IN TWO DIFFERENT AZ'S#
#################################################

resource "aws_subnet" "f5-management-a" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_management"
  }
}

resource "aws_subnet" "public-a" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_public"
  }
}

resource "aws_subnet" "private-a" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_private"
  }
}

resource "aws_subnet" "f5-management-b" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.101.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_management-b"
  }
}

resource "aws_subnet" "public-b" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.102.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_public-b"
  }
}

resource "aws_subnet" "private-b" {
  vpc_id                  = aws_vpc.terraform-vpc.id
  cidr_block              = "10.0.103.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_private-b"
  }
}


######################################
# BUILDING INTERNET GATEWAY & ROUTING#
######################################

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.terraform-vpc.id

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_internet-gateway"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.terraform-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.DeploymentSpecificName}_terraform_default_route"
  }
}

resource "aws_main_route_table_association" "association-subnet" {
  vpc_id         = aws_vpc.terraform-vpc.id
  route_table_id = aws_route_table.rt1.id
}

##################################################
# BUILDING NETWORK INTERFACES TO ATTACH TO BIG-IP#
##################################################

resource "aws_network_interface" "mgmt-a" {
  subnet_id   = aws_subnet.f5-management-a.id
  security_groups = [aws_security_group.bigipSecurityGroup.id]
 #private_ips = ["172.16.10.100"]
  tags = {
    Name = "${var.DeploymentSpecificName}_mgmt-a"
  }
}
resource "aws_network_interface" "public-a" {
  subnet_id   = aws_subnet.public-a.id
  security_groups = [aws_security_group.bigipSecurityGroup.id]
 #private_ips = ["172.16.10.100"]
  tags = {
    Name = "${var.DeploymentSpecificName}_public-a"
  }
}
resource "aws_network_interface" "private-a" {
  subnet_id   = aws_subnet.private-a.id
  security_groups = [aws_security_group.bigipSecurityGroup.id]
 #private_ips = ["172.16.10.100"]

  tags = {
    Name = "${var.DeploymentSpecificName}_private-a"
  }
}
resource "aws_network_interface" "mgmt-b" {
  subnet_id   = aws_subnet.f5-management-a.id
  security_groups = [aws_security_group.bigipSecurityGroup.id]
 #private_ips = ["172.16.10.100"]
  tags = {
    Name = "${var.DeploymentSpecificName}_mgmt-b"
  }
}
resource "aws_network_interface" "public-b" {
  subnet_id   = aws_subnet.public-a.id
  security_groups = [aws_security_group.bigipSecurityGroup.id]
 #private_ips = ["172.16.10.100"]
  tags = {
    Name = "${var.DeploymentSpecificName}_public-b"
  }
}
resource "aws_network_interface" "private-b" {
  subnet_id   = aws_subnet.private-a.id
  security_groups = [aws_security_group.bigipSecurityGroup.id]
 #private_ips = ["172.16.10.100"]

  tags = {
    Name = "${var.DeploymentSpecificName}_private-b"
  }
}
######################################################
# BUILDING SECURITY GROUP FOR PUBLIC FACING INTERFACE#
######################################################

resource "aws_security_group" "bigipSecurityGroup" {
  name   = "bigip_security_group"
  vpc_id = aws_vpc.terraform-vpc.id

  ingress {
    from_port   = 443 
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["<src_ip>/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["<src_ip>/32"]
  }

  ingress {
    from_port   = 8
    to_port     = 8
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.terraform-vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

##########################################
# GETTING ELB IP AND ATTACHING TO BIG-IP #
##########################################

resource "aws_eip" "elastic_ip-a" {
  #instance = aws_instance.bigip-a.id
  network_interface = aws_network_interface.mgmt-a.id
  vpc      = true
  tags = {
    Name = "${var.DeploymentSpecificName}_eip1"
  }
}
resource "aws_eip" "elastic_ip-b" {
  #instance = aws_instance.bigip-b.id
  network_interface = aws_network_interface.mgmt-b.id
  vpc      = true
  tags = {
    Name = "${var.DeploymentSpecificName}_eip2"
  }
}
/*
data "template_file" "cloudinit" {
  template = "${file("start-up.sh")}"
  vars = {
    adminUsername=var.adminUsername
    adminPassword=var.adminPassword
    managementGuiPort=var.managementGuiPort
    do_rpm=var.do_rpm
    as3_rpm=var.as3_rpm
    ts_rpm=var.ts_rpm
  }
}

data "template_file" "as3" {
  template = "${file("as3.json")}"
  vars = {
    tenant=var.tenant
  }
}

resource "null_resource" wait-config {
  connection {
    type     = "ssh"
    user     = var.adminUsername
    password = var.adminPassword
    host     = aws_eip.public_ip-b.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /tmp/signal ]; do sleep 2; done",
    ]
  }
  depends_on = [aws_eip.public_ip-b]
}


resource "bigip_as3"  "as3-example" {
     as3_json = data.template_file.as3.rendered
     tenant_name = var.tenant
     depends_on = [null_resource.wait-config]
}
*/

##################
# BUILDS BIG-IPS #
##################

resource "aws_instance" "bigip-a" {
 
  ami = "ami-02f9991746c6171d2"
  instance_type = "m4.2xlarge"
  key_name = var.aws_keypair
  network_interface {
    network_interface_id = aws_network_interface.mgmt-a.id
    device_index         = 0
    #delete_on_termination = true
  }
  network_interface {
    network_interface_id = aws_network_interface.public-a.id
    device_index         = 1
    #delete_on_termination = true
  }
  network_interface {
    network_interface_id = aws_network_interface.private-a.id
    device_index         = 2
    #delete_on_termination = true
  }
  tags = {
    Name = "${var.DeploymentSpecificName}_bigipA"
  }
}

resource "aws_instance" "bigip-b" {
 
  ami = "ami-02f9991746c6171d2"
  instance_type = "m4.2xlarge"
  key_name = var.aws_keypair
  network_interface {
    network_interface_id = aws_network_interface.mgmt-b.id
    device_index         = 0
    #delete_on_termination = true
  }
  network_interface {
    network_interface_id = aws_network_interface.public-b.id
    device_index         = 1
    #delete_on_termination = true
  }
  network_interface {
    network_interface_id = aws_network_interface.private-b.id
    device_index         = 2
    #delete_on_termination = true
  }
  tags = {
    Name = "${var.DeploymentSpecificName}_bigipB"
  }
  #user_data = data.template_file.cloudinit.rendered
}
