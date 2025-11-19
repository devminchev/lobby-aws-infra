# Lobby AWS Infra

Automated infrastructure and operational scripts for deploying the Personalised Lobby OpenSearch stack, managing Contentful secrets, and synchronising Lambda deployment data with the internal version dashboard.

## 🌍 Project Purpose

This repository exists to make it easy for engineers to:

1. **Bootstrap OpenSearch + API Gateway dev stacks** across EU, US, Lab, and Gen‑AI AWS accounts using a single CloudFormation template and wrapper script.
2. **Publish sensitive configuration** (Contentful tokens, OpenSearch credentials, runtime flags) into AWS Systems Manager Parameter Store in a consistent, auditable way.
3. **Inspect and update live Lambda versions** that power the lobby backend so Product & Ops teams always know which container images are running in staging/production.

The scripts are intentionally lightweight (Bash + Node.js) so they can run from any developer workstation or CI runner without additional tooling.

## 🧰 Tech Stack

| Area | Technology | Purpose |
| --- | --- | --- |
| Infrastructure as Code | **AWS CloudFormation** templates (`templates/`) | Define OpenSearch domains, API Gateway proxies, and Parameter Store entries. |
| Automation scripts | **Bash** (`deploy.sh`, `deploy-ssm.sh`, `scripts/*.sh`) | Wrap CloudFormation CLI commands, fetch Lambda metadata, and query Consul. |
| Runtime scripting | **Node.js 18+** (`node_scripts/*.js`) | Post-process Bash output and orchestrate version dashboard updates. |
| Secrets/config | **AWS Systems Manager Parameter Store** | Stores Contentful, OpenSearch, and runtime settings per environment. |
| Observability | **AWS X-Ray toggle** | Controlled via Parameter Store to trace Lambda invocations when enabled. |

## 🏗️ Architecture Overview

High level components:

1. **OpenSearch Domain** – defined in `templates/osGatewayDevStack*.yml` with encrypted storage, HTTPS-only endpoints, node-to-node encryption, and optional EU/US variants.
2. **API Gateway HTTP proxy** – created via the same template and exposes `/lobby/{proxy+}` to securely tunnel requests to OpenSearch without exposing the domain publicly.
3. **Parameter Store stack** – `templates/parameterStoreVariables.yml` provisions `/personalised-lobby/dev/*` keys for Contentful + OpenSearch configuration, populated via `deploy-ssm.sh`.
4. **Operational tooling** – Bash scripts collect Lambda image tags, while Node scripts map them to Consul version dashboard entries for staging/production environments.

```
Developer Laptop ─┬─ deploy-ssm.sh ──▶ CloudFormation stack: Parameter Store secrets
                  ├─ deploy.sh ─────▶ CloudFormation stack: OpenSearch + API Gateway
                  └─ versionDashboardUpdate.js ─▶ Consul version dashboard via proxy
```

## 📁 Repository Structure

```
.
├── deploy.sh / deploy-ssm.sh       # Wrapper scripts for CloudFormation deployments
├── templates/                      # CloudFormation templates (OpenSearch, Parameter Store, variants)
├── scripts/                        # Bash helpers (Lambda version discovery, dashboard reads)
├── node_scripts/                   # Node utilities for Consul version management
├── docs/infra_deployment.md        # Notes on why CloudFormation (not SAM) is used
└── Readme.md                       # You are here
```

## 🚀 Getting Started

### 1. Prerequisites

- AWS CLI v2 with access to the relevant sandbox/prod accounts.
- Optional: AWS Toolkit for VS Code if you prefer a UI for credential/profile switching.
- Node.js 18+ for the `node_scripts` utilities.
- `curl` available on your PATH (used by scripts + Consul interactions).

### 2. Configure AWS credentials

Create or update the named profiles referenced by the scripts (e.g. `lobby-playground`, `lobby-playground-us`, etc.).

```sh
aws configure --profile lobby-playground
```

Repeat for every AWS account you need to target. Credentials live in `~/.aws/credentials` and `~/.aws/config`.

### 3. Prepare environment variables

Copy the sample environment file and fill in all placeholders:

```sh
cp .env_example .env
```

Populate it with:

- Shared values (`CONTENTFUL_ENVIRONMENT`, `ENABLE_XRAY`, `EXECUTION_ENVIRONMENT`, ...)
- Region-specific secrets prefixed with `EU_`, `US_`, `LAB_`, or `GEN_AI_` (e.g. `EU_CONTENTFUL_ACCESS_TOKEN`).
- AWS profile names (`EU_AWS_PROFILE`, etc.).

## 🔐 Deploying Parameter Store secrets

Run `deploy-ssm.sh` before any infrastructure stack so secrets exist ahead of time.

```sh
chmod +x deploy-ssm.sh
./deploy-ssm.sh
```

What the script does:

1. Loads `.env` and validates every required variable.
2. Prompts for the target region/account.
3. Converts variable names to CamelCase parameters.
4. Invokes `aws cloudformation deploy` with `templates/parameterStoreVariables.yml` to create/update the `/personalised-lobby/dev/*` keys.

## 🏗️ Deploying OpenSearch + API Gateway

Use the wrapper script to deploy into EU, US, Lab, or Gen-AI spaces. It automatically picks the right template, stack name, and profile for the region.

```sh
chmod +x deploy.sh
./deploy.sh
```

Under the hood it calls:

```sh
aws cloudformation deploy \
  --template-file templates/osGatewayDevStack.yml \
  --stack-name personalised-lobby-os-dev \
  --profile lobby-playground \
  --region eu-west-1 \
  --parameter-overrides MasterUserName=... MasterUserPassword=...
```

### Managing the stack manually

- **Update:** rerun `aws cloudformation deploy` with your modified template.
- **Delete:** `aws cloudformation delete-stack --stack-name personalised-lobby-os-dev --profile <profile>`.

## 📡 Version Dashboard Workflows

### Discover deployed Lambda container versions

`scripts/get_latest_deployed_lambda_versions.sh` scans all Lambda functions in the configured account/region and prints the parsed Docker tag.

```sh
./scripts/get_latest_deployed_lambda_versions.sh
```

### Read dashboard values via Consul proxy

`scripts/get_deployed_versions_vers_dash.sh [stg|prod|instance]` fetches `versions/coreplatform/<instance>` keys and prints a formatted table.

### Sync Lambda versions to the dashboard

`node_scripts/versionDashboardUpdate.js` combines the Bash output with a Lambda↔component map and prepares curl commands.

Manual mode (default) writes JSON payloads to `out/version_dashboard_curls.json` for inspection:

```sh
ENV=stg MODE=manual node node_scripts/versionDashboardUpdate.js
```

Auto mode executes PUTs immediately and verifies each value:

```sh
ENV=prod MODE=auto node node_scripts/versionDashboardUpdate.js
```

### Inspect current dashboard state

`node node_scripts/getDeployedVersions.js` prints tables for staging and production components directly from Consul using the configured proxy.

## 🧭 Additional Documentation

- `docs/infra_deployment.md` explains why OpenSearch must be deployed via CloudFormation (SAM does not support `AWS::OpenSearchService::Domain`) and outlines alternative IaC options such as AWS CDK.

## 🤝 Contributing Guidelines

1. **Define infrastructure in YAML** – each new stack or resource change should live under `templates/`.
2. **Reuse stack names** – extend existing stacks rather than creating duplicates unless you intentionally need an isolated stack.
3. **Test safely** – deploy experiments to alternate regions (e.g., `us-west-2`) and delete temporary resources to avoid unnecessary AWS spend.
4. **Secrets first** – always run `deploy-ssm.sh` before rolling out infra so CloudFormation resolves parameter references successfully.
5. **Keep commits focused** – document major changes in the README/docs and submit PRs for review before merging.
6. **Cleanup** – tear down unused stacks and parameters after testing to keep AWS costs predictable.

## 🙋 FAQ for New Contributors

- **Can we use AWS SAM for OpenSearch?** No. SAM targets serverless resources only. Use the provided CloudFormation templates or migrate to AWS CDK for unified stacks.
- **How do Lambda versions reach the dashboard?** Bash scripts fetch image tags; Node scripts map them to Consul keys and either emit curl commands or push updates automatically via a corporate proxy.
- **Where do Contentful credentials live?** They are stored in `/personalised-lobby/dev/*` Parameter Store keys, provisioned through the dedicated template and populated via `deploy-ssm.sh`.

Welcome aboard! Use this guide to get the stack running locally, keep secrets safe, and maintain observability over deployed Lambda versions.
