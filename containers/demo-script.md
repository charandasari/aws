# Demo Script — Containers on AWS (60 min)

> **Format:** Instructor-led. You drive the console, attendees watch.
> **Audience:** Beginners — explain the "why" before every command.

---

## Pre-Demo Checklist (complete before the session)

- [ ] Docker Desktop running locally (`docker ps` returns no error)
- [ ] AWS CLI configured (`aws sts get-caller-identity` returns your account ID)
- [ ] ECR repo created: `aws ecr create-repository --repository-name containers-demo --region us-east-1`
- [ ] Slide deck open in browser: `cicd/presentation/containers-slides.html`
- [ ] AWS Console open and logged in — land on ECR service
- [ ] Terminal open, `cd` to `cicd/containers/` in this repo
- [ ] Test run: `docker build -t containers-demo . && docker run -p 8080:80 containers-demo` works

---

## Section 1: Introduction (0–8 min) — Slides

**Slide: Title**
> "Today we're talking about Containers on AWS. By the end of this 60 minutes,
> you'll have seen a real app go from a Dockerfile on a laptop to running in the
> AWS cloud — with no EC2 to manage."

**Slide: Agenda**
Walk through the agenda table. Call out that EKS and App Runner are covered in slides only — ECS Fargate is the live demo.

**Slide: Today's Goal**
> "The app we're deploying is the same HTML app from the CI/CD demo. Same code,
> completely different infrastructure. That's the power of containers."

---

## Section 2: What Are Containers? (8–15 min) — Slides

**Slide: The Problem**
> "Raise your hand if you've ever heard 'it works on my machine.' That's the problem
> containers solve. Different Python versions, different OS libraries, different
> environments — containers package all of it together."

**Slide: VMs vs Containers**
> "A VM runs a full operating system per app. A container shares the host OS kernel
> but isolates the process. Much lighter, much faster to start."

**Slide: Shipping Container Analogy**
> "Before shipping containers, every port had a different way to load goods.
> Standardizing the box changed everything. Docker did the same for software."

**Slide: Image vs Container**
> "An image is the blueprint — like a class in programming. A container is a running
> instance of that image. You can run 10 containers from the same image."

**Slide: Why Containers on AWS**
> "Consistency between dev and prod, easy to scale, pays per second on Fargate.
> This is how most modern apps are deployed."

---

## Section 3: Docker 101 (15–22 min) — Slides

**Slide: Docker Image**
> "An image is built in layers. Each line in your Dockerfile adds a layer."

**Slide: Dockerfile**
> "Here's ours." *(switch to terminal, show the file)*

```bash
cat Dockerfile
```

> "FROM nginx:alpine — we start with a tiny nginx web server.
> COPY — we put our HTML file in. EXPOSE 80 — we open port 80.
> That's it. 3 lines."

**Slide: Docker Commands**
> "Let me show you the commands live."

**Slide: Image → ECR**
> "Once the image is built locally, we push it to ECR — AWS's private Docker registry.
> Think of it like GitHub, but for container images."

**Slide: Docker vs the App**
> "Our HTML app — zero code changes. We just wrapped it in a container."

---

## Section 4: AWS Container Services (22–35 min — split: 7 min slides, 6 min live)

**Slide: 4 Ways to Run Containers**
> "AWS gives you four options. We're using ECR to store and ECS Fargate to run."

Walk through ECR, ECS, Fargate, EKS, App Runner slides briefly.

**Slide: Demo Architecture**
> "Here's exactly what we're about to do."

**Then switch to LIVE DEMO — Step 1:**

---

## LIVE DEMO PART 1: Build + Push to ECR (22–35 min)

### Step 1: Build the image locally

```bash
# From cicd/containers/
docker build -t containers-demo .
```

> "Docker is reading the Dockerfile, pulling nginx:alpine, and copying our HTML in.
> Watch the layers build."

```bash
docker images | grep containers-demo
```

> "The image exists locally. About 40MB — tiny."

```bash
docker run -d -p 8080:80 --name demo-local containers-demo
```

> Open `http://localhost:8080` in browser.
> "There's our app running inside a container on my laptop. Let's ship it to AWS."

```bash
docker stop demo-local && docker rm demo-local
```

### Step 2: Push to ECR

```bash
# Get your account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1
echo "Account: $AWS_ACCOUNT_ID"
```

> "ECR repos are scoped to your account and region."

```bash
# Authenticate Docker to ECR
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com
```

> "This gets a temporary token from AWS and passes it to Docker login."

```bash
# Tag the image for ECR
docker tag containers-demo:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/containers-demo:latest

# Push
docker push $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/containers-demo:latest
```

> "It's pushing each layer. Layers are cached, so future pushes are faster."

**Switch to AWS Console → ECR → containers-demo repo**
> "Show the image in the console. Copy the image URI — we'll need it next."

---

## LIVE DEMO PART 2: Deploy to ECS Fargate (35–52 min)

### Step 3: Create ECS Cluster

**AWS Console → ECS → Clusters → Create Cluster**

| Field | Value |
|-------|-------|
| Cluster name | `containers-demo-cluster` |
| Infrastructure | AWS Fargate (serverless) |

> "A cluster is just a logical grouping of tasks and services. We're using Fargate
> so AWS manages the underlying compute — no EC2 instances to patch."

Click **Create**. Wait ~30 seconds.

### Step 4: Create Task Definition

**ECS → Task Definitions → Create new task definition**

| Field | Value |
|-------|-------|
| Task definition family | `containers-demo-task` |
| Launch type | AWS Fargate |
| CPU | 0.5 vCPU |
| Memory | 1 GB |

**Add container:**

| Field | Value |
|-------|-------|
| Container name | `web` |
| Image URI | *(paste ECR URI from above)* |
| Port mappings | 80 / TCP |

> "A task definition is the blueprint for our container — what image, how much CPU and
> memory, what ports. Like a docker run command, but declarative."

Click **Create**.

### Step 5: Create ECS Service

**Clusters → containers-demo-cluster → Services → Create**

| Field | Value |
|-------|-------|
| Launch type | Fargate |
| Task definition | containers-demo-task (latest) |
| Service name | `containers-demo-service` |
| Desired tasks | 1 |

**Networking:**
- VPC: default VPC
- Subnets: select 2 public subnets
- Security group: create new → inbound TCP port 80 from 0.0.0.0/0
- Public IP: **Enabled**

Click **Create**.

> "ECS is now pulling the image from ECR and starting our container. Takes about 1–2 min."

**Watch the task go from PROVISIONING → PENDING → RUNNING.**

**Click the running task → copy Public IP**

Open `http://<public-ip>` in browser.

> "There it is. Same HTML app. Running in a Docker container. On AWS Fargate.
> No EC2, no Apache to configure, no SSH."

---

## Section 5: EKS vs App Runner (52–57 min) — Slides

**Slide: EKS vs App Runner comparison table**
> "EKS is for teams that need Kubernetes. App Runner is simpler than even ECS.
> For most beginner workloads: start with Fargate or App Runner."

**Slide: Which one should I use?**
> "Decision tree: need Kubernetes? → EKS. Want fully managed? → App Runner.
> In between? → ECS Fargate."

---

## Section 6: Recap + Q&A (57–60 min) — Slides

**Slide: Key Takeaways**

1. Containers solve environment consistency ("works on my machine")
2. Docker builds images; images run as containers
3. ECR stores your images — private, versioned, integrated with ECS
4. ECS Fargate runs containers without managing servers
5. Same app code, totally different (better) infrastructure

**Slide: Next Steps**
> "Try EKS if you want to learn Kubernetes. Try App Runner for the simplest path.
> Add a CI/CD pipeline to automate the build + push + deploy."

**Open floor for questions.**

---

## Cleanup (after the session)

```bash
# Delete ECS service (set desired count to 0 first, then delete)
# Delete ECS cluster
# Delete ECR images (to avoid storage charges)
aws ecr batch-delete-image \
  --repository-name containers-demo \
  --region us-east-1 \
  --image-ids imageTag=latest
```
