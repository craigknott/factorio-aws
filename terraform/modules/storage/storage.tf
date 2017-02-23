# -------------------------------------
# This module creates storage resources
# -------------------------------------

variable "name" {}
variable "tags" { type = "map" }
variable "vpc_id" {}
variable "subnet_ids" { type = "list" }
variable "az_count" { default = "3" }
variable "efs_fs_id" { default = "" }

resource "aws_security_group" "efs" {
    description = "Control EFS mount access for ${var.name}"
    vpc_id      = "${var.vpc_id}"
    tags        = "${var.tags}"
    ingress {
        protocol    = "tcp"
        from_port   = 2049
        to_port     = 2049
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_efs_file_system" "efs" {
    count = "${var.efs_fs_id == "" ? 1 : 0}"
    tags  = "${var.tags}"
}

resource "aws_efs_mount_target" "efs" {
    count = "${var.az_count}"
    file_system_id = "${aws_efs_file_system.efs.id}"
    subnet_id = "${element(var.subnet_ids, count.index)}"
    security_groups = ["${aws_security_group.efs.id}"]
}