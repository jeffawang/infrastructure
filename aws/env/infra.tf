resource "aws_vpc" "vpc" {
    cidr_block = "${var.cidr_block}"
    enable_dns_hostnames = true
    tags {
        Name = "${var.env}"
        Env = "${var.env}"
    }
}

resource "aws_key_pair" "key" {
    key_name = "${var.key_name}"
    public_key = "${var.public_key}"
}

resource "aws_internet_gateway" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "${var.env}"
        Env = "${var.env}"
    }
}

resource "aws_eip" "nat" {
    vpc = true
}

#resource "aws_nat_gateway" "nat" {
#    subnet_id = "${aws_subnet.public.*.id[count.index]}"
#    allocation_id = "${aws_eip.nat.id}"
#}

resource "aws_subnet" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "${var.availability_zones[count.index]}"
    cidr_block = "${cidrsubnet( aws_vpc.vpc.cidr_block, 8, count.index + length(var.availability_zones) )}"
    map_public_ip_on_launch = true
    count = "${length(var.availability_zones)}"
    tags {
        Name = "${var.env}-public-${var.availability_zones[count.index]}"
        Env = "${var.env}"
    }
    depends_on = [ "aws_internet_gateway.public" ]
}

resource "aws_subnet" "private" {
    vpc_id = "${aws_vpc.vpc.id}"
    availability_zone = "${var.availability_zones[count.index]}"
    cidr_block = "${cidrsubnet( aws_vpc.vpc.cidr_block, 8, count.index )}"
    map_public_ip_on_launch = false
    tags {
        Name = "${var.env}-private-${var.availability_zones[count.index]}"
        Env = "${var.env}"
    }
    #depends_on = [ "aws_nat_gateway.nat" ]
    count = "${length(var.availability_zones)}"
}

resource "aws_route_table" "private" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "${var.env}-private"
    }
#    route {
#        cidr_block = "0.0.0.0/0"
#        nat_gateway_id = "${aws_nat_gateway.nat.id}"
#    }
}

resource "aws_route_table_association" "private" {
    subnet_id = "${aws_subnet.private.*.id[count.index]}"
    route_table_id = "${aws_route_table.private.id}"
    count = "${length(var.availability_zones)}"
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags {
        Name = "${var.env}-public"
    }
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.public.id}"
    }
}

resource "aws_route_table_association" "public" {
    subnet_id = "${aws_subnet.public.*.id[count.index]}"
    route_table_id = "${aws_route_table.public.id}"
    count = "${length(var.availability_zones)}"
}

resource "aws_instance" "bastion" {
    ami = "${var.ami}"
    instance_type = "t2.nano"
    subnet_id = "${aws_subnet.public.*.id[0]}"
    key_name = "${aws_key_pair.key.key_name}"
    vpc_security_group_ids = ["${aws_security_group.public_ssh.id}"]
    tags {
        Name = "bastion-${var.env}"
        Role = "bastion"
        Env = "${var.env}"
    }
}

resource "aws_eip" "bastion" {
    vpc = true
    instance = "${aws_instance.bastion.id}"
}

resource "aws_security_group" "public_ssh" {
    name = "public-ssh-${var.env}"
    description = "Allow ssh from the world"
    vpc_id = "${aws_vpc.vpc.id}"
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "private" {
    name = "private-${var.env}"
    description = "Allow vpc traffic"
    vpc_id = "${aws_vpc.vpc.id}"
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["${aws_vpc.vpc.cidr_block}"]
        self = true
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        self = true
    }
}

resource "aws_route53_zone" "private" {
    name = "${var.env}.aws.jeffawang.com"
    vpc_id = "${aws_vpc.vpc.id}"
}

output "private_subnets" { value = ["${aws_subnet.private.*.id}"] }
output "public_subnets" { value = ["${aws_subnet.public.*.id}"] }
output "private_security_group" { value = "${aws_security_group.private.id}" }
output "bastion_ip" { value = "${aws_eip.bastion.public_ip}" }
output "vpc" { value = "${aws_vpc.vpc.id}" }
output "key_name" { value = "${aws_key_pair.key.key_name}" }
