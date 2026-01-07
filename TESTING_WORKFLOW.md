# Testing Workflow

## Overview

This repo uses a two-branch workflow for safe configuration testing before deployment:

- **testing**: Development branch - builds and caches configurations
- **main**: Production branch - comin watches this and deploys to hosts

## VS Code Integration

The workflow is integrated into VS Code:

### Git Configuration
- Default branch for new work: `testing`
- Push behavior: Current branch
- Auto-setup merge tracking

### Available Tasks (Cmd+Shift+P → "Tasks: Run Task")

1. **Switch to testing branch** - Ensures you're on testing and configured
2. **Build and cache (testing)** (Default: Cmd+Shift+B) - Builds all hosts on xsvr1 from testing branch
3. **Merge testing to main** - Merges testing→main and triggers comin deployment

## Workflow Steps

### 1. Make Changes
```fish
# You're already on testing branch
git status
# Make your changes...
```

### 2. Commit and Push to Testing
```fish
git add .
git commit -m "Your changes"
git push  # Pushes to testing branch
```

### 3. Build and Cache
Run the build task in VS Code (Cmd+Shift+B) or:
```fish
./scripts/build-and-cache-xsvr1-hosts.sh
```

This:
- Pulls from `testing` branch on xsvr1
- Builds all host configurations
- Caches them to nixcache.xrs444.net

### 4. Deploy to Production
When ready to deploy, merge to main:
```fish
git checkout main
git merge testing
git push
git checkout testing  # Return to testing
```

Or use the VS Code task: "Merge testing to main"

### 5. Comin Deploys Automatically
- Comin watches the `main` branch
- When you push to main, comin pulls changes on all hosts
- Hosts apply the configuration automatically
- You'll get ntfy notifications on success/failure

## Configuration Files

- `.vscode/settings.json` - Git defaults for testing workflow
- `.vscode/tasks.json` - Build and merge tasks
- `scripts/init-testing-workflow.fish` - One-time setup script
- `scripts/build-and-cache-xsvr1-hosts.sh` - Builds from testing branch
- `modules/packages-nixos/comin/default.nix` - Comin watches main branch

## Branch Details

### Testing Branch
- Where you work daily
- Safe to break things
- Builds are cached but not deployed
- Can test configurations before production

### Main Branch
- Production branch
- Only merge tested changes here
- Comin immediately deploys to all hosts
- Keep this stable

## First Time Setup

If you need to set up the workflow on a new machine:
```fish
./scripts/init-testing-workflow.fish
```

This creates the testing branch and configures git.
