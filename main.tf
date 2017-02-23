variable "name" {}
variable "aws_access_key" { default = "" }
variable "aws_secret_key" { default = "" }
variable "tags" { type = "map" }
variable "region" {}
variable "vpc_cidr" {}
variable "ntp_servers" { type = "list" }
variable "ssh_key" {}
variable "efs_id" { default = "" }
variable "route53_zone" { default = "" }

provider "aws" {
    region = "${var.region}"
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
}

module "network" {
    source              = "./modules/network"
    name                = "${var.name}"
    tags                = "${var.tags}"
    vpc_cidr            = "${var.vpc_cidr}"
    ntp_servers         = "${var.ntp_servers}"
}

module "compute" {
    source = "./modules/compute"
    name = "${var.name}"
    tags = "${var.tags}"
    region = "${var.region}"
    vpc_id = "${module.network.vpc_id}"
    subnet_ids = "${module.network.subnet_ids}"
    ssh_key = "${var.ssh_key}"
    efs_fs_id = "${var.efs_id}"
    route53_zone = "${var.route53_zone}"
}

output "ip" {
    value = "${module.compute.ip}"
}

output "dns" {
    value = "${module.compute.dns}"
}
