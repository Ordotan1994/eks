variable "vpc_id"      { type = string }
variable "subnet_ids"  { type = list(string) }
variable "alb_sg_id"   { type = string }
variable "target_port" { type = number }
variable "tags"        { type = map(string) }
