output "cluster_sg_id" {
  description = "The ID of the private security group"
  value       = aws_security_group.cluster_sg.id
}
