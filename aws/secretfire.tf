provider "aws" { region = "us-east-1" }

variable "env" { default = "dev" }
variable "ami" { default = "ami-6edd3078" } # Ubuntu xenial 16.04 LTS
variable "ephemeral_ami" { default = "ami-80ff1296" } # Ubuntu xenial 16.04 LTS (instance-store)
variable "phabricator_ami" { default = "ami-49c9295f" } # Ubuntu trusty 14.04 LTS
variable "subnets" { default = [ "subnet-65b46b13" ] }
variable "key_name" { default = "jw" }

# While there is technically a "data.availability_zones.available" data, it can't be interpolated into counts. Sad!
variable "availability_zones" { default = ["us-east-1a", "us-east-1b", "us-east-1d", "us-east-1e"] }

module "dev" {
    source = "./env"
    env = "${var.env}"
    cidr_block = "10.0.0.0/16"
    key_name = "${var.key_name}"
    availability_zones = "${var.availability_zones}"
}

module "phabricator" {
    source = "./phabricator"
    env = "${var.env}"
    ami = "${var.ami}"
    subnets = "${module.dev.public_subnets}"
    security_groups = ["${module.dev.private_security_group}"]
    key_name = "${var.key_name}"
    vpc = "${module.dev.vpc}"
}

output "phabricator_private_ip" { value = "${module.phabricator.private_ip}" }
output "phabricator_eip" { value = "${module.phabricator.eip}" }
output "bastion_ip" { value = "${module.dev.bastion_ip}" }
