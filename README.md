# VoiceFlow

Wispr Flow 스타일의 음성-텍스트 입력 앱. 어디서든 단축키를 누르면 음성 인식이 시작되고, 현재 포커스된 입력창에 텍스트를 바로 타이핑해준다.

## 핵심 기능
- **글로벌 단축키** (예: ⌥Space) → 음성 인식 시작/종료
- **실시간 STT** → Qwen3-ASR-1.7B 로컬 모델 사용
- **자동 입력** → 인식된 텍스트를 현재 포커스된 앱의 입력창에 타이핑
- **오버레이 UI** → 녹음 중 상태 표시 (플로팅 인디케이터)

## 기술 스택
- **STT 엔진:** Qwen3-ASR-1.7B (로컬, Python)
- **앱 프레임워크:** Swift + AppKit (macOS 네이티브)
- **키 입력 시뮬:** CGEvent / Accessibility API
- **통신:** Python ↔ Swift (로컬 WebSocket 또는 Unix socket)

## 아키텍처
```
┌─────────────┐     WebSocket      ┌──────────────┐
│  Swift App  │ ◄────────────────► │  ASR Server  │
│  (macOS UI) │                    │  (Python)    │
│  - 단축키    │                    │  - Qwen3-ASR │
│  - 오버레이  │                    │  - 스트리밍   │
│  - 텍스트입력│                    │              │
└─────────────┘                    └──────────────┘
```

## 프로젝트 구조
```
voiceflow/
├── README.md
├── server/          # Python ASR 서버
│   ├── main.py      # WebSocket ASR 서버
│   └── requirements.txt
├── app/             # macOS Swift 앱
│   └── VoiceFlow/
└── scripts/         # 빌드/실행 스크립트
```
