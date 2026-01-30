#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="/Users/brucechoe/clawd/.venvs/qwen3-asr"

echo "Activating venv at $VENV_DIR..."
source "$VENV_DIR/bin/activate"

echo "Starting VoiceFlow ASR server..."
python "$PROJECT_DIR/server/main.py"
