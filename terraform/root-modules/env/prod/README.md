# Smooth teardown of terraform resources
how can i setup my terraform to delete all resources without any errors like the one below so that it can delete smoothly automatically so that i don't have to type terraform destroy again?

│ Warning: Helm uninstall returned an information message
│
│ These resources were kept due to the resource policy:
│ [CustomResourceDefinition] applications.argoproj.io
│ [CustomResourceDefinition] applicationsets.argoproj.io
│ [CustomResourceDefinition] appprojects.argoproj.io
│
╵
╷
│ Error: uninstallation completed with 1 error(s): context deadline exceeded
│
│
╵
╷
│ Error: context deadline exceeded
│

Great question — this is a very common (and solvable) Terraform + Helm teardown problem. You’re hitting expected Helm behavior, not a Terraform bug.

I’ll explain why this happens, then give you a clean, production-safe teardown design so terraform destroy works once, end-to-end, without reruns.

Why your destroy is failing (what’s really happening)

You’re seeing:

These resources were kept due to the resource policy:
[CustomResourceDefinition] applications.argoproj.io
...
Error: context deadline exceeded


This happens because:

1️⃣ Helm charts (Argo CD, Prometheus, ALB Controller) install CRDs

CRDs are cluster-scoped

Many charts mark them with:

helm.sh/resource-policy: keep


Helm refuses to delete them on uninstall

2️⃣ Terraform waits for Helm → Helm waits for Kubernetes → deadlock

Helm waits for cleanup that will never happen

Terraform hits timeout → context deadline exceeded

Destroy stops halfway

This is normal Helm behavior unless you design around it.

The correct solution (what professionals do)

You need three explicit design rules:

✅ Rule 1 — Manage CRDs OUTSIDE Helm

Helm should never own CRDs if you want clean destroys.

Do this instead:

Install CRDs once

Manage them via:

Terraform kubernetes_manifest

Or raw YAML

Or a separate Helm release with skip_crds = false (advanced)

Example (recommended)
resource "kubernetes_manifest" "argocd_crds" {
  for_each = fileset("${path.module}/crds/argocd", "*.yaml")
  manifest = yamldecode(file("${path.module}/crds/argocd/${each.value}"))
}


Then in Helm:

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  skip_crds = true   # 🔑 critical
}


✅ Helm installs apps
✅ Terraform controls CRDs
✅ Destroy works cleanly

✅ Rule 2 — Increase Helm destroy timeouts (mandatory)

Some controllers take minutes to shut down.

resource "helm_release" "argocd" {
  name = "argocd"

  timeout         = 900
  wait            = true
  cleanup_on_fail = true
  atomic          = true
}


Do this for:

Argo CD

kube-prometheus-stack

AWS Load Balancer Controller

✅ Rule 3 — Explicit destroy order (this matters)

Controllers must die before:

Namespaces

RBAC

Cluster

Pattern to use
module "addons" {
  source = "../addons"

  depends_on = [
    module.eks_access,   # IAM auth first
    kubernetes_cluster_role_binding_v1.admin
  ]
}


Inside addons:

resource "helm_release" "argocd" {
  depends_on = [
    kubernetes_namespace_v1.argocd
  ]
}


Terraform will now destroy in reverse order safely.

OPTIONAL but highly recommended safeguards
🧹 Auto-clean namespaces on destroy
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }

  lifecycle {
    prevent_destroy = false
  }
}

🧹 Ignore Helm CRD leftovers (last-resort safety net)
resource "helm_release" "argocd" {
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["helm.sh/resource-policy"]
    ]
  }
}

What NOT to do ❌

❌ Rely on Helm to clean CRDs
❌ Use terraform destroy -target regularly
❌ Manually delete CRDs after every destroy
❌ Mix EKS access bootstrap with addon lifecycle

The clean teardown flow you want
terraform destroy
 ├─ helm_release addons (wait + timeout)
 ├─ kubernetes namespaces
 ├─ RBAC
 ├─ EKS access entries
 ├─ Node groups
 └─ EKS cluster


One command. No retries. No force. No panic.