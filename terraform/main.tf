variable "name" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "tags" { type = "map" }
variable "region" {}
variable "vpc_cidr" {}
variable "domain_name" {}
variable "domain_name_servers" { type = "list" }
variable "ntp_servers" { type = "list" }

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
    domain_name         = "${var.domain_name}"
    domain_name_servers = "${var.domain_name_servers}"
    ntp_servers         = "${var.ntp_servers}"
}