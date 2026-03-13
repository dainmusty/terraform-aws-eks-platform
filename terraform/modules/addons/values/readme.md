You're not supposed to kubectl apply a Helm values file — it will always fail with:

apiVersion not set, kind not set


because values YAML ≠ Kubernetes manifest.

A Helm values file does NOT contain apiVersion or kind. It is not meant to be applied directly.
It is only meant to be passed to helm install or helm upgrade, or in your case, Terraform's helm_release.


helm upgrade --install argocd argo/argo-cd -n argocd -f argo-ingress-values.yaml
Error: repo argo not found
I cd'd to the directory where the file is but still got the error above...should i just update with terraform apply? or it will be faster with helm?
ChatGPT said:

The error:

Error: repo argo not found


has nothing to do with your current directory — Helm repositories are global.
It simply means you never added the Argo Helm repo.

✅ Fix the Helm repository error

Run this:

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update


Then try again:

helm upgrade --install argocd argo/argo-cd -n argocd -f argo-ingress-values.yaml


Now it will work.

⚡ Should you use Helm manually or Terraform apply?
✔ If you installed ArgoCD using Terraform + Helm provider

You MUST NOT run Helm manually — it will cause drift
(Helm state in Terraform will differ from actual cluster).

Terraform will say:

changes detected outside Terraform


And may recreate the release.

✔ If Terraform manages the ArgoCD Helm release

→ Apply the fix by updating values.yaml in Terraform
→ Then run:

terraform apply


This is the correct and clean approach.

🟩 When is it faster to use Helm directly?

Only when you installed ArgoCD manually with Helm, not through Terraform.

But in your case, you said:

am using helm + terraform to provision the alb.

So Terraform is managing the release → stick with Terraform.

✔ Final Answer

Add the repo (only needed if running Helm manually)

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update


But since your deployment is Terraform-managed,
update the values file in Terraform and run:

terraform apply


This will safely update the ALB ingress settings without state drift.

# argo ingress working to a point so far
server:
  service:
    type: ClusterIP
    ports:
      http: 80
      https: 443

  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      kubernetes.io/ingress.class: alb
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
      alb.ingress.kubernetes.io/backend-protocol: HTTP   # If you later want to add HTTPS (TLS termination at ALB) add the details below.
    hosts:
      - argocd.example.com
    paths:
      - path: /
        pathType: Prefix


# alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS": 443}]'
# alb.ingress.kubernetes.io/certificate-arn: <ACM_CERT>
# alb.ingress.kubernetes.io/backend-protocol: HTTP



2️⃣ What is WRONG (this is why it breaks)
❌ Problem 1 — Helm chart is still creating a LoadBalancer (NLB)

Even though you created an Ingress, your Helm values do not disable the default Service exposure.

By default, kube-prometheus-stack creates:

Component	Default
Prometheus	Service (ClusterIP)
Grafana	Service type LoadBalancer ❌

That’s why AWS created:

Type: network
Scheme: Internal
TargetType: Instance


➡️ Ingress + Service type LoadBalancer = conflict

Ingress expects:

ClusterIP

IP targets

HTTP

But Kubernetes already created an NLB first.

❌ Problem 2 — Ingress has NO host rule

Your ingress:

rules:
  - http:
      paths:


⚠️ This creates a catch-all ALB rule.

ALB Controller strongly prefers a host:

host: grafana.example.com


Without it:

Routing is unreliable

Health checks may pass but traffic times out

ALB looks “healthy but unreachable”

❌ Problem 3 — Missing health check annotations

ALB defaults to:

GET /
200


Grafana responds on /login, not /.

So ALB may mark targets:

Healthy at TCP

Unhealthy at HTTP

This causes:

ERR_CONNECTION_TIMED_OUT

3️⃣ THE FIX (minimal, correct, reusable)
🔧 A. Fix Helm values (MOST IMPORTANT)

In grafana.yaml, you MUST force ClusterIP and ingress disabled there (since you manage ingress yourself).

grafana:
  service:
    type: ClusterIP

  ingress:
    enabled: false


For Prometheus (if exposed later):

prometheus:
  service:
    type: ClusterIP

  ingress:
    enabled: false


🚫 Never let kube-prometheus create LoadBalancers
🚫 Never mix Service LB + Ingress


| File type           | Starts with               | Managed by          |
| ------------------- | ------------------------- | ------------------- |
| Helm values         | `server:`, `grafana:`     | Helm                |
| Kubernetes manifest | `apiVersion:`             | kubectl / Terraform |
| Terraform resource  | `resource "kubernetes_*"` | Terraform           |

Best practice reality check (you remembered correctly)

You are 100% correct:

ArgoCD, Prometheus, and Grafana are best accessed via port-forwarding in most environments

✅ Why port-forwarding is best practice

🔐 No public exposure

🧱 No ALB complexity

💰 No extra AWS cost

🧠 Less Terraform state coupling

⚡ Faster debugging

Ingress is usually only needed when:

Multi-team shared access

SSO / external auth

Production dashboards for execs

1️⃣ Inside the cluster (preferred, since Grafana pod runs inside the cluster)

Use the service DNS name:

http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090


kube-prometheus-stack-prometheus → service name

monitoring → namespace

svc.cluster.local → standard cluster DNS suffix

9090 → Prometheus port

This is the best practice, avoids hardcoding IPs.

2️⃣ If Grafana runs locally (outside cluster) using port-forward

Port-forward Prometheus:

kubectl port-forward svc/kube-prometheus-stack-prometheus -n monitoring 9090:9090


Grafana URL for Prometheus:

http://host.docker.internal:9090


or if running directly in browser on the same machine:

http://localhost:9090

3️⃣ How to add it to Grafana

Open Grafana → Settings → Data Sources → Add data source → Prometheus

URL:

Inside-cluster: http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090

Local via port-forward: http://localhost:9090

Click Save & Test → Should show Data source is working

💡 Tip: Using service DNS names is better than using ClusterIP addresses because ClusterIPs can change if the service is recreated.


Exactly — that’s correct. ✅

Here’s why:

The Grafana sidecar in the kube-prometheus-stack Helm chart does not read local file paths in values.yaml.

The sidecar only loads dashboards from ConfigMaps that are labeled with the label/labelValue you set (in your case, grafana_dashboard=1).

Adding entries like:

cpu-dashboard:
  file: values/dashboards/cpu-dashboard.json


inside `values.yaml won’t work — Grafana never sees those files directly.

✅ What actually works

Create ConfigMaps for each dashboard JSON:

apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-cpu-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  cpu-dashboard.json: |-
    { ... your JSON content ... }


Do the same for memory and pod status dashboards.

Grafana sidecar automatically mounts any ConfigMap with grafana_dashboard=1 into /var/lib/grafana/dashboards inside the Grafana pod.

Your existing grafana-dashboards.yaml only needs the sidecar + dashboardProviders sections (paths can be removed):

grafana:
  sidecar:
    dashboards:
      enabled: true
      label: grafana_dashboard
      labelValue: "1"
      folder: /var/lib/grafana/dashboards
      defaultFolderName: "General"
      searchNamespace: ALL

  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
        - name: default
          orgId: 1
          folder: ""
          type: file
          disableDeletion: false
          editable: true
          options:
            path: /var/lib/grafana/dashboards


After that, any dashboard JSON in a properly labeled ConfigMap will automatically appear in Grafana.


Step 4 — Fix GitHub Actions (this is where it breaks)

In your workflow, the order must be exact:

- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::651706774390:role/microservices-project-dev-tf-role
    aws-region: us-east-1

- name: Terraform Init
  run: terraform init

- name: Terraform Apply
  run: terraform apply -auto-approve


❌ If terraform init runs before AWS credentials exist → provider breaks permanently in that run.

# lets try and do this
make addons idempotent and CI-safe

# my origina kp-stack
resource "helm_release" "kube_prometheus_stack" { 
  name = "kube-prometheus-stack" 
  namespace = kubernetes_namespace_v1.monitoring.metadata[0].name 
  create_namespace = false 
  repository = "https://prometheus-community.github.io/helm-charts" 
  chart = "kube-prometheus-stack" 
  version = var.prometheus_stack_version 
  values = [ 
    templatefile("${path.module}/values/grafana-service.yaml", 
    { region = var.region 
    grafana_admin_secret = kubernetes_secret_v1.grafana_admin.metadata[0].name }), 
    file("${path.module}/values/alertmanager.yaml"), 
    file("${path.module}/values/grafana-dashboards.yaml"), 
    file("${path.module}/values/prometheus_rules.yaml") ] 
    depends_on = [ kubernetes_service_account_v1.grafana,
    kubernetes_secret_v1.grafana_admin, 
    kubernetes_secret_v1.alertmanager_slack_webhook ] }