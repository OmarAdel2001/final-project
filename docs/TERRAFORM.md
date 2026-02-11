# Terraform Infrastructure Documentation

## Overview

This directory contains the Infrastructure as Code (IaC) configuration for the **DevSecOps Capstone Project**. It utilizes **Terraform** to provision a secure, scalable, and production-ready environment on AWS. The infrastructure is modularized to ensure maintainability, reusability, and separation of concerns.

The configuration provisions a tailored **Virtual Private Cloud (VPC)**, a managed **Amazon EKS** cluster, distinct data layers (**RDS PostgreSQL** and **ElastiCache Redis**), and necessary security primitives including **KMS** encryption and **IAM** roles.

## Prerequisites

Before executing the Terraform configuration, ensure the following tools are installed and configured:

- **Terraform** (v1.0+)
- **AWS CLI** (v2.x) configured with appropriate credentials (`aws configure`)
- **Git** (for cloning the repository)
- **SSH Key Pair**: Optional, but recommended for debugging EKS nodes (`~/.ssh/id_rsa.pub` by default).

## Usage Guide

### 1. Initialization
Initialize the Terraform working directory. This command downloads the required providers and configures the remote backend (S3 + DynamoDB).

```bash
cd terraform
terraform init
```

### 2. Validation & Formatting
Ensure the configuration is syntactically valid and adheres to canonical formatting.

```bash
terraform validate
terraform fmt
```

### 3. Planning
Generate an execution plan to preview the changes Terraform will make to your infrastructure.

```bash
terraform plan -out=tfplan
```
*Review the output carefully to ensure it matches your expectations.*

### 4. Application
Apply the changes to provision the infrastructure.

```bash
terraform apply tfplan
```

### 5. Destruction
To tear down all resources managed by this configuration:

```bash
terraform destroy
```

## State Management

This project uses a **Remote Backend** to store the Terraform state file securely and enable collaboration.

- **Backend Type**: AWS S3
- **Bucket Name**: `capstone-tf-state-1770806700` (Defined in `backend.tf`)
- **Locking**: Amazon DynamoDB table (`terraform-lock`) prevents concurrent state modifications.
- **Encryption**: State file is encrypted at rest.

## Infrastructure Architecture (Modules)

The configuration is orchestrated via the root `main.tf` which calls the following reusable modules:

| Module | Source | Description |
| :--- | :--- | :--- |
| **`vpc`** | `./modules/vpc` | Provisions the network foundation including VPC, Public/Private Subnets, NAT Gateways, and Route Tables. |
| **`security`** | `./modules/security` | Manages KMS keys for encryption (RDS, Redis, Logs) and generates random secure passwords for the database. |
| **`eks`** | `./modules/eks` | Deploys the EKS Control Plane, Managed Node Groups, and configures IAM Roles for Service Accounts (IRSA). |
| **`rds`** | `./modules/rds` | Provisions the Multi-AZ PostgreSQL database in isolated private subnets with encryption at rest. |
| **`redis`** | `./modules/redis` | Deploys the ElastiCache Redis cluster for high-performance caching. |
| **`alb`** | `./modules/alb` | Configures the Application Load Balancer Security Groups and dependencies (Controller installed via Helm). |
| **`logging`** | `./modules/logging` | specific CloudWatch Log Groups for cluster, application, and performance logs. |
| **`ecr`** | `./modules/ecr` | Creates ECR repositories for Backend and Frontend images with lifecycle policies and force-delete enabled. |

## Inputs

| Name | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `aws_region` | `string` | `"us-east-2"` | The AWS region where resources will be deployed. |
| `project_name` | `string` | `"capstone-project"` | Base name used for resource naming and tagging conventions. |
| `vpc_cidr` | `string` | `"10.0.0.0/16"` | The IPv4 CIDR block for the VPC. |
| `db_password` | `string` | `""` | Master password for the RDS database. If left empty, a secure random password is generated automatically. |
| `ssh_public_key_path` | `string` | `"~/.ssh/id_rsa.pub"` | Path to the local public SSH key to allow access to EKS worker nodes. |

## Outputs

After a successful `apply`, Terraform exports the following values:

| Name | Description | Usage |
| :--- | :--- | :--- |
| `cluster_name` | Name of the EKS cluster | Required for `aws eks update-kubeconfig`. |
| `cluster_endpoint` | EKS Control Plane URL | Endpoint for `kubectl` communication. |
| `alb_dns_name` | Load Balancer DNS | The public entry point for accessing the application. |
| `rds_endpoint` | Database Connection String | Host address for the PostgreSQL instance. |
| `redis_endpoint` | Redis Cluster Endpoint | Host address for the ElastiCache cluster. |
| `backend_ecr_url` | ECR Repo URL (Backend) | Target for pushing backend Docker images. |
| `frontend_ecr_url` | ECR Repo URL (Frontend) | Target for pushing frontend Docker images. |
| `db_password` | Database Password | **Sensitive**. The master password for the database. |
| `cluster_oidc_issuer_url` | OIDC Issuer | Used for configuring IAM Roles for Service Accounts (IRSA). |

## Security Best Practices implemented

1.  **Encryption at Rest**: All sensitive data stores (RDS, Redis, S3 State) are encrypted using AWS KMS.
2.  **Encryption in Transit**: EKS communication, RDS, and Redis support TLS/SSL.
3.  **Network Isolation**:
    *   Databases rely in **private, isolated subnets** with no direct internet access.
    *   EKS Nodes run in **private subnets**.
    *   Only ALB and NAT Gateways reside in **public subnets**.
4.  **Least Privilege**:
    *   Security Groups strictly limit traffic (e.g., RDS only accepts connections from EKS nodes).
    *   IAM Roles use OIDC connectivity to grant Pods only the permissions they explicitly need.
5.  **Sensitive Data**: Database passwords are marked as `sensitive` in Terraform to prevent them from being displayed in plain text in CLI output.
