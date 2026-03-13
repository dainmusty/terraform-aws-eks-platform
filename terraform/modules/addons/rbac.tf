# resource "kubernetes_cluster_role_binding_v1" "terraform_admin" {
#   metadata {
#     name = "terraform-admin"
#   }

#   subject {
#     kind      = "Group"
#     name      = "system:masters"
#     api_group = "rbac.authorization.k8s.io"
#   }

#   role_ref {
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#     api_group = "rbac.authorization.k8s.io"
#   }
# }
