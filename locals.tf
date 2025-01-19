locals {
  name = "${var.envirnoment}-${var.project-name}"
}


data "aws_vpc" "selected" {
  default = true
}