# -----------------------------------------
# This moudles creates networking resources
# -----------------------------------------

variable "name" {}
variable "tags" { type = "map" }
variable "vpc_cidr" {}
variable "domain_name" {}
variable "domain_name_servers" { type = "list" }
variable "ntp_servers" { type = "list" }
variable "az_count" { default = "3" }

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags = "${merge(map("Name", "${var.name}"), var.tags)}"
  lifecycle { create_before_destroy = true }
}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
    # Note.. Beta version of terraform allows this
    # count = "${length(data.aws_availability_zones.available.id)}"
    count                   = "${var.az_count}"
    vpc_id                  = "${aws_vpc.vpc.id}"
    cidr_block              = "${cidrsubnet(var.vpc_cidr, 8, count.index)}"
    availability_zone       = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = true
    tags                    = "${merge(map("Name", "${var.name}-${data.aws_availability_zones.available.names[count.index]}"), var.tags)}"
    lifecycle { create_before_destroy = true }
}

resource "aws_internet_gateway" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags   = "${merge(map("Name", "${var.name}"), var.tags)}"
}

resource "aws_route_table" "public" {
    vpc_id = "${aws_vpc.vpc.id}"
    tags   = "${merge(map("Name", "${var.name}"), var.tags)}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.public.id}"
    }
}

resource "aws_route_table_association" "public" {
    # Note.. Beta version of terraform allows this
    # count = "${length(data.aws_availability_zones.available.id)}"
    count          = "${var.az_count}"
    subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id = "${aws_route_table.public.id}" 
}

resource "aws_default_route_table" "unused" {
    default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
    tags = "${merge(map("Name", "${var.name}-default-unsused"), var.tags)}"
    depends_on = ["aws_route_table_association.public"]
}

output "vpc_id" {
    value = "${aws_vpc.vpc.id}"
}

output "subnet_ids" {
    value = ["${aws_subnet.public.*.id}"]
}