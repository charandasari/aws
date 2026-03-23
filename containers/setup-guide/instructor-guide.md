# Containers on AWS — Instructor Guide
**Session:** 60-minute instructor-led demo
**Audience:** Beginners
**Topic:** Containerize a static HTML app and deploy to ECS Fargate via ECR

---

## Pre-Demo Checklist

Complete all items before the session starts.

### IAM Permissions
Your AWS account (or IAM user) needs admin access or at minimum these managed policies:
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonECS_FullAccess`
- `AmazonVPCFullAccess`

### Local Setup
- [ ] Docker Desktop installed and **running** (verify: `docker info` returns output, not an error)
- [ ] AWS CLI installed and configured (`aws configure` with a valid access key)
- [ ] Verify Docker auth to ECR works:
  ```bash
  aws ecr get-login-password --region us-east-1
  ```
  It should print a long token string — not an error.

### AWS Pre-Provisioning
Create the ECR repository before the session so the push command is ready to go:
```bash
aws ecr create-repository --repository-name containers-demo --region us-east-1
```
Note the `repositoryUri` from the output — you'll tag and push to it during the demo.

### Browser Tabs to Pre-Load
- [ ] Slide deck (open in browser, navigate with arrow keys)
- [ ] AWS Console → ECR service
- [ ] AWS Console → ECS service
- [ ] Terminal window with the repo's `cicd/` directory as the working directory

### Dry Run
- [ ] Run `docker build -t containers-demo .` inside `cicd/` — confirm it succeeds
- [ ] Run `docker run -p 8080:80 containers-demo` — confirm http://localhost:8080 loads the app
- [ ] Stop the container (`Ctrl+C` or `docker stop`)

---

## Timing Guide

| Time | Segment | Notes |
|------|---------|-------|
| 0–8 min | Intro + container concepts | Do not rush the VM vs Container comparison — this is the foundation. Use the whiteboard or slide diagram. |
| 8–15 min | Docker basics | Walk through the Dockerfile line by line. Explain `FROM`, `COPY`, `EXPOSE`, `CMD`. |
| 15–22 min | AWS services overview | Cover ECR, ECS, EKS, App Runner. Keep it high-level — 1–2 sentences per service. |
| 22–35 min | Live demo part 1 — build and push to ECR | 13 min. Go slowly. Narrate every command before running it. |
| 35–52 min | Live demo part 2 — ECS cluster, task def, service | 17 min. Console-heavy. Click deliberately — beginners are reading every field. |
| 52–57 min | EKS vs App Runner comparison | Contrast against ECS. Reinforce when you'd choose each. |
| 57–60 min | Q&A | See "Common Beginner Questions" section below. |

**Pacing tip:** If you fall behind during the ECS console steps (35–52), skip creating the ECS Service and instead show the ECR console with the pushed image. Explain what ECS would do with it. This saves 5–7 minutes without losing the conceptual arc.

---

## Live Demo Commands

Copy-paste exactly. Narrate what each block does before running it.

```bash
# Step 1: Build image locally
cd /path/to/repo/cicd
docker build -t containers-demo .
docker run -p 8080:80 containers-demo
# Open http://localhost:8080 in the browser to show it works
# Stop the container before continuing (Ctrl+C or docker stop <id>)

# Step 2: Authenticate Docker to ECR and push the image
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=us-east-1

aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin \
    $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker tag containers-demo:latest \
  $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/containers-demo:latest

docker push \
  $AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/containers-demo:latest

# Step 3–5: Done via AWS Console (ECS) — see section below
```

---

## AWS Console Steps (ECS)

Walk the audience through these in order. Read each field name aloud before filling it in.

**Step 3 — Create Cluster**
1. Go to ECS → Clusters → Create Cluster
2. Cluster name: `containers-demo-cluster`
3. Infrastructure: select **AWS Fargate** (serverless)
4. Click Create — wait for the cluster to appear as Active

**Step 4 — Create Task Definition**
1. ECS → Task Definitions → Create new task definition
2. Launch type: **Fargate**
3. Task definition name: `containers-demo-task`
4. Container:
   - Name: `web`
   - Image URI: paste the ECR URI from Step 2 (the one you pushed to)
   - Port mappings: `80` / TCP
5. CPU: `0.5 vCPU`, Memory: `1 GB`
6. Click Create

**Step 5 — Create Service and Access the App**
1. Clusters → `containers-demo-cluster` → Services tab → Create
2. Launch type: **Fargate**
3. Task definition: `containers-demo-task` (latest)
4. Service name: `containers-demo-service`
5. Desired tasks: `1`
6. Networking:
   - VPC: default VPC
   - Subnets: select all public subnets
   - Security group: create new → allow inbound TCP port 80 from `0.0.0.0/0`
   - Public IP: **Enabled**
7. Click Create — wait approximately 2 minutes for the task to reach RUNNING status
8. Click the running task → copy the **Public IP**
9. Open `http://<public-ip>` in the browser — the app should load

---

## Recovery Tips

If something goes wrong live, stay calm and narrate what you're doing.

| Problem | Fix |
|---------|-----|
| ECR auth fails | Re-run the `aws ecr get-login-password` command. Double-check `$REGION` matches the region where you created the repo. |
| ECS task stuck in PENDING | Check the security group allows inbound TCP 80. Check that a task execution IAM role is attached to the task definition. |
| Task keeps stopping (STOPPED status) | Click the task → Logs tab → read the error. Common cause: wrong image URI, or the container crashed on startup. |
| Out of time | Skip ECS service creation. Show the ECR console with the pushed image. Say: "From here, ECS would pull this image, schedule it on Fargate, and expose it via a public IP — that's what we'd do with 10 more minutes." |

---

## Common Beginner Questions to Anticipate

**"What's the difference between ECS and EKS?"**
ECS is AWS's simpler, native orchestrator — no Kubernetes knowledge required. EKS runs Kubernetes on AWS — more powerful and portable, but steeper learning curve. Start with ECS; graduate to EKS when you need Kubernetes features.

**"Do I need Docker installed on the EC2 instance (or Fargate)?"**
No. With Fargate, AWS manages the underlying compute entirely. You never SSH into a server. You just hand AWS the image URI and it handles the rest.

**"How much does this cost?"**
Fargate pricing: ~$0.04048/vCPU/hour + $0.004445/GB/hour. A 0.5 vCPU / 1 GB task running 24 hours costs roughly $0.60/day. Remind attendees to stop the service after the demo.

**"How does it scale?"**
ECS Service auto-scaling uses CloudWatch alarms (CPU utilization, memory, or custom metrics) to add or remove tasks automatically. You define min/max task counts and the scaling policy.

**"What about HTTPS?"**
Put an Application Load Balancer (ALB) in front of the ECS service. Attach an ACM (AWS Certificate Manager) certificate to the ALB listener. The ALB handles TLS termination — your container still serves plain HTTP on port 80.
