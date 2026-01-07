#!/usr/bin/env fish
# Create testing branch and configure git
if not git rev-parse --verify testing &>/dev/null
    echo "Creating testing branch..."
    git checkout -b testing
    git push -u origin testing
else
    echo "Checking out testing branch..."
    git checkout testing
end

# Configure git to default to testing for new work
git config --local branch.autoSetupMerge always
git config --local push.default current

echo ""
echo "✓ Git configured for testing workflow!"
echo ""
echo "Workflow:"
echo "  1. You are now on 'testing' branch (default for work)"
echo "  2. Make changes, commit, and push normally"
echo "  3. Run: ./scripts/build-and-cache-xsvr1-hosts.sh"
echo "  4. When ready: git checkout main && git merge testing && git push"
echo "  5. Comin will deploy from 'main' to all hosts"
