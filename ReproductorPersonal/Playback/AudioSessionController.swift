import AVFoundation

enum AudioSessionController {
    static func configure() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .moviePlayback)
        try session.setActive(true)
    }
}
