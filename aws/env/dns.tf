resource "aws_route53_zone" "public" {
    name = "aws.jeffawang.com."
    delegation_set_id = "${aws_route53_delegation_set.public.id}"
}

resource "aws_route53_delegation_set" "public" {
}
