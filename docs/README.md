
---

# 🚀 Production-Grade Cloud Architecture

---

## 🏗️ High-Level Architecture Overview





This project implements a **secure, highly available, production-grade AWS architecture** following modern **DevSecOps, Zero-Trust, and Infrastructure as Code principles**.

The system is designed with:

* 🔐 Defense-in-depth security
* 🏗️ Modular Terraform infrastructure
* ☸️ Kubernetes-native workload orchestration
* 🔄 Automated CI/CD with supply chain security
* 🔎 Policy enforcement & runtime governance

---

# 🌍 Architecture Diagram

![Production Architecture](architecture.png)

---

# 🏢 Infrastructure Layers

---

## 1️⃣ Edge & Perimeter Security

### 🔹 CloudFront

* Global CDN
* TLS termination
* DDoS protection (Shield)

### 🔹 AWS WAF

* L7 filtering
* Rate limiting
* OWASP rule sets

### 🔹 Application Load Balancer

* Layer 7 routing
* Path-based routing
* Kubernetes Ingress integration

---

## 2️⃣ Network Architecture (VPC Design)

| Layer                | Purpose          | Internet Access |
| -------------------- | ---------------- | --------------- |
| Public Subnets       | ALB + NAT        | Yes             |
| Private App Subnets  | EKS Worker Nodes | Outbound only   |
| Private Data Subnets | RDS + Redis      | No              |

### Key Design Decisions

* 3-Tier Architecture (Public / App / Data)
* Multi-AZ High Availability
* NAT for controlled outbound traffic
* No direct internet access to compute or database

---

## 3️⃣ Compute Layer – Amazon EKS

* Managed Kubernetes Control Plane
* Managed Node Groups (Auto Scaling)
* Private Subnet Deployment
* IAM Roles for Service Accounts (IRSA)
* OIDC Integration

### Namespaces

* `final-project`

### Security Controls

* Kyverno policy engine
* Image signature verification (Cosign)
* Non-root container enforcement
* Resource limits enforced

---

## 4️⃣ Data Layer

### 🔹 Amazon RDS (PostgreSQL)

* Multi-AZ deployment
* Automated backups
* Encrypted at rest (KMS)
* Private subnet only

### 🔹 ElastiCache Redis

* In-memory caching
* Encrypted in transit (TLS)
* Reduces RDS load
* Private subnet isolation

---

## 5️⃣ Container Security & Supply Chain

| Stage             | Tool    | Purpose                    |
| ----------------- | ------- | -------------------------- |
| Static IaC Scan   | Trivy   | Scan Terraform             |
| Image Scan        | Trivy   | OS vulnerability detection |
| SBOM              | Syft    | Software inventory         |
| Image Signing     | Cosign  | Supply chain integrity     |
| Admission Control | Kyverno | Enforce signed images      |

Only **signed images from the CI pipeline** can run inside the cluster.

---

## 6️⃣ Infrastructure as Code (Terraform)

* Modular architecture
* Remote backend (S3)
* State locking (DynamoDB)
* KMS encryption
* Drift detection

### Modules

* VPC
* EKS
* RDS
* Redis
* ECR
* Security (KMS / SG)
* Logging

---

## 7️⃣ Secrets & Access Management

* HashiCorp Vault integration
* Vault Agent Injector
* Kubernetes Auth Method
* Dynamic secret injection
* No hardcoded credentials

Secrets exist **only in memory at runtime**.

---

## 8️⃣ CI/CD Pipeline Architecture

Platform: **Azure DevOps**

### Infra Pipeline

1. Trivy IaC Scan
2. Terraform Init / Plan / Apply
3. Post-Provision Security Setup

### Application Pipelines

1. Build Docker Image
2. Trivy Image Scan
3. Generate SBOM
4. Cosign Sign
5. Push to ECR
6. Helm Deploy to EKS

---

# 🔐 Security Model (Defense in Depth)

| Layer        | Control                 |
| ------------ | ----------------------- |
| Edge         | CloudFront + WAF        |
| Network      | Security Groups + NACL  |
| Compute      | Non-root containers     |
| Supply Chain | Signed images only      |
| Secrets      | Vault dynamic injection |
| Data         | KMS encryption          |
| State        | Encrypted S3 backend    |
| Governance   | Kyverno                 |

---

# 📈 High Availability Strategy

* Multi-AZ subnets
* RDS Multi-AZ standby
* EKS managed node groups
* Auto Scaling
* Stateless frontend/backend pods

---

# 💡 Why This Architecture Is Production-Ready

✔ Zero public database exposure
✔ Immutable infrastructure
✔ Encrypted everywhere
✔ Policy-driven Kubernetes governance
✔ Supply chain secured
✔ Remote Terraform backend with locking
✔ Modular and reusable design

---

# 🧠 Architectural Principles Applied

* Least Privilege
* Immutable Infrastructure
* Security by Default
* Infrastructure as Code
* GitOps-style deployment
* Shift-Left Security
* Defense in Depth

---
