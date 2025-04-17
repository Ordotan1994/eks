variable "region" { type = string }
variable "az_count" { type = string }
variable "vpc_cidr" { type = string }
variable "public_cidrs" { type = list(string) }
variable "private_cidrs" { type = list(string) }

variable "cluster_name" { type = string }
variable "node_instance_type" { type = string }
variable "desired_capacity" { type = number }
variable "min_capacity" { type = number }
variable "max_capacity" { type = number }
variable "grafana_domain" { type = string }
  

variable "tags" {
  type    = map(string)
  default = {}
}

variable "grafana_admin_password" {
  type      = string
  sensitive = true
}
