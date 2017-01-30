variable "env" { default = "dev" }
variable "ami" {}
variable "key_name" {}
variable "cidr_block" {}
variable "availability_zones" { type = "list" }
variable "public_key" {}
