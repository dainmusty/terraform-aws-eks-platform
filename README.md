# Terraform AWS EKS Platform

This project demonstrates how to build a **production-ready Kubernetes platform on AWS** using Terraform, GitOps, and DevSecOps automation.

The platform provides a repeatable framework for deploying containerized applications on **Amazon EKS** with integrated CI/CD, security scanning, monitoring, and automated GitOps delivery.

The goal of this project was to simulate how modern platform teams build internal Kubernetes platforms that enable developers to deploy microservices securely and consistently.

---

# Architecture Overview

This platform combines several core cloud-native components:

Infrastructure provisioning using **Terraform**

Kubernetes orchestration using **Amazon EKS**

Application delivery using **ArgoCD GitOps**

Observability using **Prometheus and Grafana**

CI/CD automation using **GitHub Actions**

Security scanning integrated into the deployment pipeline

---

# Platform Components

## Kubernetes Platform (Amazon EKS)

The platform provisions a fully managed Kubernetes cluster using Terraform.

Capabilities include:

• Multi-node EKS cluster deployment  
• Managed node groups  
• Secure IAM role configuration  
• Kubernetes networking using AWS VPC CNI  

This allows teams to run scalable container workloads without managing the control plane.

---

## GitOps Application Delivery

Application deployments are managed using **ArgoCD** following the **App-of-Apps pattern**.

Benefits:

• Declarative infrastructure and application deployments  
• Automated synchronization between Git and Kubernetes  
• Self-healing workloads  
• Environment consistency across clusters  

The GitOps workflow ensures that **Git becomes the single source of truth** for platform configuration.

---

## Kubernetes Platform Add-ons

The following core add-ons are deployed to support platform operations:

**AWS Load Balancer Controller**  
Automatically provisions Application Load Balancers through Kubernetes Ingress resources.

**EBS CSI Driver**  
Enables dynamic provisioning of persistent storage for Kubernetes workloads.

**Prometheus + Grafana**  
Provides metrics collection and visualization for cluster monitoring.

**metrics-server**  
Supplies resource metrics required for autoscaling.

---

# Observability

Cluster monitoring is implemented using the **kube-prometheus-stack**.

This provides:

• Prometheus metrics collection  
• Grafana dashboards for infrastructure and workloads  
• Alerting capabilities for operational monitoring  

This stack enables teams to quickly detect performance issues and maintain platform reliability.

---

# CI/CD and DevSecOps

Infrastructure and application pipelines are implemented using **GitHub Actions**.

The pipeline includes automated security and quality checks:

• Trivy vulnerability scanning  
• OWASP dependency scanning  
• SonarCloud code quality analysis  
• Terraform validation and planning  

This ensures that both infrastructure and application code meet security and quality standards before deployment.

---

# Infrastructure as Code Design

Infrastructure is implemented using a **modular Terraform architecture**.

```
environments/
   dev/
   staging/
   prod/

modules/
   eks/
   iam/
   rds/
   s3/
   kms/
   route53/
   cloudfront/
```

This structure enables:

• reusable modules  
• environment isolation  
• scalable infrastructure deployments

---

# GitOps Repository Structure

Kubernetes manifests are organized to support the **ArgoCD App-of-Apps pattern**.

```
k8s/
 ├ bootstrap/
 │   ├ root-app-dev.yaml
 │   └ root-app-prod.yaml
 │
 ├ shared/
 │   ├ namespace.yaml
 │   ├ configmap.yaml
 │   └ secrets.yaml
 │
 └ apps/
     ├ dev/
     │   ├ web-app
     │   ├ token-app
     │   └ mongo
     │
     └ prod/
```

This structure ensures reusable resources across environments while keeping application deployments isolated.

---

# Key Lessons Learned

Building a Kubernetes platform highlighted several important platform engineering principles.

### GitOps simplifies operations

Using ArgoCD ensures that infrastructure and application deployments remain consistent and self-healing.

### Modular Terraform improves scalability

Reusable modules make it easier to extend infrastructure across multiple environments.

### Observability must be built into the platform

Prometheus and Grafana provide critical visibility into cluster health and application performance.

### Security should be embedded into pipelines

Integrating security scans directly into CI/CD helps catch vulnerabilities early in the development lifecycle.

### Platform teams should enable developers, not slow them down

By automating infrastructure provisioning and application deployment, developers can focus on building features rather than managing infrastructure.

---

# Outcome

This platform demonstrates how organizations can build an **internal Kubernetes platform** that provides:

• automated infrastructure provisioning  
• secure CI/CD pipelines  
• GitOps-based application delivery  
• integrated monitoring and observability  

Together, these capabilities enable development teams to **deploy microservices faster while maintaining security, reliability, and operational visibility.**

---

# Technologies Used

Terraform  
AWS EKS  
Kubernetes  
ArgoCD  
Prometheus  
Grafana  
GitHub Actions  
Trivy  
SonarCloud  
OWASP Dependency Check