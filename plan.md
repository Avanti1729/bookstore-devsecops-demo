# DevSecOps Bookstore Demo — Complete Executable Plan

> **Project:** `bookstore-devsecops-demo`
> **Goal:** Build a simple NodeJS BookStore API and push it through a full DevSecOps pipeline, introducing one deliberate security issue per phase so each tool catches it.
> **Rule:** Complete one phase, verify it works, commit to GitHub, then move on.

---

## Table of Contents

- [Phase 0 — Local Application](#phase-0--local-application)
- [Phase 1 — GitHub](#phase-1--github)
- [Phase 2 — GitHub Actions](#phase-2--github-actions)
- [Phase 3 — GitLeaks](#phase-3--gitleaks)
- [Phase 4 — SonarQube](#phase-4--sonarqube)
- [Phase 5 — Snyk](#phase-5--snyk)
- [Phase 6 — Docker Build](#phase-6--docker-build)
- [Phase 7 — Trivy Scan](#phase-7--trivy-scan)
- [Phase 8 — Terraform](#phase-8--terraform)
- [Phase 9 — Checkov](#phase-9--checkov)
- [Phase 10 — ECR](#phase-10--ecr)
- [Phase 11 — EKS](#phase-11--eks)
- [Phase 12 — Kubernetes](#phase-12--kubernetes)
- [Phase 13 — Prometheus](#phase-13--prometheus)
- [Phase 14 — Grafana](#phase-14--grafana)
- [Phase 15 — Loki](#phase-15--loki)
- [Phase 16 — Alertmanager](#phase-16--alertmanager)
- [Phase 17 — Falco](#phase-17--falco)
- [Phase 18 — GuardDuty](#phase-18--guardduty)
- [Phase 19 — AWS Security Hub](#phase-19--aws-security-hub)

---

## Phase 0 — Local Application

**Goal:** Running NodeJS API with three endpoints.
**Security Issue Planted:** None yet. Clean baseline.
**Demo:** Show the app running locally before any pipeline exists.

### Step 0.1 — Create Folder Structure

```bash
mkdir bookstore-devsecops-demo
cd bookstore-devsecops-demo
mkdir app
cd app
```

### Step 0.2 — Initialize Node Project

```bash
npm init -y
npm install express
```

### Step 0.3 — Create `app/books.json`

```json
[
  { "id": 1, "name": "AWS Basics" },
  { "id": 2, "name": "Terraform Guide" }
]
```

### Step 0.4 — Create `app/server.js`

```js
const express = require("express");
const books = require("./books.json");

const app = express();
app.use(express.json());

app.get("/health", (req, res) => {
  res.send("Application Healthy");
});

app.get("/books", (req, res) => {
  res.json(books);
});

app.post("/login", (req, res) => {
  const { username, password } = req.body;
  if (username === "admin" && password === "admin123") {
    return res.json({ message: "Login Success" });
  }
  res.status(401).json({ message: "Invalid Credentials" });
});

app.listen(3000, () => {
  console.log("Running on Port 3000");
});
```

### Step 0.5 — Run and Test Locally

```bash
node server.js
```

```bash
# Health
curl localhost:3000/health

# Books
curl localhost:3000/books

# Login
curl -X POST localhost:3000/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

**Expected Outputs:**

```
Application Healthy
[{"id":1,"name":"AWS Basics"},{"id":2,"name":"Terraform Guide"}]
{"message":"Login Success"}
```

---

## Phase 1 — GitHub

**Goal:** Push project to GitHub with clean structure.
**Demo:** Show the repo structure before any CI/CD.

### Step 1.1 — Create `.gitignore`

```
node_modules/
.env
*.log
```

### Step 1.2 — Create `README.md`

```markdown
# BookStore DevSecOps Demo

A simple NodeJS BookStore API used to demonstrate a full DevSecOps pipeline.

## Endpoints
- GET  /health
- GET  /books
- POST /login

## Stack
- NodeJS / Express
- GitHub Actions
- GitLeaks, SonarQube, Snyk, Checkov
- Docker, Trivy, ECR, EKS
- Prometheus, Grafana, Loki, Alertmanager
- Falco, GuardDuty, AWS Security Hub
```

### Step 1.3 — Initialize Git and Push

```bash
cd bookstore-devsecops-demo

git init
git add .
git commit -m "phase-0: initial bookstore api"

# Create repo on GitHub (via UI or CLI)
gh repo create bookstore-devsecops-demo --public

git remote add origin https://github.com/YOUR_USERNAME/bookstore-devsecops-demo.git
git branch -M main
git push -u origin main
```

### Step 1.4 — Verify on GitHub

Open `https://github.com/YOUR_USERNAME/bookstore-devsecops-demo` and confirm files are visible.

---

## Phase 2 — GitHub Actions

**Goal:** Create a CI pipeline that triggers on every push.
**Demo:** Push code → GitHub Actions triggers → pipeline runs.

### Step 2.1 — Create Workflow Directory

```bash
mkdir -p .github/workflows
```

### Step 2.2 — Create `.github/workflows/pipeline.yml`

```yaml
name: DevSecOps Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Dependencies
        run: |
          cd app
          npm install

      - name: Run Health Check
        run: |
          cd app
          node server.js &
          sleep 2
          curl -f http://localhost:3000/health
          kill %1
```

### Step 2.3 — Commit and Push

```bash
git add .github/
git commit -m "phase-2: add github actions pipeline"
git push
```

### Step 2.4 — Verify

Go to **GitHub → Actions tab** and confirm the pipeline runs green.

---

## Phase 3 — GitLeaks

**Goal:** Detect hardcoded secrets in source code.
**Security Issue Planted:** Hardcoded AWS credential in `server.js`.
**Demo:** Developer accidentally commits a secret → GitLeaks blocks the pipeline.

### Step 3.1 — Plant the Secret (Deliberate)

Add this line to `app/server.js` near the top:

```js
// TODO: move to env
const AWS_SECRET_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE123456";
```

### Step 3.2 — Add GitLeaks to Pipeline

Append this job to `.github/workflows/pipeline.yml`:

```yaml
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: Run GitLeaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Step 3.3 — Commit and Push

```bash
git add .
git commit -m "phase-3: planted hardcoded aws key for gitleaks demo"
git push
```

### Step 3.4 — Observe Pipeline Failure

In **GitHub → Actions**, the `gitleaks` job will fail with:

```
WARN Secret detected in commit: AKIAIOSFODNN7EXAMPLE123456
LEAK: rule=aws-access-token file=app/server.js
```

### Step 3.5 — Fix (After Demo)

Remove the hardcoded key. Use environment variable instead:

```js
const AWS_SECRET_ACCESS_KEY = process.env.AWS_SECRET_ACCESS_KEY;
```

```bash
git add .
git commit -m "phase-3-fix: remove hardcoded secret, use env var"
git push
```

---

## Phase 4 — SonarQube

**Goal:** Detect code smells and security hotspots.
**Security Issue Planted:** Use of `eval()` with user input.
**Demo:** Static code analysis catches dangerous code patterns.

### Step 4.1 — Plant the Vulnerable Code

Add a new endpoint to `app/server.js`:

```js
// DEMO: dangerous eval endpoint — never do this
app.post("/run", (req, res) => {
  const result = eval(req.body.code);
  res.json({ result });
});
```

### Step 4.2 — Set Up SonarQube (Self-hosted for demo)

```bash
# Run SonarQube locally via Docker
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  sonarqube:lts-community
```

Wait ~60 seconds, then open `http://localhost:9000`.
Default login: `admin / admin`.

### Step 4.3 — Create `sonar-project.properties`

```properties
sonar.projectKey=bookstore-devsecops-demo
sonar.projectName=BookStore DevSecOps Demo
sonar.projectVersion=1.0
sonar.sources=app
sonar.language=js
sonar.sourceEncoding=UTF-8
```

### Step 4.4 — Add SonarQube to Pipeline

Add to `.github/workflows/pipeline.yml`:

```yaml
  sonarqube:
    runs-on: ubuntu-latest
    needs: gitleaks
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
```

### Step 4.5 — Add Secrets to GitHub

In **GitHub → Settings → Secrets → Actions**:

```
SONAR_TOKEN      = <token from SonarQube UI>
SONAR_HOST_URL   = http://YOUR_PUBLIC_IP:9000
```

### Step 4.6 — Commit and Push

```bash
git add .
git commit -m "phase-4: add eval endpoint for sonarqube demo"
git push
```

### Step 4.7 — Observe in SonarQube

Open `http://localhost:9000` → your project → **Security Hotspots**:

```
Security Hotspot: eval() used with user-controlled data
Severity: HIGH
File: app/server.js
```

### Step 4.8 — Fix (After Demo)

Remove the `/run` endpoint entirely or replace with a safe alternative.

```bash
git add .
git commit -m "phase-4-fix: remove eval endpoint"
git push
```

---

## Phase 5 — Snyk

**Goal:** Detect vulnerable third-party dependencies.
**Security Issue Planted:** Old version of `lodash` with known Prototype Pollution CVE.
**Demo:** Application code looks fine but the library is vulnerable.

### Step 5.1 — Install Vulnerable Dependency

```bash
cd app
npm install lodash@4.17.11
```

### Step 5.2 — Use It in `server.js`

```js
const _ = require("lodash");

app.get("/books", (req, res) => {
  const sorted = _.sortBy(books, "name");
  res.json(sorted);
});
```

### Step 5.3 — Add Snyk to Pipeline

```yaml
  snyk:
    runs-on: ubuntu-latest
    needs: sonarqube
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Dependencies
        run: |
          cd app
          npm install

      - name: Run Snyk
        uses: snyk/actions/node@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
        with:
          args: --file=app/package.json --severity-threshold=high
```

### Step 5.4 — Add Snyk Token to GitHub Secrets

- Sign up at `https://snyk.io`
- Get token from **Account Settings**
- Add to GitHub Secrets as `SNYK_TOKEN`

### Step 5.5 — Commit and Push

```bash
git add .
git commit -m "phase-5: add vulnerable lodash for snyk demo"
git push
```

### Step 5.6 — Observe Snyk Output

In **GitHub → Actions → snyk job**:

```
✗ High severity vulnerability found in lodash
  Description: Prototype Pollution
  Info: https://snyk.io/vuln/SNYK-JS-LODASH-567746
  Introduced through: lodash@4.17.11
```

### Step 5.7 — Fix (After Demo)

```bash
cd app
npm install lodash@latest
git add .
git commit -m "phase-5-fix: upgrade lodash to safe version"
git push
```

---

## Phase 6 — Docker Build

**Goal:** Package the application into a Docker image.
**Demo:** Show application containerised. No security issues yet in this phase.

### Step 6.1 — Create `Dockerfile`

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY app/package*.json ./
RUN npm install --production

COPY app/ .

EXPOSE 3000

CMD ["node", "server.js"]
```

### Step 6.2 — Create `.dockerignore`

```
node_modules
.git
*.log
.env
```

### Step 6.3 — Build and Test Locally

```bash
docker build -t bookstore:latest .

docker run -d -p 3000:3000 --name bookstore bookstore:latest

curl localhost:3000/health
# Output: Application Healthy

docker stop bookstore
docker rm bookstore
```

### Step 6.4 — Add Docker Build to Pipeline

```yaml
  docker-build:
    runs-on: ubuntu-latest
    needs: snyk
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Build Docker Image
        run: docker build -t bookstore:${{ github.sha }} .
```

### Step 6.5 — Commit and Push

```bash
git add Dockerfile .dockerignore .github/
git commit -m "phase-6: add dockerfile and docker build step"
git push
```

---

## Phase 7 — Trivy Scan

**Goal:** Scan Docker image for OS and package-level CVEs.
**Security Issue Planted:** Switch to old base image with known vulnerabilities.
**Demo:** Application code is fine but the container OS has critical CVEs.

### Step 7.1 — Plant Vulnerable Base Image

Change the first line of `Dockerfile`:

```dockerfile
FROM node:16
```

> `node:16` (older image) contains known OS-level CVEs that Trivy will catch.

### Step 7.2 — Add Trivy to Pipeline

```yaml
  trivy:
    runs-on: ubuntu-latest
    needs: docker-build
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Build Image for Scanning
        run: docker build -t bookstore:${{ github.sha }} .

      - name: Run Trivy Vulnerability Scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: bookstore:${{ github.sha }}
          format: table
          exit-code: '1'
          ignore-unfixed: false
          severity: 'CRITICAL,HIGH'
```

### Step 7.3 — Commit and Push

```bash
git add .
git commit -m "phase-7: use old node:16 base image for trivy demo"
git push
```

### Step 7.4 — Observe Trivy Output

In **GitHub → Actions → trivy job**:

```
┌──────────────────────┬────────────────┬──────────┬──────────────────────┐
│ Library              │ Vulnerability  │ Severity │ Title                │
├──────────────────────┼────────────────┼──────────┼──────────────────────┤
│ openssl              │ CVE-XXXX-XXXX  │ CRITICAL │ OpenSSL vuln ...     │
│ curl                 │ CVE-XXXX-XXXX  │ HIGH     │ Curl buffer ...      │
└──────────────────────┴────────────────┴──────────┴──────────────────────┘
```

### Step 7.5 — Fix (After Demo)

```dockerfile
FROM node:18-alpine
```

```bash
git add .
git commit -m "phase-7-fix: upgrade to node:18-alpine secure base image"
git push
```

---

## Phase 8 — Terraform

**Goal:** Write Infrastructure-as-Code for VPC, ECR, EKS, and IAM.
**Demo:** Infrastructure created automatically from code.

### Step 8.1 — Create Terraform Directory

```bash
mkdir terraform
cd terraform
```

### Step 8.2 — Create `terraform/providers.tf`

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}
```

### Step 8.3 — Create `terraform/variables.tf`

```hcl
variable "project_name" {
  default = "bookstore-demo"
}

variable "region" {
  default = "us-east-1"
}
```

### Step 8.4 — Create `terraform/vpc.tf`

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.project_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Project = var.project_name
  }
}
```

### Step 8.5 — Create `terraform/ecr.tf`

```hcl
resource "aws_ecr_repository" "bookstore" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = var.project_name
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.bookstore.repository_url
}
```

### Step 8.6 — Create `terraform/eks.tf`

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.0.0"

  cluster_name    = "${var.project_name}-cluster"
  cluster_version = "1.27"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_groups = {
    default = {
      min_size       = 1
      max_size       = 2
      desired_size   = 1
      instance_types = ["t3.medium"]
    }
  }

  tags = {
    Project = var.project_name
  }
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}
```

### Step 8.7 — Init and Plan Locally

```bash
cd terraform
terraform init
terraform plan
```

Confirm plan shows resources to create. Do **not** apply yet (that comes after Checkov).

---

## Phase 9 — Checkov

**Goal:** Scan Terraform files for IaC misconfigurations.
**Security Issue Planted:** Security Group with SSH open to the world.
**Demo:** Checkov catches infrastructure-level security problems before apply.

### Step 9.1 — Plant Vulnerable Security Group

Create `terraform/security_group.tf`:

```hcl
resource "aws_security_group" "web" {
  name   = "${var.project_name}-web-sg"
  vpc_id = module.vpc.vpc_id

  # DEMO: SSH open to the entire internet — never do this
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
  }
}
```

### Step 9.2 — Add Checkov to Pipeline

```yaml
  checkov:
    runs-on: ubuntu-latest
    needs: trivy
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Run Checkov
        uses: bridgecrewio/checkov-action@master
        with:
          directory: terraform/
          framework: terraform
          soft_fail: false
```

### Step 9.3 — Commit and Push

```bash
git add terraform/ .github/
git commit -m "phase-9: add terraform with open ssh sg for checkov demo"
git push
```

### Step 9.4 — Observe Checkov Output

In **GitHub → Actions → checkov job**:

```
Check: CKV_AWS_25: "Ensure no security groups allow ingress from 0.0.0.0:0 to port 22"
FAILED for resource: aws_security_group.web
File: /terraform/security_group.tf
```

### Step 9.5 — Fix (After Demo)

```hcl
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]   # internal only
  }
```

```bash
git add .
git commit -m "phase-9-fix: restrict ssh to internal cidr only"
git push
```

---

## Phase 10 — ECR

**Goal:** Push Docker image to Amazon ECR.
**Demo:** Promote the verified image to a registry; show ECR scanning results.

### Step 10.1 — Apply Terraform to Create ECR

```bash
cd terraform
terraform apply -target=aws_ecr_repository.bookstore -auto-approve
```

Note the `ecr_repository_url` from output.

### Step 10.2 — Push Image Manually (First Time)

```bash
export ECR_URL=<your_ecr_url>
export AWS_REGION=us-east-1

aws ecr get-login-password --region $AWS_REGION \
  | docker login --username AWS --password-stdin $ECR_URL

docker build -t bookstore:latest .
docker tag bookstore:latest $ECR_URL:latest
docker push $ECR_URL:latest
```

### Step 10.3 — Add ECR Push to Pipeline

Add secrets to GitHub: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_ACCOUNT_ID`.

```yaml
  push-to-ecr:
    runs-on: ubuntu-latest
    needs: checkov
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Login to ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build and Push Image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          ECR_REPOSITORY: bookstore-demo
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
```

### Step 10.4 — Commit and Push

```bash
git add .github/
git commit -m "phase-10: add ecr push step to pipeline"
git push
```

---

## Phase 11 — EKS

**Goal:** Provision the Kubernetes cluster.
**Demo:** Show infrastructure provisioned automatically from Terraform.

### Step 11.1 — Apply Full Terraform

```bash
cd terraform
terraform apply -auto-approve
```

> This will take 10–15 minutes (EKS cluster creation).

### Step 11.2 — Configure kubectl

```bash
aws eks update-kubeconfig \
  --name bookstore-demo-cluster \
  --region us-east-1
```

### Step 11.3 — Verify Cluster

```bash
kubectl get nodes
kubectl get namespaces
```

Expected:

```
NAME          STATUS   ROLES    AGE
ip-10-0-x-x   Ready    <none>   2m
```

---

## Phase 12 — Kubernetes

**Goal:** Deploy the BookStore application to EKS.
**Demo:** Application running in Kubernetes, accessible via LoadBalancer.

### Step 12.1 — Create `k8s/` Directory

```bash
mkdir k8s
```

### Step 12.2 — Create `k8s/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bookstore
  namespace: default
  labels:
    app: bookstore
spec:
  replicas: 1
  selector:
    matchLabels:
      app: bookstore
  template:
    metadata:
      labels:
        app: bookstore
    spec:
      containers:
        - name: bookstore
          image: <YOUR_ECR_URL>:latest
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: "100m"
              memory: "128Mi"
            limits:
              cpu: "500m"
              memory: "256Mi"
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
```

### Step 12.3 — Create `k8s/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: bookstore-service
  namespace: default
spec:
  selector:
    app: bookstore
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: LoadBalancer
```

### Step 12.4 — Deploy to EKS

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

### Step 12.5 — Verify

```bash
kubectl get pods
kubectl get svc bookstore-service
```

Wait for the `EXTERNAL-IP` to appear (2–3 minutes), then:

```bash
export LB_URL=$(kubectl get svc bookstore-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
curl http://$LB_URL/health
curl http://$LB_URL/books
```

### Step 12.6 — Add Deploy Step to Pipeline

```yaml
  deploy-to-eks:
    runs-on: ubuntu-latest
    needs: push-to-ecr
    steps:
      - name: Checkout Code
        uses: actions/checkout@v3

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v2
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: us-east-1

      - name: Configure kubectl
        run: |
          aws eks update-kubeconfig \
            --name bookstore-demo-cluster \
            --region us-east-1

      - name: Update Image in Deployment
        env:
          ECR_REGISTRY: ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com
          ECR_REPOSITORY: bookstore-demo
          IMAGE_TAG: ${{ github.sha }}
        run: |
          kubectl set image deployment/bookstore \
            bookstore=$ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG

      - name: Wait for Rollout
        run: kubectl rollout status deployment/bookstore
```

---

## Phase 13 — Prometheus

**Goal:** Scrape metrics from the application and cluster.
**Demo:** Generate load → watch CPU and memory spike in real time.

### Step 13.1 — Install Prometheus via Helm

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
```

### Step 13.2 — Verify Prometheus Pods

```bash
kubectl get pods -n monitoring
```

### Step 13.3 — Add Metrics Endpoint to `server.js`

```bash
cd app
npm install prom-client
```

Add to `server.js`:

```js
const client = require("prom-client");
const register = new client.Registry();
client.collectDefaultMetrics({ register });

app.get("/metrics", async (req, res) => {
  res.set("Content-Type", register.contentType);
  res.end(await register.metrics());
});
```

### Step 13.4 — Create `k8s/servicemonitor.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: bookstore-monitor
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: bookstore
  endpoints:
    - port: http
      path: /metrics
      interval: 15s
  namespaceSelector:
    matchNames:
      - default
```

```bash
kubectl apply -f k8s/servicemonitor.yaml
```

### Step 13.5 — Generate Load

```bash
# Install hey load testing tool
go install github.com/rakyll/hey@latest

export LB_URL=<your_lb_url>
hey -n 1000 -c 50 http://$LB_URL/books
```

### Step 13.6 — Access Prometheus UI

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus 9090:9090 -n monitoring
```

Open `http://localhost:9090` and query:

```
rate(http_requests_total[1m])
container_cpu_usage_seconds_total{pod=~"bookstore.*"}
```

---

## Phase 14 — Grafana

**Goal:** Visualize Prometheus metrics in dashboards.
**Demo:** Generate traffic → watch the Grafana dashboard update live.

### Step 14.1 — Install Grafana

```bash
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set adminPassword=admin123 \
  --set service.type=LoadBalancer
```

```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

### Step 14.2 — Get Grafana URL

```bash
kubectl get svc grafana -n monitoring
```

Access via `EXTERNAL-IP` or port-forward:

```bash
kubectl port-forward svc/grafana 3001:80 -n monitoring
```

Open `http://localhost:3001` — login: `admin / admin123`.

### Step 14.3 — Add Prometheus Data Source

In Grafana UI:
1. **Configuration → Data Sources → Add data source**
2. Select **Prometheus**
3. URL: `http://prometheus-kube-prometheus-prometheus.monitoring.svc:9090`
4. Click **Save & Test**

### Step 14.4 — Import Dashboard

1. **Dashboards → Import**
2. Import Dashboard ID: **6417** (Kubernetes Cluster Monitoring)
3. Select Prometheus data source
4. Click **Import**

### Step 14.5 — Create Custom Bookstore Dashboard

In Grafana, create a new dashboard with these panels:

**Panel 1 — HTTP Requests/sec:**
```
rate(http_requests_total[1m])
```

**Panel 2 — CPU Usage:**
```
sum(rate(container_cpu_usage_seconds_total{pod=~"bookstore.*"}[1m]))
```

**Panel 3 — Memory Usage:**
```
sum(container_memory_usage_bytes{pod=~"bookstore.*"})
```

**Panel 4 — Pod Restart Count:**
```
kube_pod_container_status_restarts_total{pod=~"bookstore.*"}
```

---

## Phase 15 — Loki

**Goal:** Aggregate and search application logs.
**Demo:** Trigger failed logins → find them instantly in Loki.

### Step 15.1 — Install Loki and Promtail

```bash
helm install loki grafana/loki-stack \
  --namespace monitoring \
  --set grafana.enabled=false \
  --set prometheus.enabled=false \
  --set promtail.enabled=true
```

### Step 15.2 — Add Loki Data Source to Grafana

In Grafana UI:
1. **Configuration → Data Sources → Add data source**
2. Select **Loki**
3. URL: `http://loki.monitoring.svc:3100`
4. Click **Save & Test**

### Step 15.3 — Improve Logging in `server.js`

```js
app.post("/login", (req, res) => {
  const { username, password } = req.body;

  if (username === "admin" && password === "admin123") {
    console.log(`[INFO] Login success for user: ${username}`);
    return res.json({ message: "Login Success" });
  }

  console.log(`[WARN] Login failed for user: ${username} from IP: ${req.ip}`);
  res.status(401).json({ message: "Invalid Credentials" });
});
```

### Step 15.4 — Generate Failed Logins

```bash
export LB_URL=<your_lb_url>

for i in {1..20}; do
  curl -s -X POST http://$LB_URL/login \
    -H "Content-Type: application/json" \
    -d '{"username":"hacker","password":"wrong"}' 
done
```

### Step 15.5 — Search Logs in Grafana

1. **Explore → Select Loki data source**
2. Enter query:

```
{namespace="default"} |= "Login failed"
```

You'll see all 20 failed login attempts with timestamps.

---

## Phase 16 — Alertmanager

**Goal:** Send alerts when metrics cross thresholds.
**Demo:** Generate high CPU → receive an email alert.

### Step 16.1 — Create `k8s/alert-rules.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: bookstore-alerts
  namespace: monitoring
  labels:
    release: prometheus
spec:
  groups:
    - name: bookstore
      rules:
        - alert: HighCPUUsage
          expr: sum(rate(container_cpu_usage_seconds_total{pod=~"bookstore.*"}[1m])) > 0.5
          for: 1m
          labels:
            severity: warning
          annotations:
            summary: "High CPU usage on BookStore pod"
            description: "CPU usage has exceeded 50% for more than 1 minute."

        - alert: HighFailedLogins
          expr: increase(http_requests_total{status="401"}[5m]) > 10
          for: 1m
          labels:
            severity: critical
          annotations:
            summary: "High number of failed login attempts"
            description: "More than 10 failed logins in the last 5 minutes — possible brute force."
```

```bash
kubectl apply -f k8s/alert-rules.yaml
```

### Step 16.2 — Configure Alertmanager Email

Create `k8s/alertmanager-config.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
type: Opaque
stringData:
  alertmanager.yaml: |
    global:
      smtp_smarthost: 'smtp.gmail.com:587'
      smtp_from: 'alerts@yourdomain.com'
      smtp_auth_username: 'your@gmail.com'
      smtp_auth_password: 'your_app_password'

    route:
      receiver: 'email-alert'

    receivers:
      - name: 'email-alert'
        email_configs:
          - to: 'your@email.com'
            send_resolved: true
```

```bash
kubectl apply -f k8s/alertmanager-config.yaml
```

### Step 16.3 — Trigger the Alert

```bash
export LB_URL=<your_lb_url>

# Generate sustained CPU load
hey -n 10000 -c 100 http://$LB_URL/books
```

### Step 16.4 — Verify Alert Firing

```bash
kubectl port-forward svc/prometheus-kube-prometheus-alertmanager 9093:9093 -n monitoring
```

Open `http://localhost:9093` to see the alert firing.
Check your email for the alert notification.

---

## Phase 17 — Falco

**Goal:** Detect runtime threats inside running containers.
**Security Issue Planted:** Exec a shell into a running pod and read `/etc/passwd`.
**Demo:** Attacker gets into the container → Falco detects it immediately.

### Step 17.1 — Install Falco

```bash
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm repo update

helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set tty=true \
  --set falco.grpc.enabled=true \
  --set falco.grpcOutput.enabled=true
```

### Step 17.2 — Verify Falco is Running

```bash
kubectl get pods -n falco
```

### Step 17.3 — Watch Falco Logs (in a separate terminal)

```bash
kubectl logs -f daemonset/falco -n falco
```

### Step 17.4 — Simulate the Attack

In another terminal, find your pod name and exec into it:

```bash
export POD=$(kubectl get pods -l app=bookstore -o jsonpath='{.items[0].metadata.name}')

# Simulated attacker gets shell in container
kubectl exec -it $POD -- /bin/sh

# Inside the container, run:
cat /etc/passwd
whoami
ls /etc
```

### Step 17.5 — Observe Falco Alert

In the Falco log terminal you will see:

```
{"output":"Warning Sensitive file opened for reading by non-trusted program
  (user=root command=cat /etc/passwd container=bookstore pod=bookstore-xxxx)",
  "priority":"Warning",
  "rule":"Read sensitive file untrusted",
  "time":"..."}

{"output":"Notice A shell was spawned in a container with an attached terminal
  (user=root shell=sh container=bookstore)",
  "priority":"Notice",
  "rule":"Terminal shell in container"}
```

Exit the container:

```bash
exit
```

---

## Phase 18 — GuardDuty

**Goal:** Detect suspicious AWS-level threat activity.
**Demo:** Simulate reconnaissance activity → GuardDuty raises findings.

### Step 18.1 — Enable GuardDuty

```bash
aws guardduty create-detector \
  --enable \
  --finding-publishing-frequency FIFTEEN_MINUTES \
  --region us-east-1
```

Or via Console: **AWS Console → GuardDuty → Get Started → Enable GuardDuty**.

### Step 18.2 — Enable Kubernetes Protection

```bash
export DETECTOR_ID=$(aws guardduty list-detectors \
  --query 'DetectorIds[0]' --output text)

aws guardduty update-detector \
  --detector-id $DETECTOR_ID \
  --features '[{"Name":"EKS_AUDIT_LOGS","Status":"ENABLED"}]'
```

### Step 18.3 — Simulate Suspicious Activity (Safe Demo)

GuardDuty provides a built-in sample finding generator:

```bash
aws guardduty create-sample-findings \
  --detector-id $DETECTOR_ID \
  --finding-types \
    "Recon:EC2/Portscan" \
    "UnauthorizedAccess:IAMUser/MaliciousIPCaller" \
    "CryptoCurrency:EC2/BitcoinTool.B"
```

### Step 18.4 — View Findings

```bash
aws guardduty list-findings \
  --detector-id $DETECTOR_ID \
  --finding-criteria '{"Criterion":{"severity":{"Gte":4}}}' \
  --output table
```

Or view in **AWS Console → GuardDuty → Findings**.

Expected sample findings:

```
Recon:EC2/Portscan
UnauthorizedAccess:IAMUser/MaliciousIPCaller
CryptoCurrency:EC2/BitcoinTool.B
```

---

## Phase 19 — AWS Security Hub

**Goal:** Aggregate all security findings into one dashboard.
**Demo:** Show one pane of glass across GuardDuty, Inspector, and IAM findings.

### Step 19.1 — Enable Security Hub

```bash
aws securityhub enable-security-hub \
  --enable-default-standards \
  --region us-east-1
```

Or via Console: **AWS Console → Security Hub → Go to Security Hub → Enable Security Hub**.

### Step 19.2 — Enable AWS Foundational Security Standard

```bash
aws securityhub batch-enable-standards \
  --standards-subscription-requests \
    'StandardsArn=arn:aws:securityhub:us-east-1::standards/aws-foundational-security-best-practices/v/1.0.0'
```

### Step 19.3 — Enable GuardDuty Integration

```bash
aws securityhub enable-import-findings-for-product \
  --product-arn "arn:aws:securityhub:us-east-1::product/aws/guardduty"
```

### Step 19.4 — View Aggregated Findings

```bash
aws securityhub get-findings \
  --filters '{"SeverityLabel":[{"Value":"CRITICAL","Comparison":"EQUALS"}]}' \
  --output table
```

Or in Console: **Security Hub → Findings**.

### Step 19.5 — Explore the Summary Dashboard

In the AWS Console, Security Hub shows:

- **Security Score** (% of passed controls)
- **Failed Checks** across CIS, NIST, PCI-DSS
- **Findings by severity** across all integrated services
- **Trends over time**

---

## Final Demo Walkthrough Script

Use this narrative when presenting to an audience:

```
1. Developer commits AWS key        →  GitLeaks catches it       (Phase 3)
2. Developer uses eval()            →  SonarQube catches it      (Phase 4)
3. Vulnerable lodash dependency     →  Snyk catches it           (Phase 5)
4. Old Docker base image            →  Trivy catches it          (Phase 7)
5. Terraform opens SSH to world     →  Checkov catches it        (Phase 9)
6. App deployed to EKS              →  Prometheus monitors it    (Phase 13)
7. Logs collected                   →  Loki + Grafana visualizes (Phase 14/15)
8. High CPU load generated          →  Alertmanager fires alert  (Phase 16)
9. Attacker gets shell in pod       →  Falco detects it          (Phase 17)
10. AWS recon activity              →  GuardDuty detects it      (Phase 18)
11. All findings aggregated         →  Security Hub shows it     (Phase 19)
```

---

## Repository Final Structure

```
bookstore-devsecops-demo/
├── .github/
│   └── workflows/
│       └── pipeline.yml
├── app/
│   ├── books.json
│   ├── package.json
│   └── server.js
├── k8s/
│   ├── alert-rules.yaml
│   ├── alertmanager-config.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   └── servicemonitor.yaml
├── terraform/
│   ├── ecr.tf
│   ├── eks.tf
│   ├── providers.tf
│   ├── security_group.tf
│   └── variables.tf
│   └── vpc.tf
├── .dockerignore
├── .gitignore
├── Dockerfile
├── README.md
└── sonar-project.properties
```

---

## Tool → Security Issue Cheat Sheet

| Phase | Tool            | Issue Planted                        | What Gets Caught              |
|-------|-----------------|--------------------------------------|-------------------------------|
| 3     | GitLeaks        | Hardcoded AWS key in source code     | Secret in commit              |
| 4     | SonarQube       | `eval(req.body.code)` in endpoint    | Code injection hotspot        |
| 5     | Snyk            | `lodash@4.17.11` dependency          | Prototype Pollution CVE       |
| 7     | Trivy           | `FROM node:16` base image            | OS-level critical CVEs        |
| 9     | Checkov         | SSH open to `0.0.0.0/0` in Terraform | Infrastructure misconfiguration |
| 17    | Falco           | `kubectl exec` + `cat /etc/passwd`   | Runtime shell in container    |
| 18    | GuardDuty       | Sample recon + malicious IP activity | Cloud threat intelligence     |
| 19    | Security Hub    | All findings across services         | Aggregated security posture   |
