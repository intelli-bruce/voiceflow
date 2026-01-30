#!/bin/bash
# VoiceFlow launcher - run both ASR server and app
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV="/Users/brucechoe/clawd/.venvs/qwen3-asr"
LOG="/tmp/voiceflow.log"

# Kill existing
pkill -f "server/main.py" 2>/dev/null || true
pkill -f "VoiceFlow" 2>/dev/null || true
sleep 1

echo "🚀 Starting VoiceFlow..."
echo ""

# Start ASR server in background
echo "📡 Starting ASR server..."
"$VENV/bin/python3" "$PROJECT_DIR/server/main.py" > /tmp/voiceflow-server.log 2>&1 &
SERVER_PID=$!

# Wait for server to be ready
for i in $(seq 1 30); do
    if curl -s -o /dev/null -w '' --connect-timeout 1 http://localhost:9876 2>/dev/null; then
        break
    fi
    sleep 1
done

echo "✅ ASR server ready (pid: $SERVER_PID)"
echo ""

# Start VoiceFlow app (open으로 실행해야 접근성 권한이 앱에 정상 적용됨)
echo "🎤 Starting VoiceFlow app..."
echo "   Ctrl+Ctrl (더블탭) = 녹음 시작/종료"
echo "   Ctrl+C = 서버 종료"
echo ""

open "$PROJECT_DIR/VoiceFlow.app"

# 앱 종료 대기
echo "📌 VoiceFlow.app 실행됨. 서버를 중지하려면 Ctrl+C를 누르세요."
wait_for_exit() {
    while pgrep -f "VoiceFlow.app/Contents/MacOS/VoiceFlow" > /dev/null 2>&1; do
        sleep 2
    done
}

trap 'kill $SERVER_PID 2>/dev/null; echo "👋 VoiceFlow stopped."' EXIT INT TERM
wait_for_exit
