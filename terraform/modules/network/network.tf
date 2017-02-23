# -----------------------------------------
# This moudles creates networking resources
# -----------------------------------------

variable "name" {}
variable "tags" { type = "map" }
variable "vpc_cidr" {}
variable "domain_name" {}
variable "domain_name_servers" { type = "list" }
variable "ntp_servers" { type = "list" }
variable "create_vpn" { default = false }

module "vpc" {
    source = "./vpc"
    name = "${var.name}-vpc"
    cidr = "${var.vpc_cidr}"
    domain_name = "${var.domain_name}"
    domain_name_servers = "${var.domain_name_servers}"
    ntp_servers = "${var.ntp_servers}"
    create_vpn = "${var.create_vpn}"
    tags = "${var.tags}"
}