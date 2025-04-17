variable "cluster_name"           { type = string }
variable "grafana_admin_password" { type = string }
variable "grafana_domain"         { type = string }   # leave empty to use ALB DNS
variable "tags"                   { type = map(string) }
variable "oidc"                   { type = string }
variable "region"                 { type = string }
variable "vpc_id"                { type = string }
