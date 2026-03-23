# Containers on AWS — Attendee Reference Guide
**Session:** Containers on AWS — 60-minute demo
**Audience:** Beginners
**Date:** 2026-03-22

---

## What We Built

We took a static HTML app, packaged it in a Docker container, stored the image in AWS ECR (a private registry), and deployed it to ECS Fargate so it runs as a serverless container accessible from the internet — no servers to manage.

---

## Architecture

```
You (laptop) → docker build → Docker Image
                                   |
                              docker push
                                   |
                                   v
                        Amazon ECR (image registry)
                                   |
                           ECS pulls image
                                   |
                                   v
                   ECS Fargate Task (running container)
                                   |
                                port 80
                                   |
                                   v
                        Public IP → Browser
```

---

## Prerequisites to Replicate at Home

- AWS account — free tier is sufficient for this demo
- Docker Desktop: https://docs.docker.com/get-started/get-docker/
- AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Configure the CLI with your access key:
  ```bash
  aws configure
  ```
  You will be prompted for your Access Key ID, Secret Access Key, default region (`us-east-1`), and output format (`json`).

---

## Step-by-Step Replication Guide

Follow these steps after the session to reproduce everything on your own AWS account.

**1. Get the Dockerfile**

Clone the repo or create a `Dockerfile` in a directory with your `index.html`:

```
cicd/
  Dockerfile
  app/
    index.html
```

**2. Build the Docker image**

```bash
cd cicd/
docker build -t containers-demo .
```

**3. Test the image locally**

```bash
docker run -p 8080:80 containers-demo
```

Open http://localhost:8080 — you should see your HTML app. Press `Ctrl+C` to stop.

**4. Create an ECR repository**

In the AWS Console: go to ECR → Create repository → name it `containers-demo` → Create.

Or via CLI:
```bash
aws ecr create-repository --repository-name containers-demo --region us-east-1
```

**5. Authenticate Docker to ECR**

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
```

You should see: `Login Succeeded`

**6. Tag and push the image**

```bash
docker tag containers-demo:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/containers-demo:latest

docker push \
  $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/containers-demo:latest
```

**7. Create an ECS cluster**

In the AWS Console: ECS → Clusters → Create Cluster
- Name: `containers-demo-cluster`
- Infrastructure: AWS Fargate
- Click Create

**8. Create a task definition**

ECS → Task Definitions → Create new task definition
- Launch type: Fargate
- Name: `containers-demo-task`
- Container name: `web`
- Image URI: paste your ECR URI (from Step 4/5)
- Port: `80`
- CPU: 0.5 vCPU, Memory: 1 GB

**9. Create an ECS service**

Clusters → `containers-demo-cluster` → Services → Create
- Launch type: Fargate
- Task definition: `containers-demo-task`
- Desired tasks: `1`
- VPC: default VPC, public subnets
- Security group: allow inbound TCP port 80 from anywhere (`0.0.0.0/0`)
- Public IP: Enabled
- Click Create — wait ~2 minutes

**10. Access the app**

ECS → Clusters → `containers-demo-cluster` → Tasks → click the running task → copy the Public IP.

Open `http://<public-ip>` in your browser. Your containerized app is live.

---

## Glossary

| Term | Plain-language definition |
|------|--------------------------|
| **Container** | A lightweight, portable package that bundles your app and all its dependencies together so it runs the same everywhere. |
| **Docker image** | The blueprint (template) for a container. Think of it like a class in object-oriented programming — you instantiate it to get a running container. |
| **Dockerfile** | A plain text file with step-by-step instructions telling Docker how to build your image. |
| **ECR** | Amazon Elastic Container Registry — AWS's private Docker registry. Stores your images so ECS (and other services) can pull them. |
| **ECS** | Amazon Elastic Container Service — AWS's container orchestration service. Decides where and how your containers run, restarts them if they crash, and can scale them up or down. |
| **Fargate** | A launch type for ECS (and EKS) where AWS manages the underlying servers entirely. You never provision or SSH into EC2 instances. |
| **Task definition** | A blueprint for your ECS container — specifies the image URI, CPU, memory, port mappings, and environment variables. |
| **ECS service** | Keeps N copies of your task running at all times. If a container crashes, the service automatically replaces it. |

---

## Cost Note

Stop or delete your ECS service and task after the demo to avoid ongoing charges.

| Resource | Approximate cost |
|----------|-----------------|
| Fargate (0.5 vCPU / 1 GB) | ~$0.025/hour while running |
| ECR image storage | $0.10/GB/month |
| Fargate when stopped | $0.00 |

To clean up: ECS → Services → select service → Delete. Then ECS → Clusters → Delete cluster.

---

## Next Steps

- **Try EKS** — deploy the same container using Kubernetes (`kubectl` + `eksctl`)
- **Try App Runner** — even simpler than ECS; point it at your ECR image and it handles everything
- **Add a CI/CD pipeline** — push code → CodeBuild builds the image → pushes to ECR → updates the ECS service automatically (no manual steps)
- **Add HTTPS** — put an Application Load Balancer with an ACM certificate in front of your ECS service for a real domain + TLS
