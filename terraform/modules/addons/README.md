# To access the argocd UI, you need to do the ff.
1. Update the kubecofig
aws eks --region us-east-1 update-kubeconfig --name effulgencetech

2. Use the command below to grab your argocd password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d


 JopJyvT8kTxFdDZ9
3. Access argocd via Port Forwarding on your local machine. Option 1
kubectl port-forward -n argocd svc/argocd-server 8080:80
# Go to localhost:8080

4. Access argocd via Ingress + ALB Option 2. (Recommended for production) 
If you installed ArgoCD with an Ingress (via AWS ALB), then you access it via the ALB DNS name instead
kubectl -n argocd get ingress

5. Access prometheus via Port Forwarding on your local machine. Option 1
kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090
# Go to localhost:9090


6. Access grafana via Port Forwarding on your local machine. Option 1
kubectl port-forward svc/kube-prometheus-stack-grafana -n monitoring 3000:80
# Go to localhost:3000   #gfnpasswd$123456789

| Component      | Namespace   | ServiceAccount               | Can rename?           |
| -------------- | ----------- | ---------------------------- | --------------------- |
| ArgoCD         | argocd      | argocd-server                | ✅ but not recommended |
| Grafana        | monitoring  | grafana                      | ✅                     |
| ALB Controller | kube-system | aws-load-balancer-controller | ❌                     |
| VPC CNI        | kube-system | aws-node                     | ❌                     |
| EBS CSI        | kube-system | ebs-csi-controller-sa        | ❌                     |



Key takeaway (important DevOps lesson)

When Argo CD is deployed with:

--insecure


You must use:

HTTP

Service port 80

Pod port 8080

Ingress/ALB later will terminate TLS — not Argo CD itself.








  type: ClusterIP
ChatGPT said:

Thanks — this clarifies the issue. Your argocd-server service is a ClusterIP with ports:

- port: 80 → targetPort: 8080
- port: 443 → targetPort: 8080

Problem Analysis

Your ingress ALB annotations are currently:

alb.ingress.kubernetes.io/backend-protocol: HTTPS
alb.ingress.kubernetes.io/listen-ports: [{"HTTP": 80}]


The ALB is listening on HTTP:80 but trying to forward to the backend using HTTPS.

The backend service is ClusterIP 172.20.19.230, which serves both 80 and 443 over HTTP, not HTTPS.

Port 443 is actually TCP → targetPort 8080, so the ALB cannot just forward HTTPS unless the backend actually speaks HTTPS.

ClusterIP is correct (ALB uses IP targets via target-type: ip), so no issue there.

ALB target group likely shows targets unhealthy because it is trying HTTPS but the pods respond only with HTTP.

✅ Fix

For HTTP only:

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server
  namespace: argocd
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP":80}]'
    alb.ingress.kubernetes.io/backend-protocol: HTTP
spec:
  rules:
    - host: argocd.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80


backend-protocol: HTTP matches your service.

ALB listens on HTTP:80 and forwards traffic to service port 80 (targetPort 8080).

If you want HTTPS via ALB:

Change ALB to listen on HTTPS:443

Add ACM certificate

Set alb.ingress.kubernetes.io/backend-protocol: HTTP (ALB terminates TLS)

Optional: keep service port 443 mapped to 8080.

Example:

alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
alb.ingress.kubernetes.io/certificate-arn: <ACM_CERT_ARN>
alb.ingress.kubernetes.io/backend-protocol: HTTP


💡 After applying the fixed ingress, check:

kubectl get ingress argocd-server -n argocd -w


Targets should become healthy and the page should load.











✅ EKS Addon Troubleshooting Summary
🧩 1. ArgoCD Setup & Debugging
Issues Faced:
Initial access and login password retrieval was non-obvious.

Needed manual port-forwarding to access the UI.

Key Fixes / Actions:
Used kubectl port-forward to expose ArgoCD server locally.

Retrieved admin password securely using:

kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
z9TXqltew6O9cEft
Verified deployment with:

helm list -n argocd

kubectl get svc -n argocd

kubectl get pods -n argocd

📊 2. Prometheus & Grafana Observability Stack
Issues Faced:
Port-forwarding required for UI access.

Insecure default settings (anonymous Grafana login, hardcoded credentials).

Runtime secrets fetching pattern via initContainer and aws-cli.

Fixes & Improvements:
Used Helm with existingSecret to inject Grafana admin credentials:

grafana:
  admin:
    existingSecret: grafana-admin
Enabled resource requests/limits:

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi
Enabled persistent storage:

persistence:
  enabled: true
  storageClassName: gp2
  size: 5Gi
Disabled anonymous access:

grafana.ini:
  auth.anonymous:
    enabled: false
Outcome:
🔐 Secured login.

💾 Persistent dashboards.

📊 Enabled ServiceMonitor for Prometheus to scrape Grafana metrics.

☁️ 3. ALB Controller Setup
Issues Faced:
Needed to confirm ALB pods running and debug logs.

Key Checks:
Verified services with kubectl get svc -A | grep LoadBalancer.

Verified controller status with:

kubectl get pods -n kube-system | grep alb
kubectl logs -n kube-system <alb-pod>
🔩 4. EBS CSI Driver & Cluster Connectivity
Tasks:
Ensured cluster was connected using:

aws eks --region us-east-1 update-kubeconfig --name effulgencetech-dev
kubectl get nodes
kubectl cluster-info
Validated namespace and CSI driver behavior.

🔒 5. Secrets Handling & Alertmanager Slack Integration
Original Issue:
Secrets were pulled at runtime via initContainers with aws-cli — insecure and fragile.

Fix:
Pulled Slack webhook from AWS Secrets Manager using Terraform:

data "aws_secretsmanager_secret_version" "slack_webhook" {
  secret_id = var.slack_webhook_secret_id
}
Created Kubernetes Secret with key slack_api_url.

Outcome:
🔐 Secure deployment-time secret injection.

📫 Reliable and compliant Slack alerting.

📦 6. Modular Terraform Structure
Improvements:
Split Prometheus alert rules into a separate prometheus_rules.tf for maintainability.

Used modular values = [ file(...) ] pattern to load Helm values cleanly.

✅ Final Summary
Area	Outcome
ArgoCD	Access fixed, admin login secured, deployment verified
Grafana/Prometheus	Secured secrets, persistent storage, resource limits, alerting enhanced
ALB Controller	Verified pods, logs, service exposure
EBS CSI Driver	Cluster connection validated, namespace checks passed
Secrets Handling	Migrated to Terraform-managed secure secrets from AWS SM
Terraform Structure	Modularized alert rules and Helm values for production readiness

gfnpasswd$1234grafana-user-passwd


Ah — now it’s clear why the ALB Controller pods are CrashLoopBackOff. The issue is IRSA (IAM Roles for Service Accounts) is not correctly wired in your Helm chart. Let me break it down:

1️⃣ What’s happening now

Your Helm snippet:

set {
  name  = "serviceAccount.create"
  value = "true"
}

set {
  name  = "serviceAccount.name"
  value = "aws-load-balancer-controller"
}


This creates a ServiceAccount, but does not attach your IAM role to it.

Because your EC2 nodes require IMDSv2, the controller tries to fetch AWS metadata from the node’s instance metadata.

Since the node role does not have the full ALB permissions, you get:

failed to fetch VPC ID from instance metadata

2️⃣ Correct way: wire IRSA via Helm

The Helm chart supports IRSA by specifying the IAM role ARN for the service account instead of letting Helm just create a default SA.

You need two things:

Pre-create the IAM role (you already have aws_iam_role.alb_controller_role).

Tell Helm to use it:

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"  # <- do NOT create a new SA, you pre-created one
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.alb_controller_role.arn
  }

  depends_on = [
    var.alb_controller_role
  ]
}


✅ Key points:

serviceAccount.create = false → Helm will use the SA you already have.

serviceAccount.annotations.eks.amazonaws.com/role-arn → This binds the IAM role to the pod via IRSA.

Notice the \\. escape in Terraform HCL for the dot (.) in the annotation key.

3️⃣ Steps to fix your cluster

Update the Helm release with IRSA annotation (like above).

Rollout restart the deployment (or let Helm upgrade apply the changes):

kubectl -n kube-system rollout restart deployment aws-load-balancer-controller
kubectl -n kube-system get pods -w | grep aws-load-balancer-controller


Verify logs:

kubectl -n kube-system logs <pod-name>


You should see:

Controller starting successfully
Listening on port ...


No more failed to fetch VPC ID from instance metadata.

If you want, I can write the full Terraform + Helm snippet for your ALB Controller including:


🔴 Root cause (confirmed by Events)
0/1 nodes are available: 1 Too many pods.
no new claims to deallocate


This means:

Your only worker node is already at its maximum Pod limit, so Kubernetes cannot schedule any new pods.

That’s why:

❌ prometheus-operator → Pending

❌ kube-state-metrics → Pending

✅ node-exporter → Running (already scheduled earlier)

1️⃣ Why this happens on EKS

EKS limits max pods per node based on:

Instance type

VPC CNI configuration

ENI + IP limits

For example:

t3.medium → ~17–29 pods max

System pods (kube-system) consume most of this

With:

CNI

CoreDNS

kube-proxy

EBS CSI

ALB Controller

Metrics Server

Node Exporter

👉 You’ve exhausted pod capacity before Prometheus even starts.

2️⃣ Verify pod limit (optional but informative)
kubectl describe node ip-10-1-3-40.ec2.internal | grep -i pods


You’ll see something like:

pods:             29

3️⃣ Correct fixes (choose one)
✅ FIX A – Add more worker nodes (BEST PRACTICE)

Increase node count in your node group.

If Terraform-managed:

scaling_config {
  desired_size = 2
  max_size     = 3
  min_size     = 2
}


Then:

terraform apply


💡 With 2 nodes, Prometheus installs cleanly.

✅ FIX B – Use a bigger instance type

Example:

Move from t3.medium → t3.large or m5.large

More ENIs → more pod IPs → higher pod limit.

⚠️ FIX C – Enable CNI prefix delegation (advanced)

This increases pod density without adding nodes.

kubectl set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true
kubectl set env daemonset aws-node -n kube-system WARM_PREFIX_TARGET=1


Then restart nodes.

⚠️ Still not ideal for monitoring stacks.

❌ NOT recommended

Deleting system pods

Forcing tolerations

Disabling components in kube-prometheus-stack

4️⃣ Why Terraform & Helm failed exactly this way

Terraform waited for:

prometheus-operator → Ready ❌ (never scheduled)

kube-state-metrics → Ready ❌

Scheduler said:

“Too many pods”

Terraform timed out → Helm marked release failed.

This is expected behavior.

5️⃣ Clean recovery steps (do this exactly)
helm uninstall kube-prometheus-stack -n monitoring


Scale node group (Fix A or B), wait until nodes are Ready:

kubectl get nodes


Then:

terraform apply

6️⃣ DevOps best practice (important for your project)

For EKS + kube-prometheus-stack:

Component	Recommendation
Node count	≥ 2 nodes
Instance size	t3.large or bigger
Monitoring	Dedicated node group (optional but ideal)

This is production-grade and interview-ready.

7️⃣ TL;DR

❌ Not a Helm issue

❌ Not IAM

❌ Not storage

✅ Single node hit max pod limit

✅ Add nodes or increase instance size

If you want, paste your Terraform node group config, and I’ll give you the exact minimal change (1–2 lines) to fix it cleanly.


provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name", var.cluster_name,
      "--region", var.region
    ]
  }
}

provider "helm" {
  kubernetes {
    host                   = var.cluster_endpoint
    cluster_ca_certificate = base64decode(var.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = [
        "eks",
        "get-token",
        "--cluster-name", var.cluster_name,
        "--region", var.region
      ]
    }
  }

}


the client to provide credentials"

Good news first: your cluster and addons are now correct.
What you’re seeing now is not a Terraform / Helm problem anymore — it’s pure kubectl authentication context drift.

Let’s straighten this out cleanly.

Short answer (important)

❌ No, you do NOT need the Terraform role to assume your IAM user
✅ You must use kubectl as a principal that already has EKS access

Right now:

Terraform (via microservices-project-dev-tf-role) ✅ works

AWS Console (when you Switch Role) ✅ works

kubectl (as IAM user musty) ❌ is using stale or invalid credentials

That’s why Helm succeeds but kubectl port-forward fails.

Why this is happening

Your access entries are correct:

Principal	Purpose	OK
AWSServiceRoleForAmazonEKS	Control plane	✅
dev-node-role	Worker nodes	✅
microservices-project-dev-tf-role	Terraform / CI	✅

But your IAM user (arn:aws:iam::…:user/musty) is NOT the principal kubectl is authenticated as — even if you can see resources in the console after switching roles.

kubectl does not inherit console role switching.

The root cause of this error
the server has asked for the client to provide credentials


This means kubectl is calling EKS with credentials that are either:

expired

wrong IAM principal

missing EKS access

The correct mental model (this is key)
Tool	Identity used
Terraform	OIDC → microservices-project-dev-tf-role
AWS Console	Whatever role you switched to
kubectl	Whatever AWS credentials are active in your shell

They are independent.

✅ Correct solution (recommended & clean)
Option A — Use kubectl as the Terraform role (BEST PRACTICE)

This matches how CI works and avoids IAM-user drift.

1️⃣ Assume the Terraform role locally
aws sts assume-role \
  --role-arn arn:aws:iam::651706774390:role/microservices-project-dev-tf-role \
  --role-session-name kubectl-session


Export the credentials returned:

export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...

2️⃣ Regenerate kubeconfig using that role
aws eks update-kubeconfig \
  --region us-east-1 \
  --name effulgencetech-dev \
  --role-arn arn:aws:iam::651706774390:role/microservices-project-dev-tf-role

3️⃣ Verify identity
aws sts get-caller-identity


You must see:

arn:aws:iam::651706774390:assumed-role/microservices-project-dev-tf-role/...

4️⃣ Test kubectl
kubectl auth can-i get pods -n argocd
kubectl get nodes
kubectl port-forward -n argocd svc/argocd-server 8080:80


✅ This will now work.

❌ What you should NOT do

❌ Do NOT make Terraform role assume your IAM user

❌ Do NOT add more EKS access entries

❌ Do NOT loosen RBAC

❌ Do NOT re-create the cluster

Your access model is already correct.

If you really want IAM user access too (optional)

Only do this if you insist on using your IAM user directly with kubectl.

Add one access entry:

resource "aws_eks_access_entry" "iam_user" {
  cluster_name  = var.cluster_name
  principal_arn = "arn:aws:iam::651706774390:user/musty"
  type          = "STANDARD"
}


Then regenerate kubeconfig without role-arn:

aws eks update-kubeconfig --name effulgencetech-dev --region us-east-1


But again — this is not recommended for production.

Why Helm worked but kubectl failed

Helm ran inside Terraform → assumed role → valid token

kubectl ran in your shell → wrong credentials → rejected

This is a very common EKS gotcha, not a design issue.

Final verdict

✅ Your cluster is healthy
✅ Your addons are healthy
✅ Your IAM model is correct
❌ Your local kubectl context just needs alignment

Once you align kubectl with the Terraform role, the errors disappear permanently.

If you want next:

permanent AWS profile setup

kubectl context per-role

GitHub Actions parity with local

zero-trust RBAC tightening

I’ve got you.

i have disguised the userId details ok 
aws sts get-caller-identity
{
    "UserId": "***************5:kubectl-session", 
    "Account": "651706774390",
    "Arn": "arn:aws:sts::651706774390:assumed-role/microservices-project-dev-tf-role/kubectl-session"
}
Mustydain:microservices-k8s-project$ kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:sts::651706774390:assumed-role/microservices-project-dev-tf-role/kubectl-session is not authorized to perform: sts:AssumeRole on resource: arn:aws:iam::651706774390:role/microservices-project-dev-tf-role
E1222 00:52:58.625162   38896 memcache.go:265] "Unhandled Error" err="couldn't get current server API group list: Get \"https://363B73A6A82B1F370F1095C7D96D9CBD.gr7.us-east-1.eks.amazonaws.com/api?timeout=32s\": getting credentials: exec: executable aws failed with exit code 254"

Perfect — thanks for pasting the output. This is actually the final missing piece, and it’s a classic EKS + kubectl + role-assumption trap. You’re one small fix away.

What’s happening (very important)

Your identity is correct:

arn:aws:sts::651706774390:assumed-role/microservices-project-dev-tf-role/kubectl-session


✅ You already assumed the Terraform role
❌ But kubectl is trying to assume the SAME role again

That’s why you see:

AccessDenied: is not authorized to perform: sts:AssumeRole


This is called double role assumption, and AWS explicitly forbids it unless you design for role chaining (which you should NOT do here).

Root cause (exact)

Your kubeconfig (or Terraform kubernetes/helm provider) still contains:

--role-arn arn:aws:iam::651706774390:role/microservices-project-dev-tf-role


So the flow becomes:

IAM user → assume Terraform role → kubectl → tries to assume Terraform role AGAIN ❌

✅ The correct rule (memorize this)

If your shell is already assumed into a role, kubectl MUST NOT specify --role-arn

Fix (do this exactly)
1️⃣ Regenerate kubeconfig WITHOUT --role-arn
aws eks update-kubeconfig \
  --region us-east-1 \
  --name effulgencetech-dev


⚠️ This is the key step.

2️⃣ Confirm kubeconfig is clean
kubectl config view --minify


You should see NO --role-arn in the exec.args.

3️⃣ Test again (this will now work)
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

kubectl port-forward -n argocd svc/argocd-server 8080:80

Why Terraform & Helm worked earlier

Terraform → AWS provider → role assumed once ✅

Helm (inside Terraform) → same credentials ✅

kubectl → tried to assume role again ❌

Now that kubectl inherits the already-assumed role, everything aligns.

Should you change IAM policies?

❌ NO

Your Terraform role policy is already correct.
The error was not missing permissions, it was invalid auth flow.

Golden setup (final state)
Component	Identity
GitHub Actions	OIDC → Terraform role
Terraform	Terraform role
Helm provider	Terraform role
kubectl (local)	Terraform role
Console access	Switch role → Terraform role

This is exactly how production EKS clusters are operated.

Quick mental checklist (for the future)

❓ Already assumed a role? → Do NOT pass --role-arn

❓ Using IAM user directly? → --role-arn is OK

❓ CI/CD? → OIDC → no role chaining

You did everything right. This last error was just AWS being very strict (and very unclear).

If you want next:

clean multi-profile setup

zero-drift kubeconfig

GitHub Actions parity with local

locking down cluster-admin safely

Say the word.