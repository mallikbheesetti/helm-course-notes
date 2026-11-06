#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RENDER_DIR="$(mktemp -d)"
trap 'rm -rf "$RENDER_DIR"' EXIT

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required but was not found in PATH" >&2
  exit 1
fi

echo "Helm: $(helm version --short)"
echo "Repository: $ROOT"
echo

count=0
for chart in "$ROOT"/labs/reference/lab*/guestbook; do
  [[ -f "$chart/Chart.yaml" ]] || continue
  count=$((count + 1))
  name="$(basename "$(dirname "$chart")")"
  out="$RENDER_DIR/$name.yaml"

  echo "==> Linting $name"
  helm lint "$chart"

  echo "==> Rendering $name"
  helm template demo "$chart" > "$out"

  if ! grep -q '^kind:' "$out"; then
    echo "No Kubernetes objects rendered for $name" >&2
    exit 1
  fi

  echo "    $(grep -c '^kind:' "$out") objects rendered"
  echo
done

if [[ "$count" -eq 0 ]]; then
  echo "No reference charts found" >&2
  exit 1
fi

echo "Validated $count reference charts."
