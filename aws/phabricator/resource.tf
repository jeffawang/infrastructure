variable "ami" {}
variable "subnets" { type = "list" }
variable "env" { default = "dev" }
variable "security_groups" { type = "list" }
variable "key_name" {}
variable "vpc" {}

resource "aws_eip" "phabricator" {
    instance = "${aws_instance.phabricator.id}"
    vpc = true
}

resource "aws_instance" "phabricator" {
    ami = "${var.ami}"
    instance_type = "t2.small"
    subnet_id = "${var.subnets[0]}"
    vpc_security_group_ids = ["${var.security_groups}", "${aws_security_group.phabricator.id}", "${aws_security_group.phabricator-git-ssh.id}"]
    key_name = "${var.key_name}"
    tags {
        Name = "phabricator-${var.env}"
        Env = "${var.env}"
    }
    root_block_device {
        volume_type = "gp2"
        delete_on_termination = false
        volume_size = 20
    }
}

resource "aws_security_group" "phabricator" {
    name = "phabricator-${var.env}-http/s"
    description = "Allow http/s traffic"
    vpc_id = "${var.vpc}"
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "phabricator-git-ssh" {
    name = "phabricator-${var.env}-git-ssh"
    description = "Allow git ssh traffic on 2222"
    vpc_id = "${var.vpc}"
    ingress {
        from_port = 2222
        to_port = 2222
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

output "eip" { value = "${aws_eip.phabricator.public_ip}" }
output "private_ip" { value = "${aws_instance.phabricator.private_ip}" }
