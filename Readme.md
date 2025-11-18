# 🚀 OpenSearch with API Gateway Dev Stack Deployment Guide

## TL;DR Quick Commands

### Infra Deployment

- `./deploy.sh` – interactive CloudFormation deploy (EU/US/Lab) using credentials from `.env`.
- `./deploy-ssm.sh` – push `.env` secrets into SSM Parameter Store before stack deploys.

### Get/Update Deployables Version Scripts

- `./scripts/get_latest_deployed_lambda_versions.sh` – list Lambdas with parsed image tag versions.
- `ENV=stg MODE=manual node node_scripts/versionDashboardUpdate.js` – generate curl JSON for Consul updates.
- `ENV=prod MODE=auto node node_scripts/versionDashboardUpdate.js` – push versions straight to Consul and verify.
- `node node_scripts/getDeployedVersions.js` – print staging & prod dashboard versions via curl.
- `./scripts/get_deployed_versions_vers_dash.sh [stg|prod]` – Bash variant to read dashboard versions (defaults to both).

## 📌 Purpose

This project provides **consistent stack creation** for AWS OpenSearch Dev Environments.  
It enables **automated deployment** via **AWS CloudFormation** using **VS Code & AWS CLI**, and now also includes a script to safely deploy secrets into AWS Systems Manager Parameter Store.

---

## 📦 Project Structure

```text
.
├── scripts/                     # Helper scripts to manage our resources
├── templates/
│   ├── osGatewayDevStack.yml    # CloudFormation template for OpenSearch & API Gateway
│   ├── ssm-params.yml           # CloudFormation template for SSM Parameter Store secrets
├── .env                         # Environment variables (ignored by Git)
├── .env_example                 # Example env file for users to copy
├── deploy.sh                    # Deployment script for OpenSearch & API Gateway stack
├── deploy-ssm.sh                # Deployment script to push secrets into SSM Parameter Store
├── .gitignore                   # Ignores secrets & generated files
└── README.md                    # This guide
```

## ⚙️ Setup

### 1️⃣ Install Required Tools

Ensure you have the following installed:

- **AWS CLI** → [Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- **AWS Toolkit for VS Code** (Optional, for AWS UI inside VS Code) → [Install and Usage Guide](https://docs.aws.amazon.com/infrastructure-composer/latest/dg/using-composer-ide.html)
- **CloudFormation Permissions** (IAM role must have `cloudformation:*` permissions) - if you are using our shared dev account that is already granted.

### 2️⃣ Configure AWS Credentials

[Docs](https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/connect.html)

Run:

```sh
aws configure --profile lobby-playground
```

Or if you're already setup use/edit:

```sh
~/.aws/credentials
~/.aws/config
```

### 3️⃣ Setup Environment Variables

1. Copy the `.env_example` file to `.env`:

   ```sh
   cp .env_example .env
   ```

2. Update the `.env` file with **your OpenSearch credentials** and the necessary **Contentful credentials**:

---

## 🚀 Deployment

For OpenSearch deployment we use AWS cloudformation deploy. [Read More about why and how we deploy](docs/infra_deployment.md)

### 🔒 Secret Deployment

Before deploying your OpenSearch/API stack, run the `deploy-ssm.sh` script to push all sensitive values into SSM Parameter Store:

1. Make it executable:

   ```sh
   chmod +x deploy-ssm.sh
   ```

2. Execute it:

   ```sh
   ./deploy-ssm.sh
   ```

This script:

- Reads your `.env` variables
- Prompts for the target region (EU/US/Lab)
- Pushes each secret and configuration value into `/personalised-lobby/dev/...` in SSM

---

### 🚀 Stack Deployment

Deployment for the OpenSearch & API Gateway stack:

#### **Use Deployment Script**

1. Make the deploy script executable:

   ```sh
   chmod +x deploy.sh
   ```

2. Deploy with:

   ```sh
   ./deploy.sh
   ```

Alternatively, you can use the AWS CLI directly:

```sh
aws cloudformation deploy \
  --template-file templates/osGatewayDevStack.yml \
  --stack-name personalised-lobby-os-dev \
  --profile lobby-playground \
  --region eu-west-1
```

---

## 🛠 Managing Your Stack

### **Update Stack**

If you make changes to the template:

```sh
aws cloudformation update-stack \
  --template-file templates/osGatewayDevStack.yml \
  --stack-name personalised-lobby-os-dev \
  --profile lobby-playground \
  --region eu-west-1
```

### **Delete Stack**

To remove all resources:

```sh
aws cloudformation delete-stack --stack-name opensearch-demo-stack --profile lobby-playground
```

---

## 💡 Example API Call

After deployment, test your API Gateway:

```sh
curl -X GET "https://your-api-id.execute-api.eu-west-1.amazonaws.com/Dev/lobby/_cluster/health" \
  -u "os_master_user:os_master_pass"
```

Expected response:

```json
{
  "cluster_name": "lobby-opensearch",
  "status": "green",
  "number_of_nodes": 4
}
```

---

## Contributing to the project

Before contributing, please review and follow these guidelines to ensure smooth collaboration and maintain a clean and cost-efficient development environment.

### 🚀 General Contribution Rules

- All new stacks **must** be defined using a `.yml` file under the **template repo**.
- If you're adding to an **existing stack**, make sure to **reuse the same stack name** when deploying. Avoid creating duplicate stacks unless absolutely necessary.
- **Extending an existing stack:** ✅ Yes, you can extend a stack by adding/modifying resources in the `.yml` file.
- **Nuking a stack:** ❌ Not always required. Only destroy and recreate a stack if fundamental changes require a full rebuild.

### ✅ Deployment & Testing

- **Deploy secrets** first using `deploy-ssm.sh` to ensure all sensitive values are safely stored.
- **Every addition must be tested** before committing. This means:
  - Deploying resources in a separate **test environment**.
  - If you create resources for testing, **delete them immediately after** to avoid unnecessary AWS costs.
  - Avoid interfering with the main **development environment**.
- **Test in a different region:**
  - Our main region for Europe is **eu-west-1** for production/dev.
  - Our main region for the US is **us-east-1** for production/dev.
  - For testing, use a different region (e.g., **us-west-3**) to avoid conflicts.

### 💰 Cost Management

- **AWS resources that are not actively used must be deleted after testing.**
- If you deploy temporary resources, **track them and clean up** once done.
- Regularly review active stacks and remove anything obsolete to prevent excessive AWS billing.

### 🛠️ Code & Repo Cleanliness

- **Keep your commits clean and meaningful.** No unnecessary changes.
- **Follow naming conventions** for stacks and resources.
- **Document major changes** so the team knows what’s up.
- **PR reviews are required** before merging any changes.

### 💡 Best Practices

- Use **version control** for `.yml` files.
- **Automate** cleanup tasks where possible.
- Always **double-check before deleting** any shared resources.

## Useful References

- [AWS Infrastructure as Code](https://docs.aws.amazon.com/whitepapers/latest/introduction-devops-aws/infrastructure-as-code.html)
- [AWS Infrastructure Composer](https://docs.aws.amazon.com/pdfs/infrastructure-composer/latest/dg/infrastructure-composer.pdf)
