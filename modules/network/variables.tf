variable "vpc_cidr"             { type = string }
variable "azs"                  { type = list(string) }
variable "public_cidrs"         { type = list(string) }
variable "private_cidrs"        { type = list(string) }
variable "tags"                 { type = map(string) }
variable "region"               { type = string }
variable "security_group_ids"   { type = string }
variable "ssm_endpoints"        { type = map(string) }
variable "cluster_name"         { type = string }


