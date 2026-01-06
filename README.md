This is a template for a secure, automated CI/CD pipeline built with Jenkins on AWS EKS for deploying microservices. The pipeline integrates DevSecOps practices including static code analysis, container scanning, compliance benchmarking, GitOps deployment, and observability via Prometheus and Grafana.
I am open to suggestions on how to make this configuration run smoother or more securely. This was fun to work on and had some troubleshooting along the way. 

Architecture & Infrastructure
Provisioned with Terraform:
    • VPC with public and private subnets across multiple AZs.
    • EKS Cluster using AWS-managed Kubernetes.
    • Security Groups restrict inbound/outbound traffic.
    • IAM Roles for Service Accounts (IRSA): Fine-grained access for each component (e.g., Jenkins, ArgoCD).
    • Kubernetes Network Policies: Segment communication between namespaces and workloads.

CI/CD Pipeline Stages
Stage
Tools Used
Security Integration
Checkout
GitHub
N/A
Build
Maven
Dependency auditing (optional)
Static Code Analysis
SonarQube
Detects vulnerabilities, code quality issues
Unit Tests
Maven/JUnit
Validates logic correctness
Docker Build & Image Scan
Docker, Trivy
Detect CVEs in base/app layers
CIS Benchmark Scan
kube-bench
Ensures Kubernetes hardening
Prometheus Export Conversion
Custom script
Parses kube-bench JSON for observability
Deployment
Helm, GitOps (ArgoCD)
Rollbacks on failure, auto-sync

Jenkins Pipeline file explained:
The stages defined for Jenkins to complete in this pipeline file include
    1.  Build, Test, and Static Code Analysis using SonarQube.
    2. Container Image Scanning using Trivy.
    3.  Kubernetes deployment with GitOps – ArgoCD.
    4. Runtime security monitoring using Falco.
    5. Compliance reporting using Trivy, kube-bench.
    6.  Monitoring and alerting using Prometheus + Grafana.

Configuration Files
    • trivy-scan.sh: Bash script to run Trivy against Docker images.
    • convert-cis-report-to-prometheus.sh: Converts kube-bench results to Prometheus metrics.
    • helm-chart/: Microservice manifests and templates.
    • argocd/: ArgoCD-managed GitOps directory structure.
    • jenkins-policy.json: IAM policy granting scoped permissions to Jenkins and related tools.

Security Policies
Control Type
Implementation Details
IAM
IRSA roles assigned to K8s service accounts for scoped permissions
Image Vulnerability
Trivy scans before pushing to registry
Static Analysis
SonarQube scans during Jenkins build stage
Compliance
kube-bench executed per build for EKS cluster nodes
Runtime Security
Falco deployed as DaemonSet (planned)
Network Segmentation
Kubernetes NetworkPolicies and separate namespaces
Encryption
Secrets and passwords encrypted (e.g., Jenkins credentials)

Compliance Reporting
    • kube-bench generates CIS benchmark reports for worker nodes.
    • Converted via convert-cis-report-to-prometheus.sh and sent to Pushgateway.
    • Prometheus scrapes metrics; Grafana displays dashboards.
    • Optional: Export logs/metrics to CloudWatch or SIEM.

Observability
Monitoring Setup:
    • Prometheus: Collects metrics from:
        ◦ Jenkins build success/failure
        ◦ Trivy scan results
        ◦ kube-bench compliance score
    • Grafana: Dashboards include:
        ◦ CI/CD health
        ◦ Vulnerability trends
        ◦ CIS compliance status
    • Alerts: Triggered via Prometheus Alertmanager for:
        ◦ High-severity CVEs
        ◦ Compliance failure
        ◦ Build pipeline errors

Collaboration and Governance
Team
Responsibilities
Dev Team
Application code, unit testing, Helm charts
SRE/Platform
Terraform infra, Jenkins & ArgoCD setup, observability
Security
Policy definition, scanner config, compliance enforcement

Architecture Diagram:

Developer
   |
   v
Jenkins CI
   ├─> SonarQube
   ├─> Trivy (image scan)
   ├─> kube-bench (CIS)
   └─> Git update to ArgoCD Repo
           |
           v
        ArgoCD
           |
           v
     Amazon EKS Cluster
           |
     ┌──────────────┐
     │ Prometheus   │ <── kube-bench/trivy results
     │ Grafana      │ <── dashboards/alerts
