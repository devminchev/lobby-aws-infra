
# 🚀 Deployment details

## **Why Not AWS SAM?**

You might be wondering **why we’re using CloudFormation and not AWS SAM**.

### 🔥 TL;DR - Why Can’t We Deploy OpenSearch with SAM?

- ❌ SAM is for serverless apps, OpenSearch is not serverless.
- ❌ SAM doesn't support AWS::OpenSearchService::Domain.
- ✅ Use CloudFormation or AWS CLI instead.
- ✅ Best setup: SAM for Lambda/API Gateway, CloudFormation for OpenSearch.

### **1️⃣ AWS SAM is Only for Serverless Apps**

AWS SAM (Serverless Application Model) is specifically designed for **serverless applications**, like:

- Lambda Functions (🔥 The core of SAM)
- API Gateway (HTTP/REST APIs)
- DynamoDB (Serverless DBs)
- Step Functions
- S3, SNS, SQS, EventBridge (for event-driven stuff)

🔹 BUT… AWS SAM doesn’t support OpenSearch directly!
OpenSearch is not a serverless service—it’s an **AWS-managed service with dedicated infrastructure**, which SAM doesn’t handle.

- ❌ **Doesn’t support `AWS::OpenSearchService::Domain`**
- ❌ **Can’t deploy OpenSearch with `sam deploy` or `sam sync`**
- ❌ **Doesn’t show OpenSearch in AWS VS Code Toolkit**

### **2️⃣ How We Deploy OpenSearch Instead**

Since SAM doesn’t support OpenSearch, we use **CloudFormation**:
- ✅ **AWS Console** → Manual deployment  
- ✅ **AWS CLI** → `aws cloudformation deploy`  
- ✅ **CloudFormation Templates** → Automate everything  

### What’s the Best Way to Manage Everything?

If you want SAM & CloudFormation to work together, the best way is:

#### Option 1: Use SAM for Serverless, CloudFormation for OpenSearch

- SAM: Deploy Lambda & API Gateway.
- CloudFormation: Deploy OpenSearch as a separate stack.
- Glue them together by passing OpenSearch DomainEndpoint as an environment variable to SAM.

#### Option 2: Use AWS CDK (Cloud Development Kit)

- CDK can deploy both OpenSearch & Lambda in one go.
- Uses programming languages (TypeScript, Python, etc.).
- More modern & flexible than CloudFormation.
