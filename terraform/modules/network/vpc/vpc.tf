# -------------------------------------
# This module creates all VPC resources
# -------------------------------------

variable "name" {}
variable "cidr" {}
variable "create_vpn" { default = false }
variable "tags" { type = "map" }
variable "domain_name" {}
variable "domain_name_servers" { type = "list" }
variable "ntp_servers" { type = "list" }

resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr}"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = "${merge(map("Name", "${var.name}"), var.tags)}"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_dhcp_options" "dhcp_options" {
  domain_name = "${var.domain_name}"
  domain_name_servers = "${var.domain_name_servers}"
  ntp_servers = "${var.ntp_servers}"
  tags = "${merge(map("Name", "${var.name}"), var.tags)}"
}

resource "aws_vpc_dhcp_options_association" "dhcp_options" {
  vpc_id = "${aws_vpc.vpc.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.dhcp_options.id}"
}

resource "aws_vpn_gateway" "vpn" {
  count = "${var.create_vpn ? 1 : 0}"
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${merge(map("Name", "${var.name}"), var.tags)}"
}

output "vpn_gateway_id" {
  value = "${aws_vpn_gateway.vpn.id}"
}

output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "vpc_cidr" {
  value = "${aws_vpc.vpc.cidr_block}"
}

output "vpc_default_network_acl_id" {
  value = "${aws_vpc.vpc.default_network_acl_id}"
}

output "vpc_default_route_table_id" {
  value = "${aws_vpc.vpc.default_route_table_id}"
}