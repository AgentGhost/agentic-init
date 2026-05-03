# Second Implementation

## Creating a New Project from Template

This guide explains how to create a second implementation that builds upon `agentic-init`.

### 1. Create New Project in Plane

1. In Plane UI: Open existing project
2. Click the "•••" menu → **Duplicate Project**
3. Rename: "Agentic Implementation 2"
4. Click into the new project

### 2. Clone Git Repo

```bash
# Clone fresh template
git clone https://github.com/AgentGhost/agentic-init.git agentic-implementation-2
cd agentic-implementation-2

# Rename origin to avoid pulling from template
git remote rename origin template

# Connect to your GitHub (create new repo first)
git remote add origin https://github.com/AgentGhost/agentic-implementation-2.git

# Update README for your project
# Edit: project name, API keys, specific configuration

# Push to new origin
git push -u origin main
```

### 3. Update Config

Edit:
- `sec/.env` - your API keys
- `README.md` - project name
- `SPEC.md` - specific requirements

### 4. Sync from Template (Later)

When `agentic-init` template updates:

```bash
# Add template as remote
git remote add template https://github.com/AgentGhost/agentic-init.git

# Fetch latest
git fetch template

# Review changes
git log main..template/main --oneline

# Merge or cherry-pick specific commits
git cherry-pick <commit>
```

### Workspace Overview

```
agentic-projects (workspace)
├── agentic-init - Template & reference
└── agentic-implementation-2 - Your implementation
```

Each project has its own Git repo. They share the same workspace and can use common Cycles/Modules.