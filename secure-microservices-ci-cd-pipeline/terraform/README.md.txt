# Before running this make sure to set valid AWS credentials using one of the following methods:

1. Use AWS CLI with a named profile
If you have AWS CLI installed and configured:

aws configure --profile my-secure-profile
Then modify your provider "aws" block to use this profile:

provider "aws" {
  region  = var.region
  profile = "my-secure-profile"
}

2. Set environment variables
Alternatively, export credentials directly in your terminal:

export AWS_ACCESS_KEY_ID="your_access_key"
export AWS_SECRET_ACCESS_KEY="your_secret_key"
export AWS_SESSION_TOKEN="your_session_token"  # if using temporary credentials (e.g., MFA)

Then run:
terraform init
terraform plan

===============================================================

This Terraform configuration provisions a secure, production-ready Kubernetes infrastructure on AWS using Amazon EKS, with best practices including:

- Isolated networking via VPC and subnets
- Role-based access using IAM for Service Accounts (IRSA)
- EKS audit logging
- Fine-grained network policies

---

## Components

### 1. **Provider**

provider "aws" {
  region = var.region
}

Specifies the AWS region used for provisioning resources.

---

### 2. **Networking: VPC & Subnets**

module "vpc" { ... }

Uses the `terraform-aws-modules/vpc/aws` module to create:
- A VPC (`10.0.0.0/16`)
- 3 Public Subnets
- 3 Private Subnets
- DNS support (for service discovery)

> Best Practice:Private subnets are used for EKS node placement to isolate workloads from the public internet.

---

### 3. **Security Group**

resource "aws_security_group" "eks_nodes_sg" { ... }

Defines a security group allowing only intra-VPC traffic to EKS nodes on port `443`, and unrestricted egress.

> **Note:** Port 443 access is limited to VPC CIDR for inter-service communication.

---

### 4. **IAM Policy for IRSA**

resource "aws_iam_policy" "example_irsa_policy" { ... }

Loads a custom IAM policy (`example-policy.json`) for attaching to Kubernetes service accounts via IAM Roles for Service Accounts (IRSA).

---

### 5. **Amazon EKS Cluster**

module "eks" { ... }

Uses the `terraform-aws-modules/eks/aws` module to create:
- A secure EKS cluster (`my-secure-eks`)
- Kubernetes version `1.29`
- Private endpoint only (no public access)
- Logging for `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`
- One managed node group using `t3.medium` instances
- Attaches custom IAM policies for IRSA support

---

### 6. **Kubernetes Namespace & Network Policies**
```hcl
resource "kubernetes_namespace" "network_policy_demo" { ... }
resource "kubernetes_network_policy" "deny_all" { ... }
resource "kubernetes_network_policy" "allow_app_ingress" { ... }
```

- **Namespace**: `secure-app`
- **Default Deny-All Policy**: Blocks all ingress/egress traffic
- **Ingress Allow Policy**: Allows `frontend` pods to talk to `myapp` pods only

> **Security Benefit**: Implements zero-trust networking using Kubernetes network policies.

---

## File Structure

├── main.tf                      # Terraform infrastructure definitions
├── variables.tf                 # Input variables
├── outputs.tf                   # Output Variables    
├── README.md                    # This documentation


---

## Security Best Practices

| Area               | Implementation                                              |
|--------------------|--------------------------------------------------------------|
| Network Isolation  | Private subnets, deny-all network policy                     |
| IAM Permissions    | Fine-grained IRSA role with specific policy                  |
| Logging & Audit    | EKS control plane logs enabled                               |
| Access Restriction | EKS public endpoint disabled                                 |
| Least Privilege    | Custom security group rules                                  |

---
