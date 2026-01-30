import AppKit
import AudioToolbox

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var hotkeyManager: HotkeyManager!
    private var audioRecorder: AudioRecorder!
    private var asrClient: ASRClient!
    private var textInjector: TextInjector!
    private var overlayPanel: OverlayPanel!
    private var isRecording = false

    private var startSoundID: SystemSoundID = 0
    private var stopSoundID: SystemSoundID = 0

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[AppDelegate] applicationDidFinishLaunching called!")
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

        // Load sounds via AudioServices (bypasses AVCaptureSession output blocking)
        loadSounds()

        overlayPanel = OverlayPanel()
        textInjector = TextInjector()
        asrClient = ASRClient()
        audioRecorder = AudioRecorder()
        audioRecorder.onAudioChunk = { [weak self] data in
            self?.asrClient.sendAudioChunk(data)
        }

        asrClient.onTranscriptionResult = { [weak self] text in
            guard let self else { return }
            DispatchQueue.main.async {
                self.overlayPanel.showDone()
                if !text.isEmpty {
                    self.textInjector.inject(text: text)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.overlayPanel.hide()
                }
            }
        }

        asrClient.onConnectionStatusChanged = { [weak self] connected in
            DispatchQueue.main.async {
                self?.statusBarController.updateConnectionStatus(connected: connected)
            }
        }

        statusBarController = StatusBarController()
        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }

        hotkeyManager = HotkeyManager()
        hotkeyManager.onDoubleTap = { [weak self] in
            self?.toggleRecording()
        }
        hotkeyManager.start()

        audioRecorder.prepare()
        asrClient.connect()
    }

    private func loadSounds() {
        let startURL = URL(fileURLWithPath: "/System/Library/Sounds/Tink.aiff")
        let stopURL = URL(fileURLWithPath: "/System/Library/Sounds/Pop.aiff")

        var status = AudioServicesCreateSystemSoundID(startURL as CFURL, &startSoundID)
        if status == noErr {
            NSLog("[Audio] startSound loaded via AudioServices (ID: %d)", startSoundID)
        } else {
            NSLog("[Audio] ERROR: Failed to load startSound (status: %d)", status)
        }

        status = AudioServicesCreateSystemSoundID(stopURL as CFURL, &stopSoundID)
        if status == noErr {
            NSLog("[Audio] stopSound loaded via AudioServices (ID: %d)", stopSoundID)
        } else {
            NSLog("[Audio] ERROR: Failed to load stopSound (status: %d)", status)
        }
    }

    private func playSound(_ soundID: SystemSoundID, name: String) {
        guard soundID != 0 else {
            NSLog("[Audio] WARNING: %@ not loaded, cannot play", name)
            return
        }
        AudioServicesPlaySystemSound(soundID)
        NSLog("[Audio] %@ played via AudioServices", name)
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        NSLog("[Recording] Starting recording, playing start sound")
        playSound(startSoundID, name: "startSound")
        overlayPanel.showRecording()
        statusBarController.updateRecordingStatus(recording: true)
        asrClient.sendStart()
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        isRecording = false
        NSLog("[Recording] Stopping recording, playing stop sound")
        playSound(stopSoundID, name: "stopSound")
        audioRecorder.stopRecording()
        overlayPanel.showProcessing()
        statusBarController.updateRecordingStatus(recording: false)
        asrClient.sendStop()
    }
}
