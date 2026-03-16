# AWS CI/CD Pipeline Demo

A hands-on demo project showing a 4-stage AWS CI/CD pipeline deploying a static web app to EC2 via Apache. Used for presentations and workshops.

## Pipeline Overview

```
CodeCommit → CodeBuild → CodeDeploy → EC2 (Apache)
```

Each push to `master` triggers the full pipeline automatically.

## Project Structure

```
app/index.html          # Static demo app (edit the <h1> to trigger a demo run)
appspec.yml             # CodeDeploy lifecycle configuration
buildspec.yml           # CodeBuild packaging steps
scripts/
  before_install.sh     # Stops httpd, clears old files
  after_install.sh      # Sets file permissions (apache:apache)
  start_server.sh       # Starts httpd and enables it on boot
  stop_server.sh        # Graceful httpd shutdown
diagrams/               # Architecture diagrams (local only, not in CodeCommit)
presentation/           # HTML slide deck (local only, not in CodeCommit)
setup-guide/            # Instructor and attendee Word docs (local only)
```

## Running Locally

No build step required — the app is a single static HTML file.

```bash
python -m http.server 8080
# Open http://localhost:8080/app/index.html
```

## Demo Workflow

1. Edit the `<h1>` in `app/index.html`
2. Commit and push to CodeCommit:
   ```bash
   git add app/index.html
   git commit -m "Update heading"
   git push origin master
   ```
3. Watch CodePipeline in the AWS Console: Source → Build → Deploy
4. Verify the change on the EC2 public IP

## How It Works

| Stage | Service | What happens |
|-------|---------|-------------|
| Source | CodeCommit | Push triggers pipeline |
| Build | CodeBuild | Runs `buildspec.yml`, packages `app/`, `appspec.yml`, `scripts/` into an artifact |
| Deploy | CodeDeploy | Runs lifecycle hooks, copies files to `/var/www/html/` |
| Serve | EC2 + Apache | Apache serves `index.html` on port 80 |

## Prerequisites

- AWS account with CodeCommit, CodeBuild, CodeDeploy, and CodePipeline set up
- EC2 instance with the CodeDeploy agent installed and Apache (httpd) available
- IAM roles for CodeBuild and CodeDeploy with appropriate permissions

See `setup-guide/cicd-aws-setup-guide.docx` for full infrastructure setup instructions.
