import AppKit
import AVFoundation

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController!
    private var hotkeyManager: HotkeyManager!
    private var audioRecorder: AudioRecorder!
    private var asrClient: ASRClient!
    private var textInjector: TextInjector!
    private var overlayPanel: OverlayPanel!
    private var isRecording = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("[AppDelegate] applicationDidFinishLaunching called!")
        // Hide dock icon
        NSApp.setActivationPolicy(.accessory)

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

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        overlayPanel.showRecording()
        statusBarController.updateRecordingStatus(recording: true)
        asrClient.sendStart()
        audioRecorder.startRecording()
    }

    private func stopRecording() {
        isRecording = false
        audioRecorder.stopRecording()
        overlayPanel.showProcessing()
        statusBarController.updateRecordingStatus(recording: false)
        asrClient.sendStop()
    }
}
