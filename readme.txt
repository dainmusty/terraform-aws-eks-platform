# Enterprise Terraform Infrastructure Framework

This repository contains a standard cloud infrastructure design for enterprise-scale applications, built with Terraform on AWS. The goal is to provide a reusable, secure, and automated infrastructure framework that accelerates deployments while maintaining strong governance and scalability.

Key Features

Kubernetes Orchestration (EKS)

Fully managed Amazon EKS cluster for container workloads.

Addons: Grafana, Prometheus, ArgoCD (GitOps), ALB Controller, EBS CSI driver.

Supports frontend, backend, and database tiers with Kubernetes secrets for ECR and DB credentials.

AWS Services Provisioned via Terraform

RDS for relational databases.

IAM with hardened roles and guardrails.

S3 for storage, KMS for encryption, CloudFront for global distribution, Route53 for DNS, AWS Config for compliance.

Security & Compliance

Enforced IAM policies and KMS key management.

Integrated GuardDuty, WAF, Shield, and AWS Config for threat detection and governance.

CI/CD & DevSecOps Integration

GitHub Actions pipelines with pre-commit hooks.

Integrated SonarQube, OWASP, and Trivy for code quality, dependency, and vulnerability scanning.

Automated Docker image builds and ECR publishing.

Infrastructure as Code (IaC) Design via Terraform

Modular Terraform setup with root and child modules (EKS, IAM, RDS, S3, Route53, KMS, etc.).

Multi-environment deployments (dev, staging, prod) with consistent workflows.

Extensible and reusable design for future projects.

Impact

This framework improves:

Deployment speed with automation.

Environment consistency across teams and accounts.

Cost efficiency with reusable modules.

Security posture with compliance guardrails and monitoring.



Getting Started
Prerequisites

Terraform
 >= 1.5

AWS CLI
 configured with appropriate profiles

kubectl
 for EKS interaction

Helm
 for managing Kubernetes addons

Pre-commit hooks installed:

pre-commit install

Setup

Clone the repository

git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>


Initialize Terraform

terraform init


Select the environment (dev, staging, prod)

cd environments/dev


Validate and plan

terraform validate
terraform plan


Apply infrastructure

terraform apply

CI/CD Workflow

Pre-commit hooks ensure formatting, linting, and security checks:

terraform fmt

tflint

checkov

trivy

sonarqube

GitHub Actions automates:

Terraform plan & apply

Security scans

Docker image builds & ECR publishing

GitOps delivery with ArgoCD


.
├── environments/         # Root modules for dev, staging, prod
│   ├── dev/
│   ├── staging/
│   └── prod/
│
├── modules/              # Reusable child modules
│   ├── eks/              # EKS cluster provisioning
│   ├── rds/              # RDS database
│   ├── iam/              # IAM roles and policies
│   ├── s3/               # S3 storage
│   ├── kms/              # KMS key management
│   ├── route53/          # DNS management
│   ├── cloudfront/       # CDN distribution
│   └── config/           # AWS Config rules
│
├── scripts/              # User data scripts (e.g., Docker install)
├── .github/workflows/    # GitHub Actions CI/CD pipelines
├── .pre-commit-config.yaml # Pre-commit hooks (fmt, tflint, checkov, trivy, sonar)
└── README.md


Contributing

We welcome contributions to improve this framework. Please follow the steps below:

Fork the repository and create a feature branch:

git checkout -b feature/my-feature


Run pre-commit hooks before committing:

pre-commit run --all-files


This ensures formatting, linting, and security checks (Terraform fmt, TFLint, Checkov, Trivy, SonarQube) pass before submission.

Submit a Pull Request (PR) with a clear description of your changes.

Reference any issues being fixed.

Ensure CI/CD pipelines pass.

Code Review

PRs will be reviewed for consistency, security, and best practices.

Approved PRs will be merged into main after review.

⚡ With this framework, enterprises can deploy faster, remain secure, and scale confidently on AWS using Terraform and GitOps best practices.

# Enterprise with EKS + GitOps Summary
Use case: This pipeline is built for enterprises deploying full Kubernetes infrastructure using EKS and GitOps via ArgoCD.

🔧 Stack Overview
Infrastructure: EKS (via Terraform)
GitOps Tool: ArgoCD
Monitoring: kube-prometheus-stack (Prometheus + Grafana via Helm)
Security Scans: Trivy, OWASP, SonarCloud


# Steps to note
1. Design your  terraform directory structure. Setup your root module for your environments (dev,staging and prod) and your resuable child modules. Below is the directory structure

├── environments/         # Root modules for dev, staging, prod
│   ├── dev/
│   ├── staging/
│   └── prod/
│
├── modules/              # Reusable child modules
│   ├── eks/              # EKS cluster provisioning
│   ├── rds/              # RDS database
│   ├── iam/              # IAM roles and policies
│   ├── s3/               # S3 storage
│   ├── kms/              # KMS key management
│   ├── route53/          # DNS management
│   ├── cloudfront/       # CDN distribution
│   └── config/           # AWS Config rules
│
├── scripts/              # User data scripts (e.g., Docker install)
├── .github/workflows/    # GitHub Actions CI/CD pipelines
├── .pre-commit-config.yaml # Pre-commit hooks (fmt, tflint, checkov, trivy, sonar)
└── README.md


2. Start with your IAM roles and policies for your child modules that require permissions(best practice). Add permission boundaries to ensure least privilege access. Create a role and call it "terraform-role". Create an OIDC provider for github(use the youtube video link below to guide you) for a Federated User. Attach the oidc policy or permissions to the terraform role. The policy will give the terraform role the least access privilege. This adds another security layer for github to access your aws account through the oidc Fed provider. see below the oidc policy to be attached to the terraform role.

2. Build your EKS module; there are serveral options. You can use terraform directly or use cloudformation to build your EKS and nodegroup stack. You can then use cloudformation to deploy the stacks together.

3. As best practice, add the ff. to be installed on the EKS for cluster management.
# ALB controller to allow an ALB to be provisioned via the ingress k8s manifest file
# Argocd for gitOps operations. This will automatically handle your container(k8s) apps of apps
# EBS CSI Driver - This will aid in provisioning additional EBS volumes for your nodes
# Prometheus-Grafana Stack - This pack will install both prometheus and grafana on the cluster and accessed by your ingress. It is best practice to access it locally though via your localhost
# VPC CNI Driver is required for your EKS to be successfully deployed. It needs to be part of your addons.
# Setup the above-mentioned addons as reuseable modules so that it is easily maintained
# NB: Your EKS cluster will come with its own VPC and EC2s(nodes), thus you don't need  VPC and EC2 modules.

4. Build the rest of your child modules including S3, KMS, Config, RDS, CloudFront and Route53. Ensure each module is attached to the its IAM role with descriptions for team members to easily understand and reuse.

5. Reference the modules that are connected and test them one after the other as you build and add on.

6. Create a separate directory for your k8s manifest files and organise the frontend, backend and db tiers in separate directories. Below is how your k8s files should be setup.
├── k8s/
│   ├── bootstrap/
│   │   └── root-app-dev.yaml      # App of Apps 
│   └── apps/
│       └── dev/
│           ├── web-app/
│           │   ├── deployment.yaml
│           │   ├── service.yaml
│           │   ├── ingress.yaml
│           │   
│           ├── token-app/
│           │   ├── deployment.yaml
│           │   ├── service.yaml
│           │   ├── ingress.yaml
│           │   
│           └── payment-app/
│               ├── mongo-deployment.yaml
│               ├── mongo-service.yaml
│               ├── web-deployment.yaml
│               ├── web-service.yaml
│               ├── configmap.yaml
│               ├── secret.yaml
│               └── web-ingress.yaml

| Component         | Exposure       |
| ----------------- | -------------- |
| Web App           | Ingress        |
| Token App         | Ingress        |
| Payment (MongoDB) | ClusterIP only |
| Debugging         | Port-forward   |

# GitOps 
✅ ArgoCD App of Apps Structure

* `bootstrap/root-app.yml`: Defines ArgoCD root application pointing to `apps/`.

# How to access your argocd

7. Install pre-commit and checkov. Just like gitignore, create config files to override checkov and pre-commit errors that are deprecated or not threatening. See examples below.

# Pre-commit
.checkov.yml
framework: terraform

skip-check:
  - CKV2_AWS_62     # Event notifications not required for log bucket
  - CKV_AWS_290     # Acceptable write access in dev for flow logs
  - CKV_AWS_145     # SSE-KMS not enforced in dev
  - CKV_AWS_144     # Cross-region replication not required for dev logs
  - CKV2_AWS_11     # VPC flow logs are handled dynamically
  - CKV_AWS_300     # Lifecycle rule handles abort incomplete uploads
  - CKV2_AWS_12     # Default SG restricted via module logic


.pre-commit-config.yml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.100.0
    hooks:
      - id: terraform_fmt
      - id: terraform_tflint
      # remove terraform_checkov since we’ll use the official Checkov hook

  - repo: https://github.com/bridgecrewio/checkov
    rev: 3.2.471   # pin latest stable
    hooks:
      - id: checkov
        args: [--quiet, -d, .]   # optional: make it match your CLI usage

8. You can choose to install sonarqube and checkov locally to check your code quality or you can include it in your git workflow to use sonarcloud(scan on build). Depending on the language or application code, you can get the sonarqube job from git marketplace. Below are sonarqube and checkov jobs used for this project workflow. 

checkov:
    name: Run Checkov
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Checkov Scan
        uses: bridgecrewio/checkov-action@master
        with:
          directory: .
          quiet: true
          soft_fail: false

  sonarcloud:
    name: Run SonarCloud Code Quality Scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install SonarCloud Scanner
        run: |
          curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
          unzip -q sonar-scanner.zip
          echo "$PWD/sonar-scanner-5.0.1.3006-linux/bin" >> $GITHUB_PATH
      - name: SonarCloud Scan
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        run: |
          sonar-scanner \
            -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
            -Dsonar.organization=${SONAR_ORGANIZATION} \
            -Dsonar.branch.name=${GITHUB_REF_NAME} \
            -Dsonar.sources=. \
            -Dsonar.host.url=https://sonarcloud.io \
            -Dsonar.login=$SONAR_TOKEN


# Sonarcloud Setup
Go to the sonarcloud website and register. You can also login with you github account and it automatically connects with your repos.
Once you are logged in, create an organisation and add your repos as projects. This will automatically generate the project key (SONAR_PROJECT_KEY) and (SONAR_ORGANIZATION) which you can define as environmental variables in your workflow. eg.
env:
  TF_VAR_management_account_id: ${{ secrets.AWS_MANAGEMENT_ACCOUNT_ID }}
  TF_VAR_dev_account_id: ${{ secrets.AWS_DEV_ACCOUNT_ID }}
  AWS_REGION: ${{ secrets.AWS_REGION }}
  SONAR_PROJECT_KEY: dainmusty_MULTI-VPC-INTER-REGION-TGW
  SONAR_ORGANIZATION: effulgencetech


# Git Actions setup
9. Create a directory called .github , inside that directory, create another directory and call it workflows. Now create a yaml file inside workflows, you can give it any name. eg. terraform-apply-manual-destroy.yaml.

10. Define your workflow. The components of the workflow will depend on what expected in the project. For example, in this project, we want CICD of k8s microservices which is to be deployed by terraform and managed by argoCD. The workflow can be sectioned into 3 parts. 
Part 1 - trigger upon git push to a feature branch say dev
Part 2 - defining your environmental variables
Part 3 - actual jobs which includes the code scans, infra deployment and GitOps activities. eg. terraform plan,apply and manual destroy, k8s manifest files deployment by argocd. scans include code quality, code vulnerability, code dependency and k8s image scans.
Part 4 - Configuring credentials
See below the workflow for this project.

Part 1 - Trigger upon push
# name: Full CI/CD Pipeline

# on:
#   push:
#     branches:
#       - main
#   pull_request:

Part 2 - defining your environmental variables
 
# env:
#   AWS_REGION: us-east-1
#   CLUSTER_NAME: dev_eks_cluster
#   SONAR_PROJECT_KEY: dainmusty_ENTERPRISE-BUSINESS-TERRAFORM-INFRA
#   SONAR_ORGANIZATION: effulgencetech

Part 3 - scans; it could be code quality, code vulnerability, code dependency and k8s image scans.
# jobs:
#   security-scan:
#     name: Run Security Scans (Trivy + OWASP + SonarCloud)
#     runs-on: ubuntu-latest

#     steps:
#       - name: Checkout code
#         uses: actions/checkout@v4

#       - name: Trivy Filesystem Scan
#         uses: aquasecurity/trivy-action@0.28.0
#         with:
#           scan-type: fs
#           scan-ref: .
#           ignore-unfixed: true
#           severity: CRITICAL,HIGH

#       - name: OWASP Dependency-Check
#         uses: dependency-check/Dependency-Check_Action@main
#         id: Depcheck
#         with:
#           project: 'effulgencetech'
#           path: '.'
#           format: 'HTML'
#           out: 'reports'
#           args: >
#             --failOnCVSS 7
#             --enableRetired

#       - name: Upload OWASP Dependency-Check Report
#         uses: actions/upload-artifact@v4
#         with:
#           name: OWASP Depcheck Report
#           path: reports

#   sonarcloud:
#     runs-on: ubuntu-latest

#     steps:
#       - uses: actions/checkout@v4

#       - name: Install SonarCloud Scanner
#         run: |
#           curl -sSLo sonar-scanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip
#           unzip -q sonar-scanner.zip
#           echo "$PWD/sonar-scanner-5.0.1.3006-linux/bin" >> $GITHUB_PATH

#       - name: SonarCloud Scan
#         env:
#           SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
#         run: |
#           sonar-scanner \
#             -Dsonar.projectKey=${SONAR_PROJECT_KEY} \
#             -Dsonar.organization=${SONAR_ORGANIZATION} \
#             -Dsonar.branch.name=${GITHUB_REF_NAME} \
#             -Dsonar.sources=. \
#             -Dsonar.host.url=https://sonarcloud.io \
#             -Dsonar.login=$SONAR_TOKEN

#   terraform:
#     name: Deploy Infra with Terraform
#     runs-on: ubuntu-latest
#     needs: security-scan

#     steps:
#       - uses: actions/checkout@v4

#       - name: Set up Terraform
#         uses: hashicorp/setup-terraform@v3
#         with:
#           terraform_version: 1.6.6

Part 4 - Configuring credentials
#       - name: Configure AWS credentials
#         uses: aws-actions/configure-aws-credentials@v4
#         with:
#           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
#           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
#           aws-region: ${{ env.AWS_REGION }}

#       - name: Terraform Init
#         working-directory: env/dev
#         run: terraform init -input=false

#       - name: Create EKS Cluster Stack (Targeted)
#         working-directory: env/dev
#         run: |
#           terraform apply \
#             --auto-approve \
#             -target=module.eks.aws_cloudformation_stack.eks_cluster_stack

#       - name: Update kubeconfig for EKS
#         run: |
#           aws eks update-kubeconfig --region ${{ env.AWS_REGION }} --name ${{ env.CLUSTER_NAME }}

#       - name: Terraform Full Apply (Post Cluster)
#         working-directory: env/dev
#         run: terraform apply --auto-approve

#       - name: Check ArgoCD Status
#         run: |
#           echo "Checking ArgoCD pods status..."
#           kubectl get pods -n argocd
#           echo "Waiting for ArgoCD server pod to be ready..."
#           kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=120s

#   deploy-k8s:
#     name: ArgoCD Sync
#     runs-on: ubuntu-latest
#     needs: terraform

#     steps:
#       - uses: actions/checkout@v4

#       - name: Set up Git user
#         run: |
#           git config user.name github-actions[bot]
#           git config user.email github-actions[bot]@users.noreply.github.com

#       - name: Pull latest before pushing
#         run: |
#           git pull --rebase origin main

#       - name: Push changes
#         env:
#           GH_PAT: ${{ secrets.GH_PAT }}
#         run: |
#           git remote set-url origin https://x-access-token:${GH_PAT}@github.com/dainmusty/gnpc-terraform-infra-k8s-web-app.git
#           git push origin main

11. Once you define your credentials for eg. aws access keys and secret access keys, then you go to github and register or create all the access controls. This is to allow GitActions to permit terraform to access your aws account including they aws region you are working in. Go to the repo you are working on in github, go to settings, go to actions/variables, then create the secrets below for terraform. You also need to create a secret for the sonarqube token and paste the value generated for the project in sonarcloud.see below that section in the workflow

# - name: Configure AWS credentials
#         uses: aws-actions/configure-aws-credentials@v4
#         with:
#           aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
#           aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
#           aws-region: ${{ env.AWS_REGION }}
# SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
#         run: |
#           sonar-scanner \
#             -Dsonar.projectKey=${SONAR_PROJECT_KEY}

# How to access your prometheus and Grafana via GUI
12. Port forwarding (best practice for dev environment)


