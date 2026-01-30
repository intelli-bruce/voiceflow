# VoiceFlow

macOS 네이티브 음성 입력 앱. 글로벌 단축키(Ctrl 더블탭)로 음성 인식을 시작하고, 인식된 텍스트를 현재 포커스된 앱에 자동으로 입력합니다.

> Wispr Flow의 로컬 오픈소스 대안 — 모든 데이터는 로컬에서 처리됩니다.

## 주요 기능

- **Ctrl 더블탭** — 어디서든 녹음 시작/종료
- **실시간 음성 인식** — Qwen3-ASR-1.7B 모델 (MPS GPU 가속)
- **자동 텍스트 입력** — 인식 결과를 현재 포커스된 앱에 붙여넣기
- **플로팅 오버레이** — 녹음/인식/완료 상태 표시
- **메뉴바 아이콘** — ASR 서버 연결 상태 확인
- **52개 언어 지원** — 한국어 기본, 다국어 가능

## 요구사항

- macOS 14+ (Sonoma)
- Python 3.12+
- Apple Silicon Mac (MPS GPU 가속)

## 설치

### 1. ASR 서버 (Python)

```bash
# venv 생성
python3 -m venv .venvs/qwen3-asr
source .venvs/qwen3-asr/bin/activate

# 의존성 설치
pip install qwen-asr websockets numpy soundfile

# 서버 실행
python server/main.py
```

첫 실행 시 모델을 자동 다운로드합니다 (~3.5GB).

### 2. Swift 앱

```bash
cd VoiceFlow
swift build

# .app 번들 생성
cd ..
bash scripts/bundle.sh

# 실행
open VoiceFlow.app
# 또는 터미널에서 직접:
VoiceFlow.app/Contents/MacOS/VoiceFlow
```

### 3. 권한 설정

시스템 설정 → 개인정보 보호 및 보안:
- **입력 모니터링** → VoiceFlow 허용
- **손쉬운 사용** → VoiceFlow 허용
- **마이크** → VoiceFlow 허용

## 사용법

1. ASR 서버 실행 (`python server/main.py`)
2. VoiceFlow 앱 실행
3. **Ctrl 더블탭** → 말하기 → **Ctrl 더블탭** → 텍스트 입력됨

## 프로젝트 구조

```
voiceflow/
├── server/
│   ├── main.py              # WebSocket ASR 서버 (Qwen3-ASR + MPS)
│   └── requirements.txt
├── VoiceFlow/               # Swift Package
│   ├── Package.swift
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── VoiceFlowApp.swift
│   │   │   └── AppDelegate.swift
│   │   ├── Core/
│   │   │   ├── HotkeyManager.swift    # Ctrl 더블탭 감지
│   │   │   ├── AudioRecorder.swift    # AVCaptureSession 마이크 캡처
│   │   │   ├── ASRClient.swift        # WebSocket 클라이언트
│   │   │   └── TextInjector.swift     # 클립보드 + Cmd+V 입력
│   │   └── UI/
│   │       ├── OverlayPanel.swift     # 플로팅 오버레이
│   │       └── StatusBarController.swift
│   └── Resources/
│       └── Info.plist
├── scripts/
│   ├── start-server.sh
│   └── bundle.sh
├── PRD.md
└── README.md
```

## 성능

| 오디오 길이 | 처리 시간 (MPS) | 비고 |
|------------|----------------|------|
| ~2초 | ~0.7초 | |
| ~3.5초 | ~1.0초 | |
| ~5초 | ~2.0초 | |
| 첫 추론 | ~9초 | MPS 셰이더 컴파일 (1회성) |

## 라이선스

MIT
