variable "aws_region" {
  description = "aws region (default is us-east-2)"
  default     = "us-east-2"
}

variable "bigip_port" {
  description = "The BIG-IP explicit proxy port for proxy requests from client"
  default     = 8080
}

variable "aws_keypair" {
  description = "The name of an existing key pair. In AWS Console: NETWORK & SECURITY -> Key Pairs"
  default     = "f5_aws_acct_keypair"
}


variable "DeploymentSpecificName" {
  description = "Deployment specific description, used to name objects associated with this deployment"
  default     = "Test"
}

variable "restrictedSrcAddress" {
  type        = list(string)
  description = "Lock down management access by source IP address or network"
  default     = ["0.0.0.0/0", "10.0.0.0/16"]
}

variable "adminUsername" {
  default = "adminF5"
}
variable "do_rpm" {
  default = "f5-declarative-onboarding-1.13.0-5.noarch.rpm"
}
variable "as3_rpm" {
  default = "f5-appsvcs-3.20.0-3.noarch.rpm"
}
variable "ts_rpm" {
  default = "f5-telemetry-1.12.0-3.noarch.rpm"
}
variable "managementGuiPort" {
  default = "8443"
}
variable "tenant" {
  default = "testTenant"
}