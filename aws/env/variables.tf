variable "env" { default = "dev" }
variable "ami" { default = "ami-6edd3078" } # Ubuntu xenial 16.04 LTS
variable "ephemeral_ami" { default = "ami-80ff1296" } # Ubuntu xenial 16.04 LTS (instance-store)
variable "key_name" {}
variable "cidr_block" {}
variable "availability_zones" { type = "list" }
