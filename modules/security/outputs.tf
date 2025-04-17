output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "eks_sg_id" {
  value = aws_security_group.eks.id
}

output "endpoints_sg_id" {
  value = aws_security_group.endpoints.id
}
