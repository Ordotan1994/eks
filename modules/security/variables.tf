variable "vpc_id"               { type = string }
variable "alb_sg_ingress_cidrs" { type = list(string) }
variable "tags"                 { type = map(string) }
variable "vpc_cidr"             { type = string }
