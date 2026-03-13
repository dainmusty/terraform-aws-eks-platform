
output "eks_access_entry" {
  description = "output for eks access entry"
  value = aws_eks_access_entry.terraform.id
}
