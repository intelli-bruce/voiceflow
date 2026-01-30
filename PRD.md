# VoiceFlow - Product Requirements Document

## 개요
macOS 네이티브 음성 입력 앱. 글로벌 단축키(Ctrl 더블탭)로 음성 인식을 시작하고, 인식된 텍스트를 현재 포커스된 앱의 입력창에 자동으로 타이핑한다. Wispr Flow의 로컬 오픈소스 대안.

## 핵심 UX 플로우
1. 앱이 백그라운드에서 상시 실행 (메뉴바 아이콘)
2. 사용자가 **Ctrl 키를 빠르게 2번** 누름 (300ms 이내)
3. 화면에 **플로팅 오버레이** 표시 (녹음 중 표시)
4. 사용자가 말함
5. **Ctrl 더블탭** 다시 누르면 녹음 종료
6. 인식된 텍스트가 현재 포커스된 앱의 커서 위치에 타이핑됨
7. 오버레이 사라짐

## 기능 요구사항

### F1: 글로벌 단축키 - Ctrl 더블탭
- **트리거:** Left Control 키를 300ms 이내에 2번 연속 탭
- Ctrl을 다른 키와 조합해서 누르는 경우는 무시 (Ctrl+C 등)
- 단독 Ctrl 탭만 카운트
- 토글 방식: 첫 더블탭 → 녹음 시작, 두번째 더블탭 → 녹음 종료 + 인식 결과 입력
- 어떤 앱이 포커스되어 있든 동작해야 함 (글로벌 이벤트 모니터링)

### F2: 오디오 캡처
- macOS 기본 입력 장치(마이크)에서 오디오 캡처
- 샘플레이트: 16kHz mono (ASR 모델 최적)
- 포맷: Float32 PCM
- 녹음 중 오디오 데이터를 ASR 서버로 스트리밍 전송

### F3: ASR 서버 (Python)
- WebSocket 서버 (localhost:9876)
- Qwen3-ASR-1.7B 모델 사용 (transformers 백엔드)
- venv 경로: /Users/brucechoe/clawd/.venvs/qwen3-asr/
- 언어: Korean 고정
- 프로토콜:
  - Client → Server: binary audio chunks (PCM float32, 16kHz mono)
  - Client → Server: JSON `{"type": "start"}`, `{"type": "stop"}`
  - Server → Client: JSON `{"type": "partial", "text": "..."}` (중간 결과)
  - Server → Client: JSON `{"type": "final", "text": "..."}` (최종 결과)
- stop 수신 시 전체 누적 오디오를 모델에 전달하여 최종 인식
- 모델은 서버 시작 시 한 번만 로드 (메모리 상주)

### F4: 텍스트 입력 시뮬레이션
- 인식된 텍스트를 현재 포커스된 앱에 입력
- 방법: CGEvent 키 입력 시뮬레이션 또는 NSPasteboard + Cmd+V 붙여넣기
- 권장: 클립보드 방식 (한글 입력 호환성 좋음)
  1. 현재 클립보드 백업
  2. 인식 텍스트를 클립보드에 복사
  3. Cmd+V 키 이벤트 시뮬레이션
  4. 원래 클립보드 복원
- Accessibility 권한 필요 (시스템 설정에서 허용)

### F5: 플로팅 오버레이 UI
- 항상 최상위 (모든 앱 위에 표시)
- 위치: 화면 상단 중앙 또는 커서 근처
- 크기: 작고 심플 (pill shape)
- 상태 표시:
  - 🔴 녹음 중: 빨간 점 + "녹음 중..." 텍스트 + 파형 애니메이션
  - ⏳ 인식 중: "인식 중..." 텍스트
  - ✅ 완료: 잠깐 "완료" 표시 후 사라짐
- NSPanel (non-activating) 사용 → 포커스를 뺏지 않음
- 반투명 배경, 다크 테마

### F6: 메뉴바 아이콘
- 상태 표시: 대기/녹음 중/인식 중
- 클릭 시 메뉴:
  - ASR 서버 상태 (연결됨/끊어짐)
  - 설정 (나중에)
  - 종료

## 비기능 요구사항

### 성능
- 모델 로딩: 앱 시작 시 1회 (ASR 서버가 모델을 메모리에 유지)
- 인식 지연: 녹음 종료 후 3초 이내 결과 반환 (30초 이하 오디오 기준)
- 메모리: ASR 서버 ~4GB (1.7B 모델), Swift 앱 ~50MB

### 안정성
- ASR 서버 연결 끊김 시 자동 재연결
- 서버 미실행 시 사용자에게 알림
- 앱 크래시 시 녹음 자동 중단

### 보안/권한
- 마이크 접근 권한 (Info.plist)
- Accessibility 권한 (키 입력 시뮬레이션)
- 입력 모니터링 권한 (글로벌 키 감지)
- 모든 데이터는 로컬에서만 처리 (네트워크 전송 없음)

## 기술 구현 세부사항

### Swift 앱 (macOS, SwiftUI + AppKit)
- 최소 지원: macOS 14 (Sonoma)
- Swift 5.9+
- 빌드: Xcode project 또는 Swift Package
- 의존성:
  - URLSessionWebSocketTask (내장 WebSocket)
  - AVFoundation (오디오 캡처)
  - Carbon (글로벌 핫키) 또는 CGEvent tap
  - AppKit (NSPanel, NSStatusBar)

### Python ASR 서버
- Python 3.12
- venv: /Users/brucechoe/clawd/.venvs/qwen3-asr/
- 의존성: qwen-asr, websockets, numpy, soundfile
- 실행: `python server/main.py`
- 포트: 9876

### 프로젝트 구조
```
voiceflow/
├── README.md
├── PRD.md
├── server/
│   ├── main.py              # WebSocket ASR 서버
│   └── requirements.txt     # 추가 의존성 (websockets)
├── VoiceFlow/               # Xcode 프로젝트
│   ├── VoiceFlow.xcodeproj/
│   ├── Sources/
│   │   ├── App/
│   │   │   ├── VoiceFlowApp.swift       # 앱 엔트리포인트, 메뉴바
│   │   │   └── AppDelegate.swift        # 앱 생명주기
│   │   ├── Core/
│   │   │   ├── HotkeyManager.swift      # Ctrl 더블탭 감지
│   │   │   ├── AudioRecorder.swift      # 마이크 캡처
│   │   │   ├── ASRClient.swift          # WebSocket 클라이언트
│   │   │   └── TextInjector.swift       # 텍스트 입력 시뮬레이션
│   │   └── UI/
│   │       ├── OverlayPanel.swift       # 플로팅 오버레이
│   │       └── StatusBarController.swift # 메뉴바 아이콘
│   ├── Resources/
│   │   └── Assets.xcassets
│   └── Info.plist
└── scripts/
    ├── start-server.sh      # ASR 서버 시작
    └── build.sh             # 앱 빌드
```

## 개발 순서
1. **Phase 1:** Python ASR WebSocket 서버
2. **Phase 2:** Swift 앱 기본 구조 (메뉴바 + 글로벌 단축키)
3. **Phase 3:** 오디오 캡처 + WebSocket 연결
4. **Phase 4:** 텍스트 입력 시뮬레이션
5. **Phase 5:** 플로팅 오버레이 UI
6. **Phase 6:** 통합 테스트 + 폴리싱
