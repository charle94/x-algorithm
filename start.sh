#!/usr/bin/env bash
# One-click launcher for the X For You Feed Algorithm (Phoenix pipeline).
# Run from the project root: ./start.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHOENIX_DIR="$SCRIPT_DIR/phoenix"
ARTIFACTS_ZIP="$PHOENIX_DIR/artifacts/oss-phoenix-artifacts.zip"
ARTIFACTS_DIR="$PHOENIX_DIR/artifacts/oss-phoenix-artifacts"

# ── 1. Ensure uv is available ─────────────────────────────────────────────────
if ! command -v uv &>/dev/null; then
    echo "[start.sh] uv not found — installing via the official installer..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh; then
        export PATH="$HOME/.local/bin:$PATH"
    else
        echo "[start.sh] Curl installer failed — falling back to pip install uv..."
        pip install --quiet uv
    fi
fi

echo "[start.sh] Using uv $(uv --version)"

# ── 2. Install / sync Python dependencies ────────────────────────────────────
echo "[start.sh] Syncing Python dependencies in phoenix/..."
cd "$PHOENIX_DIR"
uv sync

# ── 3. Extract model artifacts if needed ─────────────────────────────────────
if [ ! -d "$ARTIFACTS_DIR" ]; then
    if [ ! -f "$ARTIFACTS_ZIP" ]; then
        echo "[start.sh] ERROR: Artifact archive not found at $ARTIFACTS_ZIP" >&2
        echo "           Download oss-phoenix-artifacts.zip (via Git LFS) and place it" >&2
        echo "           at phoenix/artifacts/oss-phoenix-artifacts.zip, then re-run." >&2
        exit 1
    fi
    echo "[start.sh] Extracting $ARTIFACTS_ZIP ..."
    unzip -q "$ARTIFACTS_ZIP" -d "$PHOENIX_DIR/artifacts/"
    echo "[start.sh] Artifacts extracted to $ARTIFACTS_DIR"
else
    echo "[start.sh] Artifacts already extracted at $ARTIFACTS_DIR — skipping unzip."
fi

# ── 4. Run the end-to-end pipeline ───────────────────────────────────────────
echo "[start.sh] Starting Phoenix retrieval + ranking pipeline..."
uv run run_pipeline.py --artifacts_dir "$ARTIFACTS_DIR" "$@"
