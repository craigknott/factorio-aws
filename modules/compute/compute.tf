# ----------------------------------------
# This module configures compute resources
# ----------------------------------------

variable "name" {}
variable "tags" { type = "map" }
variable "vpc_id" {}
variable "region" {}
variable "az_count" { default = 3 }
variable "subnet_ids" { type = "list" }
variable "instance_type" { default = "t2.micro" }
variable "ami_release" { default = "trusty" }
variable "ssh_key" {}
variable "factorio_version" { default = "0.14.22" }
variable "game_name" { default = "current" }
variable "efs_fs_id" { default = "" }
variable "route53_zone" { default = "" }

# -------
# Storage
# -------
# I'd like to have these in their own module, but depends_on
# doesn't work across submodules.

resource "aws_security_group" "efs" {
    description = "Control EFS mount access for ${var.name}"
    vpc_id = "${var.vpc_id}"
    name = "${var.name}-efs"
    tags = "${merge(map("Name", "${var.name}-efs"), var.tags)}"
    ingress {
        protocol = "tcp"
        from_port = 2049
        to_port = 2049
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_efs_file_system" "efs" {
    count = "${var.efs_fs_id == "" ? 1 : 0}"
    tags = "${merge(map("Name", "${var.name}"), var.tags)}"
}

resource "aws_efs_mount_target" "efs" {
    count = "${var.efs_fs_id == "" ? var.az_count : 0}"
    file_system_id = "${aws_efs_file_system.efs.id}"
    subnet_id = "${element(var.subnet_ids, count.index)}"
    security_groups = ["${aws_security_group.efs.id}"]
}

# -------
# Compute
# -------

resource "aws_key_pair" "key" {
    key_name = "${var.name}"
    public_key = "${var.ssh_key}"
}

resource "aws_security_group" "instance" {
    description = "Controls access to application instances"
    vpc_id = "${var.vpc_id}"
    name = "${var.name}-instance"
    tags = "${merge(map("Name", "${var.name}-instance"), var.tags)}"
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
        fs_id = "${var.efs_fs_id == "" ? aws_efs_file_system.efs.id : var.efs_fs_id}"
        factorio_version = "${var.factorio_version}"
        game_name = "${var.game_name}"
    }
}

resource "aws_instance" "factorio" {
    key_name = "${aws_key_pair.key.key_name}"
    subnet_id = "${element(var.subnet_ids, 0)}"
    ami = "${module.ami.ami_id}"
    instance_type = "${var.instance_type}"
    associate_public_ip_address = true
    user_data = "${data.template_file.cloud_config.rendered}"
    security_groups = ["${aws_security_group.instance.id}"]
    lifecycle { create_before_destroy = true }
    depends_on = [
        "aws_efs_mount_target.efs",
        "aws_security_group.instance"
    ]
}

data "aws_route53_zone" "dns" {
    count = "${var.route53_zone == "" ? 0 : 1}"
    name = "${var.route53_zone}"
}

resource "aws_route53_record" "factorio" {
    count = "${var.route53_zone == "" ? 0 : 1}"
    zone_id = "${data.aws_route53_zone.dns.zone_id}"
    name = "${var.name}"
    type = "A"
    ttl = "300"
    records = ["${aws_instance.factorio.public_ip}"]
    depends_on = ["aws_instance.factorio"]
}

output "ip" {
    value = "${aws_instance.factorio.public_ip}"
}

output "dns" {
    value = "${var.name}.${data.aws_route53_zone.dns.name}"
}
