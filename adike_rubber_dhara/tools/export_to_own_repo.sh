#!/usr/bin/env bash
# Copy Adike–Rubber Dhara into its own repository layout (app at repo root).
#   tools/export_to_own_repo.sh /path/to/new/adike-rubber-dhara
set -euo pipefail
src="$(cd "$(dirname "$0")/.." && pwd)"
repo_root="$(cd "$src/.." && pwd)"
dst="${1:?usage: $0 <destination dir>}"
mkdir -p "$dst/.github/workflows"
tar -C "$src" --exclude node_modules --exclude ./app/build --exclude .dart_tool --exclude __pycache__ \
  --exclude ./tools/export_to_own_repo.sh -cf - . | tar -C "$dst" -xf -
for f in "$repo_root"/.github/workflows/adike-*.yml; do
  sed -e 's#APP_DIR: adike_rubber_dhara#APP_DIR: .#' \
      -e 's#adike_rubber_dhara/#./#g' \
      -e '/^ *paths:/d' "$f" > "$dst/.github/workflows/$(basename "$f")"
done
echo "Exported to $dst. Then: git init && git add -A && git commit"
