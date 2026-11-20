#!/usr/bin/env bash
# Install the qrme OpenCode skill.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/skills/qrme"
FORCE=0
DEST_BASE="$HOME/.config/opencode/skills"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--project] [--force]

  --project   install into ./.opencode/skills (current project only)
  --force     overwrite an existing qrme skill
  -h, --help  show this help

Environment:
  PYTHON      python interpreter to use (default: python3, then python)
EOF
}

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --project) DEST_BASE="$(pwd)/.opencode/skills" ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option '$arg'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

DEST="$DEST_BASE/qrme"

if [ ! -f "$SRC/SKILL.md" ] || [ ! -f "$SRC/scripts/make_qr.py" ]; then
  echo "error: skill files missing under $SRC" >&2
  exit 1
fi

# --- python check -----------------------------------------------------------
PY=""
for candidate in "${PYTHON:-python3}" python3 python; do
  if command -v "$candidate" >/dev/null 2>&1; then
    if "$candidate" -c 'import sys; raise SystemExit(0 if sys.version_info[0] == 3 else 1)' 2>/dev/null; then
      PY="$candidate"
      break
    fi
  fi
done

if [ -z "$PY" ]; then
  echo "error: Python 3 is required but was not found." >&2
  echo "       install python3, or run: PYTHON=/path/to/python ./install.sh" >&2
  exit 1
fi

# --- install ----------------------------------------------------------------
if [ -e "$DEST" ]; then
  if [ "$FORCE" -ne 1 ]; then
    echo "error: $DEST already exists (use --force to overwrite)" >&2
    exit 1
  fi
  rm -rf -- "$DEST"
fi

mkdir -p -- "$DEST_BASE"
cp -R -- "$SRC" "$DEST"
chmod +x -- "$DEST/scripts/make_qr.py" 2>/dev/null || true

# --- smoke test -------------------------------------------------------------
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "$TMP_DIR"' EXIT

echo "==> testing QR generation"
TEST_OUT="$("$PY" "$DEST/scripts/make_qr.py" "https://example.com" "$TMP_DIR/test.png")" || {
  echo "error: smoke test failed." >&2
  echo "       the skill was copied to $DEST but was not verified." >&2
  exit 1
}

case "$TEST_OUT" in
  OK*1000x1000*) ;;
  *)
    echo "error: unexpected test output: $TEST_OUT" >&2
    exit 1
    ;;
esac

echo "==> $TEST_OUT"
echo
echo "Installed qrme → $DEST"
echo "Try in OpenCode:  @qrme https://example.com"
