# -------------------------------------------
# This module creates public subnet resources
# -------------------------------------------

variable "name" {}
variable "tags" { type = "map" }
variable "vpc_id" {}
variable "cidr" {}
variable "az_count" { default = "3" }
variable "default_route_table_id" {}

data "aws_availability_zones" "available" {}

resource "aws_subnet" "public" {
    # Note.. Beta version of terraform allows this
    # count = "${length(data.aws_availability_zones.available.id)}"
    count = "${var.az_count}"
    vpc_id = "${var.vpc_id}"
    cidr_block = "${cidrsubnet(var.cidr, 8, count.index)}"
    availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
    map_public_ip_on_launch = true
    lifecycle {
        create_before_destroy = true
    }
    tags = "${merge(map("Name", "${var.name}-${data.aws_availability_zones.available.names[count.index]}"), var.tags)}"
}

resource "aws_internet_gateway" "public" {
    vpc_id = "${var.vpc_id}"
    tags = "${merge(map("Name", "${var.name}"), var.tags)}"
}

resource "aws_route_table" "public" {
    vpc_id = "${var.vpc_id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.public.id}"
    }
    tags = "${merge(map("Name", "${var.name}"), var.tags)}"
}

resource "aws_route_table_association" "public" {
    # Note.. Beta version of terraform allows this
    # count = "${length(data.aws_availability_zones.available.id)}"
    count = "${var.az_count}"
    subnet_id = "${element(aws_subnet.public.*.id, count.index)}"
    route_table_id = "${aws_route_table.public.id}" 
}

resource "aws_default_route_table" "unused" {
    default_route_table_id = "${var.default_route_table_id}"
    tags = "${merge(map("Name", "${var.name}-default-unsused"), var.tags)}"
    depends_on = ["aws_route_table_association.public"]
}