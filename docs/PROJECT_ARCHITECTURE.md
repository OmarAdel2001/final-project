# Project Architecture & Documentation

This document provides a detailed explanation of the DevSecOps-NTI-Production-Project codebase, covering infrastructure, security, kubernetes, and CI/CD pipelines. It explains not just *what* is implemented, but *why* these specific technologies and patterns were chosen.
<img width="1024" height="1536" alt="image" src="https://github.com/user-attachments/assets/f76fbd53-4193-4a28-8955-4e3c11856250" />

## 1. Repository Structure Overview

The repository is organized into logical components separating infrastructure, application code, and operational configuration.

```
├── ansible/                # Config management for Vault & Security extensions
├── backend/                # Python/Flask Backend Application
├── charts/                 # Helm Charts for Kubernetes deployments
├── devops/                 # CI/CD Templates & Scripts
├── docs/                   # Documentation (Guides, Setup, Terraform)
├── frontend/               # Node.js/React Frontend Application
├── k8s/                    # Raw Kubernetes Manifests & Kyverno Policies
├── terraform/              # Infrastructure as Code (AWS Resource Provisioning)
├── azure-pipelines-*.yml   # CI/CD Pipeline Definitions
```

## 2. Infrastructure (Terraform) (`/terraform`)

The project uses modular Terraform to provision a secure AWS environment.

### Why Terraform?
*   **Infrastructure as Code (IaC)**: Allows us to version control our infrastructure, ensuring reproducibility and eliminating manual "ClickOps" errors.
*   **State Management**: Tracks the exact state of resources, allowing for safe updates and drift detection.
*   **Modularity**: enables reusability of code (e.g., standardizing how we create S3 buckets or ECR repositories across the organization).

### Core Modules
*   **VPC (`modules/vpc`)**: Creates the network foundation.
    *   *Why*: Required for isolation. We use public subnets for entry points (ALB) and private subnets for everything else (Apps, DBs) to minimize the attack surface.
*   **EKS (`modules/eks`)**: Provisions the Kubernetes Control Plane and Worker Node Groups (instances managed by ASG).
    *   *Why*: Managed Kubernetes (EKS) handles the complex control plane upgrades and availability, letting us focus on running applications.
*   **Security (`modules/security`)**: Manages KMS Keys (Encryption) and Security Groups (Firewalls) for RDS/Redis/EKS.
    *   *Why*: Centralizing security rules ensures consistency. KMS keys allow us to rotate encryption keys centrally without redeploying data.
*   **RDS (`modules/rds`)**: Deploys a managed Postgres database in private subnets, encrypted with KMS.
    *   *Why*: RDS handles backups, patching, and failover automatically. Putting it in private subnets prevents direct internet access, preventing brute-force attacks.
*   **Redis (`modules/redis`)**: Deploys ElastiCache Redis for caching, encrypted with KMS.
    *   *Why*: Caching frequently accessed data reduces load on the primary database (RDS), improving application response times for users.
*   **ECR (`modules/ecr`)**: Creates detailed Container Registries with lifecycle policies and scan-on-push enabled.
    *   *Why*: ECR integrates natively with EKS for authentication. Scan-on-push provides immediate feedback on vulnerabilities in our container images before they are even deployed.

### State Management
*   **Backend (`backend.tf`)**: Stores state in S3 (`capstone-tf-state...`) with DynamoDB locking (`terraform-lock`) to prevent concurrent edits.
    *   *Why*: Storing state remotely allows multiple developers/pipelines to work without overwriting each other. DynamoDB locking prevents race conditions.

## 3. Kubernetes & Security (`/k8s`, `/charts`)

### Governance (Kyverno)
Located in `k8s/kyverno/policies/`.
*   **Why Kyverno?**: It is an admission controller that acts as a gatekeeper. It prevents "bad" configurations from ever entering the cluster, rather than just alerting on them later.
*   **`require-non-root.yaml`**: Enforces best practices by blocking containers running as root (UID 0).
    *   *Why*: If a container running as root is compromised, the attacker has a higher chance of escaping to the host node. Running as non-root mitigates this significantly.
*   **`verify-images.yaml`**: INTEGRITY CHECK. Ensures only images signed by your specific Cosign keys (or OIDC identity) can run in the cluster.
    *   *Why*: Prevents supply chain attacks where a malicious actor injects a compromised image into our registry. If the signature doesn't match our CI pipeline's signature, the cluster rejects it.

### Access Management (Vault)
Located in `ansible/` and `terraform/modules/vault`.
*   **Why Vault?**: Kubernetes Secrets are only base64 encoded (not encrypted) by default. Vault provides dynamic, encrypted secrets management.
*   **Integration**: Vault tracks secrets (DB passwords) and injects them safely into Pods at runtime using the Vault Agent Injector.
    *   *Why*: The application never needs to know the actual password in its config files. The secret exists only in memory while the app is running.
*   **Authorization**: Uses Kubernetes Auth Method (`ansible/vault-config.yml`).
    *   *Why*: Ties secret access to the *Pod's identity* (Service Account). If a pod is deleted, its access is revoked immediately.

### Deployment (Helm Charts)
*   **Why Helm?**: Helm is a package manager for K8s. It allows us to template our manifests, making it easy to deploy the same application to Dev, Staging, and Prod with different configurations (values.yaml).
*   **Backend (`charts/backend`)**: Deployment, Service, and Vault annotation injection for the Python app.
*   **Frontend (`charts/frontend`)**: Deployment, Service, and Ingress (ALB) configuration for the Node.js app.

## 4. CI/CD Pipelines (Azure DevOps)

The system relies on three primary pipelines.
*   **Why Azure DevOps?**: Provides an integrated environment for Repos, Pipelines, and Artifacts. Its "yaml pipelines" allow us to version control our build process alongside our code.

### `azure-pipelines-infra.yml` (Infrastructure)
1.  **Security Scan**: Runs `Trivy` on Terraform code.
    *   *Why*: Detects insecure defaults (like open ports or unencrypted storage) *before* we provision them, shifting security left.
2.  **Diagnostics**: Checks AWS connectivity.
    *   *Why*: Fails fast if credentials are missing, saving time.
3.  **Terraform Lifecycle**: Init -> Validate -> Plan -> Apply.
    *   *Why*: Standard IaC workflow. `Plan` lets us review changes before `Apply` makes them real.
4.  **Post-Provisioning**: Installs Kyverno and Vault.
    *   *Why*: Ensures the cluster is "secure by default" immediately after creation.

### `azure-pipelines-backend.yml` & `azure-pipelines-frontend.yml`
1.  **Build**: Creates Docker image.
2.  **Security Checks**:
    *   **Trivy**: Scans the *image* for OS vulnerabilities.
        *   *Why*: Ensures we aren't shipping images with known exploits (e.g., Log4Shell, Heartbleed).
    *   **Syft**: Generates an SBOM (Software Bill of Materials).
        *   *Why*: Provides a complete inventory of every library in our software. Critical for rapid response when zero-day vulnerabilities are announced.
    *   **Cosign**: Signs the image.
        *   *Why*: Creates a cryptographic proof that *this specific pipeline* built *this specific image*.
3.  **Publish**: Pushes to AWS ECR.
4.  **Deploy**: Uses Helm to deploy.
    *   *Why*: Automated deployment ensures consistency and reduces manual handover errors between Dev and Ops.

## 5. Key Operational Files
*   **`ansible/vault-config.yml`**: Playbook to configure Vault completely.
    *   *Why*: Configuring Vault via UI or CLI is manual and error-prone. Ansible automates the complex setup (Auth methods, Policies, Roles) so security configuration is reproducible.
*   **`devops/templates/*.yml`**: Reusable pipeline steps.
    *   *Why*: "Don't Repeat Yourself" (DRY). If we want to change how we scan images, we update one template, and both Frontend and Backend pipelines are automatically updated.
