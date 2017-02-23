# ----------------------------------------
# This module configures compute resources
# ----------------------------------------

variable "name" {}
variable "tags" { type = "map" }
variable "vpc_id" {}
variable "region" {}
variable "subnet_ids" { type = "list" }
variable "instance_type" { default = "t2.micro" }
variable "efs_id" {}
variable "ami_release" { default = "trusty" }
variable "ssh_key" {}
variable "factorio_version" { default = "0.14.22" }
variable "game_name" { default = "current" }

resource "aws_key_pair" "key" {
    key_name = "${var.name}"
    public_key = "${var.ssh_key}"
}

resource "aws_security_group" "instance" {
    description = "Controls access to application instances"
    vpc_id = "${var.vpc_id}"
    name = "${var.name}-instance"
    tags = "${var.tags}"
    ingress {
        protocol = "tcp"
        from_port = 22
        to_port = 22
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        protocol = "udp"
        from_port = 34197
        to_port = 34197
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

module "ami" {
    source = "github.com/terraform-community-modules/tf_aws_ubuntu_ami/ebs"
    instance_type = "${var.instance_type}"
    region = "${var.region}"
    distribution = "${var.ami_release}"
}

data "template_file" "cloud_config" {
    template = "${file("${path.module}/cloud-config.yml")}"
    vars {
        aws_region = "${var.region}"
        fs_id = "${var.efs_id}"
        factorio_version = "${var.factorio_version}"
        game_name = "${var.game_name}"
    }
}

resource "aws_instance" "factorio" {
    ami = "${module.ami.ami_id}"
    instance_type = "${var.instance_type}"
    subnet_id = "${element(var.subnet_ids, 0)}"
    key_name = "${aws_key_pair.key.key_name}"
    vpc_security_group_ids = [ "${aws_security_group.instance.id}" ]
    associate_public_ip_address = true
    user_data = "${data.template_file.cloud_config.rendered}"
    tags = "${merge(map("Name", "${var.name}"), var.tags)}"
    lifecycle { create_before_destroy = true }
}