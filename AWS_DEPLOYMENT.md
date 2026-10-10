# 💧 AquaGuard AI — AWS Cloud Architecture & Deployment Guide
### Built for AWS Environmental Hacks Hackathon

**AquaGuard AI** is an AI-powered water contamination reporting and smart complaint routing system designed to safeguard community drinking water and aquatic ecosystems. This document details the AWS cloud architecture, deployment blueprints, and environment configurations.

---

## 🏗️ 1. Architecture Overview

AquaGuard AI follows a resilient, decoupled cloud architecture designed to run seamlessly both in local development and on AWS cloud services:

```
[ Citizen & Officer Web Clients ]
              │ (HTTPS)
              ▼
   [ AWS CloudFront (CDN) / Amazon S3 ]
              │
              ▼
    [ Application Load Balancer / Amazon ECS (Fargate) ]
              │
              ├──► [ Roboflow Cloud Serverless Vision API ]
              │      (Pre-built Water Pollution Model)
              │
              ├──► [ Amazon RDS for PostgreSQL ] (Database Persistence)
              │
              ├──► [ Amazon S3 ] (Object Storage for Contamination Photos)
              │
              └──► [ Amazon SNS ] (Real-time Officer SMS/Email Alerts)
```

---

## ☁️ 2. AWS Services Mapped to Solution Components

| AWS Service | AquaGuard AI Integration Role | Status in Local Dev | Status in Production AWS |
| :--- | :--- | :--- | :--- |
| **Amazon RDS for PostgreSQL** | Persistent relational storage for complaints, departments, audit logs, and AI telemetry | Connected via local PostgreSQL 18 instance (`aquaguard_db`) | Managed multi-AZ PostgreSQL 15/16 database |
| **Amazon S3** | Secure, scalable storage for high-resolution water contamination images | Local `/uploads/` filesystem disk storage | S3 Bucket with pre-signed upload URLs & public read policy |
| **Amazon SNS** | Automated alerts to water department officers on emergency high-priority incidents | Handled via configured SMTP / Nodemailer logger | SNS Topic subscribing officer emails and SMS numbers |
| **Amazon ECS (Fargate)** | Containerized backend Node.js / Express REST API deployment | Local Node.js v20 engine running on port `5000` | Serverless container execution with auto-scaling |
| **AWS CloudFront** | Low-latency global CDN edge delivery for citizen web portals and map tiles | Served directly via Express static asset middleware | Global HTTPS edge caching for high responsiveness |
| **AWS Secrets Manager** | Encrypted storage for Roboflow API keys and DB credentials | Managed via `.env` file | Integrated via AWS IAM Task Roles |

---

## 🚀 3. Environment Variables & Configuration

AquaGuard AI dynamically detects whether AWS cloud credentials are present:
- When AWS environment variables (`AWS_S3_BUCKET_NAME`, `AWS_SNS_TOPIC_ARN`) are provided, the backend seamlessly routes uploads and notifications through AWS SDK.
- When absent, the application gracefully uses zero-dependency local disk storage and local SMTP emulation, enabling immediate evaluation on local machines.

### Required Configuration Template (`backend/.env`):
```env
# Server
PORT=5000
NODE_ENV=development

# Database (Amazon RDS for PostgreSQL or Local Instance)
DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:5433/aquaguard_db
PGHOST=127.0.0.1
PGPORT=5433
PGUSER=postgres
PGPASSWORD=postgres
PGDATABASE=aquaguard_db
PGSSL=false

# Roboflow Pre-Built Computer Vision Model
ROBOFLOW_API_KEY=tiuCwSKgFd2lAPoP2dlT
ROBOFLOW_MODEL_ID=water-pollution-6ekuv-iqw6f/1
ROBOFLOW_API_URL=https://serverless.roboflow.com
ROBOFLOW_CONFIDENCE_THRESHOLD=0.30
DEMO_MODE=false

# AWS Cloud Services Integration (Optional for local test, populated in AWS)
AWS_REGION=us-east-1
AWS_S3_BUCKET_NAME=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_SNS_TOPIC_ARN=
```

---

## 🛠️ 4. Step-by-Step AWS Deployment Blueprint

### Step 4.1: Deploy PostgreSQL on Amazon RDS
```bash
aws rds create-db-instance \
    --db-instance-identifier aquaguard-db \
    --db-instance-class db.t4g.micro \
    --engine postgres \
    --allocated-storage 20 \
    --master-username postgres \
    --master-user-password YourSecurePassword123! \
    --backup-retention-period 7
```
Once provisioned, execute the database schema:
```bash
psql -h <RDS_ENDPOINT> -U postgres -d postgres -f backend/schema.sql
```

### Step 4.2: Create Amazon S3 Bucket for Contamination Images
```bash
aws s3api create-bucket \
    --bucket aquaguard-incident-photos \
    --region us-east-1
```

### Step 4.3: Deploy Container to Amazon ECS Fargate
1. Build and push container to Amazon ECR:
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
docker build -t aquaguard-backend .
docker tag aquaguard-backend:latest <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/aquaguard-backend:latest
docker push <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/aquaguard-backend:latest
```
2. Launch ECS Service with Application Load Balancer.

---

## 🧪 5. Testing & Verification
Run the integrated test suite locally or in CI/CD pipeline:
```bash
cd backend
npm test
```
The test suite validates:
1. Health and AI model telemetry check.
2. Roboflow live inference API connection and JSON response validation.
3. PostgreSQL connection, table schema, and parameterized record persistence.
4. Department lifecycle status transitions (NEW → IN PROGRESS → RESOLVED).
5. Aggregated real-time metrics for municipal administrators.
