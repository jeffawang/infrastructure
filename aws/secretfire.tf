provider "aws" { region = "us-west-2" }

variable "env" { default = "dev" }
variable "ami" { default = "ami-7c803d1c" } # Ubuntu xenial 16.04 LTS HVM
variable "ephemeral_ami" { default = "ami-e9873a89" } # Ubuntu xenial 16.04 LTS HVM (instance-store)
variable "subnets" { default = [ "subnet-65b46b13" ] }
variable "key_name" { default = "jw" }

variable "public_key" { default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDrucCBnskFwELJlPzGcTmn01P35kDrmDNIVYZgL9+Dso3p/ESHMIY4xRuRoFpxVRnRQq50YIyf76v4oJPyTRWa9i17AKxAllyMClM7y03z1dVoO4y8U+3svhMXxuXpPzVCtZacKDtvDypSWsvBZlA9kkG6M895qbGcrvWvWlpbHYNDQ4ZKB5mB5YnrMi0csXO9JlBqWHdE3iu+SbfnzQVi/93NQSJC97TgWWzKOAfFpiFIeM0ftuX/0iSZPjqv4rHDXdexirF0SMnfVxBnOhxlAMbwKJ2WxGIugUYPFpiR3lqFIgFLKnwAj8+D+gkwQtWh83j7J4S8ZrXQ6MZKpTOtGTlqUidFy+hFcTZCpdLT1wRSodOUArrWjXRU9fDNYOdDNJpXaKsl9jvxybtbCYqnRYCW5sfm+w4CRSlnYQ7eqpy03ofsc0mlQSjq3HigGpOfe85R7+28pVM27FTiB6vhV6Ay1zCYHxKMoZsxclfM84fCT2choVkJlsztxUN0efKl1DYG44Am/MMjKLyVKIaxIm1kIgrgxktcktGtku66Mmtspz46nLCUILTG4I99W7RXIhRpiLFhGfJfT1ylsKpQZKfe0S3Gzydzse7vxNLIpFx2C6D+Spc/INEfQMMZvdd7mFF3XYluZtHD0ZvSwsmiWTVxMeC5tKVmf0QEPmbAmw== jwang" }

# While there is technically a "data.availability_zones.available" data, it can't be interpolated into counts. Sad!
variable "availability_zones" { default = ["us-west-2a", "us-west-2b", "us-west-2c"] }

module "env" {
    source = "./env"
    env = "${var.env}"
    ami = "${var.ami}"
    cidr_block = "10.0.0.0/16"
    availability_zones = "${var.availability_zones}"
    key_name = "${var.key_name}"
    public_key = "${var.public_key}"
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
