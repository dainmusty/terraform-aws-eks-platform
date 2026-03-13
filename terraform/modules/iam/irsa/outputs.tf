
 # Output for the ALB IRSA 
output "alb_controller_role_arn" {
  value = aws_iam_role.alb_controller_role.arn
}

output "argocd_role_arn" {
  value = aws_iam_role.argocd_role.arn
  
}

# Output for the Grafana IRSA
output "grafana_irsa_arn" {
  value = aws_iam_role.grafana_irsa.arn
}

# Output for the EBS CSI Driver IRSA
output "ebs_csi_role_arn" {
  value = aws_iam_role.ebs_csi_driver_role.arn
}

output "vpc_cni_irsa_role_arn" {
  value = aws_iam_role.vpc_cni_irsa_role.arn
  
}

