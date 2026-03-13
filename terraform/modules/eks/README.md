Yes — the way you’re getting the OIDC issuer is correct, but let’s verify the format and common pitfalls.

1️⃣ How Terraform outputs it:
output "oidc_provider_url" {
  value = aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer
}


This returns something like:

https://oidc.eks.us-east-1.amazonaws.com/id/7A2C6AB51D3637BC07FA403A62BA82F9


✅ This is expected. It includes https://.

2️⃣ What AWS IAM expects in the trust policy:

For IRSA, the Principal condition must not include https:// when referencing the issuer for :sub and :aud conditions.

So in Terraform, we must strip it when creating the role policy:

locals {
  oidc_provider_id = replace(aws_eks_cluster.dev_cluster.identity[0].oidc[0].issuer, "https://", "")
}


Then in the IAM policy:

variable = "${local.oidc_provider_id}:sub"
values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]

3️⃣ How to double-check from CLI:
aws eks describe-cluster --name effulgencetech-dev --query "cluster.identity.oidc.issuer" --output text


Should return something like:

https://oidc.eks.us-east-1.amazonaws.com/id/7A2C6AB51D3637BC07FA403A62BA82F9


✅ If it matches your Terraform output, the cluster is correct.

⚠️ Only thing to fix is removing https:// when building the IAM trust policy.


✅ The ONE missing piece (minimal & modern)

You need one Kubernetes ClusterRoleBinding that maps your role to cluster-admin.

🔐 Create this ONCE (recommended via Terraform or kubectl)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: terraform-admin
subjects:
  - kind: User
    name: arn:aws:iam::651706774390:role/microservices-project-dev-tf-role
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io


Apply with:

kubectl apply -f clusterrolebinding.yaml

🎯 What happens immediately after

AWS Console:

Pods ✔

Nodes ✔

Services ✔

ConfigMaps ✔

kubectl works

No aws-auth ConfigMap

No legacy mappings

Fully modern EKS access model

🔥 Important best-practice note (you’re doing it right)

Your setup now follows AWS’s recommended 2024+ model for Amazon EKS:

✔ IAM Access Entries
✔ No aws-auth dependency
✔ Explicit RBAC bindings
✔ Clean separation of infra vs access

🧠 Final mental model (remember this)

IAM Access Entry = who may authenticate
Kubernetes RBAC = what they may see/do

Both are required.

so should i depends on eks access entry to the rbac block below so that the eks access entry is created before the Bootstrap Kubernetes RBAC (once)
resource "kubernetes_cluster_role_binding_v1" "terraform_admin" {
  metadata {
    name = "terraform-admin"
  }

  subject {
    kind      = "User"
    name      = var.terraform_role_arn
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}

Short answer: YES — but do it carefully 👍
Long answer below so you don’t create a circular-dependency trap (very common with EKS).

✅ Should RBAC depend on the EKS access entry?

Yes, conceptually:

EKS Access Entry must exist first, otherwise Kubernetes will not recognize the IAM principal and RBAC will fail with Unauthorized.

So this ordering is correct:

EKS Cluster
→ EKS Access Entry
→ Kubernetes RBAC (ClusterRoleBinding)
→ Addons / Helm / Namespaces

⚠️ The important caveat (this is where people get stuck)

Terraform cannot automatically infer this ordering because:

aws_eks_access_entry is AWS-side

kubernetes_cluster_role_binding_v1 is Kubernetes-side

They use different providers

So you must explicitly wire the dependency.

✅ Correct RBAC block (with dependency)
resource "kubernetes_cluster_role_binding_v1" "terraform_admin" {
  metadata {
    name = "terraform-admin"
  }

  subject {
    kind      = "User"
    name      = var.terraform_role_arn
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }

  depends_on = [
    aws_eks_access_entry.terraform
  ]
}


✔️ This guarantees:

IAM role is registered with EKS

Kubernetes API recognizes the caller

RBAC creation succeeds

🧠 Why this works (important mental model)

EKS Access Entry = “Who are you?”

RBAC = “What are you allowed to do?”

RBAC cannot succeed unless EKS already knows the principal.

🚨 One more critical rule (DO NOT skip this)
The Kubernetes provider must authenticate as the same role

Your provider must use get-token with the Terraform role:

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(
    data.aws_eks_cluster.this.certificate_authority[0].data
  )

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks", "get-token",
      "--cluster-name", var.cluster_name,
      "--role-arn", var.terraform_role_arn
    ]
  }
}


If:

AWS provider uses the role

Kubernetes provider does not

➡️ You will still get Unauthorized

🧨 Avoid this common mistake

❌ Do NOT put this RBAC resource in the same module as cluster creation unless:

Access entry is already created

Provider is configured correctly

Best practice (what you’re already drifting toward 👌)


#RBAC in K8s - We don't need if we are using eks access entries
resource "kubernetes_cluster_role_binding_v1" "terraform_admin" {
  metadata {
    name = "terraform-admin"
  }

  subject {
    kind      = "Group"
    name      = "system:masters"
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = "cluster-admin"
    api_group = "rbac.authorization.k8s.io"
  }
}
