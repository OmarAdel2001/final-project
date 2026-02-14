# Infrastructure as Code (IaC) Architecture

## Executive Summary

This document serves as the comprehensive reference for the Infrastructure as Code (IaC) implementation of the **DevSecOps Capstone Project**. The infrastructure is provisioned using **Terraform**, adhering to the principles of immutability, modularity, and least privilege.

The solution deploys a highly available, secure, and compliant environment on **Amazon Web Services (AWS)**, designed to host microservices workloads orchestrated by **Amazon EKS**. Security is baked into every layer, from network isolation (VPC design) to data encryption at rest and in transit.

## Solution Architecture

The infrastructure is organized into a modular hierarchy, controlled by a root orchestration module.

<img width="1024" height="1536" alt="architecture" src="https://github.com/user-attachments/assets/00c3823d-3069-4d1b-b97b-84f7af1b9916" />

## Detailed Component Analysis

### 1. Network Foundation (VPC)
*   **Design**: Custom VPC with a 3-tier subnet architecture per Availability Zone (AZ).
*   **Public Tier**: Hosts Application Load Balancers (ALB) and NAT Gateways.
*   **Private Tier**: Dedicated to compute resources (EKS Nodes) and internal caching (ElastiCache).
*   **Data Tier**: Strictly isolated subnets for persistent storage (RDS), with no route to the internet.

### 2. Compute & Orchestration (EKS)
*   **Control Plane**: Managed Amazon EKS, updated to the latest stable Kubernetes version.
*   **Data Plane**: Managed Node Groups running in private subnets, auto-scaling based on CPU/Memory pressure.
*   **Identity**: Integrated with AWS IAM via OIDC, enabling **IAM Roles for Service Accounts (IRSA)** for fine-grained pod permissions.

### 3. Data Persistence
*   **Relational Database**: Amazon RDS for PostgreSQL.
    *   **High Availability**: Multi-AZ deployment (standby replica in a different AZ).
    *   **Security**: Encrypted at rest using a dedicated KMS key.
*   **Caching**: Amazon ElastiCache (Redis).
    *   **Performance**: In-memory data store for sub-millisecond latency.
    *   **Security**: Encrypted in transit (TLS) and at rest.

### 4. Container Registry (ECR)
*   **Repositories**: Separate repositories for Backend and Frontend artifacts.
*   **Lifecycle Policies**: Automated retention rules to expire untagged or old images, optimizing storage costs.
*   **Security**: Image scanning on push enabled to detect vulnerabilities early.

## Operational Procedures

### Prerequisites
*   **Terraform**: v1.5.0 or higher.
*   **AWS CLI**: Configured with Administrator privileges for the target account.
*   **S3 Backend**: An S3 bucket (`capstone-tf-state-1770806700`) must exist for state storage.

### Deployment Lifecycle

#### Step 1: Initialization
Download providers and configure the remote backend.
```bash
terraform init
```

#### Step 2: Static Analysis
Validate syntax and configuration integrity.
```bash
terraform validate
```

#### Step 3: Predictive Planning
Generate an execution plan to visualize changes before application.
```bash
terraform plan -out=tfplan
```
*CRITICAL: exact resources to be added, changed, or destroyed will be detailed here. Review this output for any unintended destructive actions.*

#### Step 4: Infrastructure Provisioning
Apply the verified plan.
```bash
terraform apply tfplan
```

### Disaster Recovery
In the event of a catastrophic failure or need for decommissioning:
```bash
terraform destroy
```

## Security & Compliance Control

| Control | Implementation |
| :--- | :--- |
| **Data Encryption** | AWS KMS (symmetric) used for RDS, Redis, and CloudWatch Logs. |
| **Network Segmentation** | Strict security group rules allowing traffic only from specific upstream sources (e.g., App -> DB). |
| **Secret Management** | Database credentials generated randomly by Terraform and stored in AWS Secrets Manager (or output as sensitive). |
| **State Security** | Terraform state file stored in S3 with Server-Side Encryption (SSE) and DynamoDB locking. |

## Module Reference

| Module | Source Path | Key Responsibilities |
| :--- | :--- | :--- |
| `vpc` | `./modules/vpc` | CIDR allocation, Subnetting, Route Tables, IGW/NAT. |
| `eks` | `./modules/eks` | Cluster bootstrapping, Node Groups, OIDC Provider. |
| `security` | `./modules/security` | Key Management Service (KMS) & Random Password generation. |
| `rds` | `./modules/rds` | PostgreSQL instance configuration & Subnet Groups. |
| `redis` | `./modules/redis` | Redis Replication Group & Subnet Groups. |
| `logging` | `./modules/logging` | CloudWatch Log Groups for centralized observability. |
