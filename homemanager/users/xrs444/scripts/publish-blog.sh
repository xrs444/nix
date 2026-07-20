#!/usr/bin/env bash
# Publish blog posts from the Obsidian vault (Blog/) into the Hugo site repo
# (content/posts/), then commit and push. Cloudflare Pages builds Hugo on
# push, so this script's job ends at `git push` — no local hugo build.
#
# One-way, vault -> site. Deliberately no --delete on rsync: the site repo
# may contain posts that were never authored in the vault (e.g. yourgpos.md),
# and losing those silently would be worse than a stale copy lying around.
set -euo pipefail

VAULT_BLOG="$HOME/Documents/obsidian/xrs444/Blog"
SITE_REPO="$HOME/site/xrs444"
SITE_POSTS="$SITE_REPO/content/posts"

if [ ! -d "$VAULT_BLOG" ]; then
  echo "publish-blog: vault Blog folder not found at $VAULT_BLOG" >&2
  exit 1
fi

if [ ! -d "$SITE_REPO/.git" ]; then
  echo "publish-blog: site repo not found at $SITE_REPO (expected a git checkout)" >&2
  exit 1
fi

mkdir -p "$SITE_POSTS"

rsync -a --include='*.md' --exclude='*' "$VAULT_BLOG/" "$SITE_POSTS/"

cd "$SITE_REPO"

if [ -z "$(git status --porcelain -- content/posts)" ]; then
  echo "publish-blog: no changes to publish"
  exit 0
fi

git add content/posts
git commit -m "blog: publish from obsidian"
git push

echo "publish-blog: pushed. Cloudflare Pages will rebuild xrs444.net shortly."
