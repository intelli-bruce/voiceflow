#!/bin/bash
# VoiceFlow 초기 설정 스크립트
# Python 가상환경 생성 + 의존성 설치
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/.venv"

echo "🐍 Setting up Python virtual environment..."

# Python 버전 확인
PYTHON_CMD=""
for cmd in python3.11 python3.12 python3; do
  if command -v "$cmd" &>/dev/null; then
    version=$("$cmd" --version 2>&1 | awk '{print $2}')
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)
    if [ "$major" -ge 3 ] && [ "$minor" -ge 11 ]; then
      PYTHON_CMD="$cmd"
      break
    fi
  fi
done

if [ -z "$PYTHON_CMD" ]; then
  echo "❌ Python 3.11+ not found. Install via:"
  echo "   brew install python@3.12"
  exit 1
fi

echo "   Using: $PYTHON_CMD ($($PYTHON_CMD --version))"

# 가상환경 생성
if [ -d "$VENV_DIR" ]; then
  echo "   .venv already exists, skipping creation"
else
  echo "   Creating .venv..."
  "$PYTHON_CMD" -m venv "$VENV_DIR"
fi

# 의존성 설치
echo "📦 Installing Python dependencies..."
"$VENV_DIR/bin/pip" install --upgrade pip -q
"$VENV_DIR/bin/pip" install -r "$PROJECT_DIR/server/requirements.txt" -q

echo ""
echo "✅ Setup complete!"
echo "   Python venv: $VENV_DIR"
echo "   Next: scripts/build.sh"
