# CI/CD Architecture Diagram

## Pipeline Flow

```mermaid
flowchart LR
    Dev["👨‍💻 Developer\n(git push)"]
    CC["📦 CodeCommit\n(Source Stage)"]
    CP["⚙️ CodePipeline\n(Orchestrator)"]
    CB["🔨 CodeBuild\n(Build Stage)"]
    CD["🚀 CodeDeploy\n(Deploy Stage)"]
    EC2["🖥️ EC2 Instance\n(Production)"]

    Dev -->|git push| CC
    CC -->|triggers| CP
    CP --> CB
    CB -->|artifact to S3| CP
    CP --> CD
    CD -->|deploys app| EC2

    style Dev fill:#1f2937,color:#e5e7eb,stroke:#374151
    style CC fill:#0d47a1,color:#fff,stroke:#1565c0
    style CP fill:#4a148c,color:#fff,stroke:#6a1b9a
    style CB fill:#1b5e20,color:#fff,stroke:#2e7d32
    style CD fill:#e65100,color:#fff,stroke:#f57c00
    style EC2 fill:#37474f,color:#fff,stroke:#546e7a
```

## Service Roles

| Service | Role | Key File |
|---------|------|----------|
| **CodeCommit** | Git repository — source of truth, pipeline trigger | — |
| **CodePipeline** | Orchestrates stages, passes artifacts between them | Pipeline config |
| **CodeBuild** | Compiles code, runs tests, produces deployment artifact | `buildspec.yml` |
| **CodeDeploy** | Copies artifact to EC2, runs lifecycle hooks | `appspec.yml` |
| **EC2** | Runs the application (Apache serving index.html) | — |

## Artifact Flow

```
CodeCommit repo
  └── buildspec.yml        ← tells CodeBuild what to do
  └── appspec.yml          ← tells CodeDeploy how to deploy
  └── scripts/             ← lifecycle hook scripts
  └── app/index.html       ← the application

CodeBuild packages → uploads artifact .zip to S3

CodeDeploy downloads artifact from S3 → deploys to EC2
```
