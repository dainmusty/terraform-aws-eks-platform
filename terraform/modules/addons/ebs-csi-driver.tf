resource "kubernetes_service_account_v1" "ebs_csi_controller" {
  metadata {
    name      = "ebs-csi-controller-sa" # EBS CSI Driver expects this exact name  for the controller service account
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = var.ebs_csi_role_arn
    }
  }
}


# Helm release for EBS CSI Driver
resource "helm_release" "ebs_csi_driver" {
  name             = "aws-ebs-csi-driver"
  namespace        = "kube-system"
  create_namespace = false

  repository = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart      = "aws-ebs-csi-driver"
  version    = "2.28.0"

  values = [
    yamlencode({
      controller = {
        serviceAccount = {
          create = false
          name   = kubernetes_service_account_v1.ebs_csi_controller.metadata[0].name
        }
      }
    })
  ]
  depends_on = [kubernetes_service_account_v1.ebs_csi_controller]
}




# resource "kubernetes_storage_class" "ebs_sc" {
#   metadata {
#     name = "ebs-sc"
#   }

#   provisioner          = "ebs.csi.aws.com"
#   reclaim_policy       = "Delete"
#   volume_binding_mode  = "WaitForFirstConsumer"
#   allow_volume_expansion = true
# }
