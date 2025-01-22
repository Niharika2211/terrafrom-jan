variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr_rng" {
  type    = string
  default = "192.0.0.0/16"
}

variable "pub_sub_cidr" {
  type    = list(string)
  default = ["192.0.1.0/24", "192.0.2.0/24"]
}

variable "pvt_sub_cidr" {
  type    = list(string)
  default = ["192.0.3.0/24", "192.0.4.0/24"]
}
variable "db_sub_cidr" {
  type    = list(string)
  default = ["192.0.5.0/24", "192.0.6.0/24"]
}

variable "enable_dns_hostnames" {
  type    = bool
  default = true
}

variable "envirnoment" {
  type    = string
  default = "prod"
}

variable "project-name" {
  type    = string
  default = "mini"
}

variable "common_tags" {
  type = map(any)
  default = {
    "owner"        = "niha"
    "terraform"    = true
    "project_name" = "expense"
    "environment"  = "dev"
  }
}

variable "nat_enable" {
  type    = bool
  default = true
}