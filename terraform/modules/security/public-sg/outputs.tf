output "node_sg_id" {
  description = "The ID of the public security group"
  value       = aws_security_group.node_sg.id
}
