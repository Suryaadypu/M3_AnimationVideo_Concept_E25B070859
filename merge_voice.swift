import AVFoundation
import Foundation

@main
struct MergeVoice {
    static func main() async throws {
        guard CommandLine.arguments.count == 10 else {
            fatalError("Usage: merge_voice.swift silent-video scene01.wav ... scene06.wav music.wav output.mp4")
        }
        let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
        let musicURL = URL(fileURLWithPath: CommandLine.arguments[8])
        let outputURL = URL(fileURLWithPath: CommandLine.arguments[9])
        try? FileManager.default.removeItem(at: outputURL)

        let source = AVURLAsset(url: sourceURL)
        let sourceVideo = try await source.loadTracks(withMediaType: .video)
        guard let sourceVideoTrack = sourceVideo.first else { fatalError("Video track missing") }
        let duration = try await source.load(.duration)

        let composition = AVMutableComposition()
        let pauseAfterScene = 6.0
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { fatalError("Could not create video track") }
        try videoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: duration),
            of: sourceVideoTrack,
            at: .zero
        )
        videoTrack.preferredTransform = try await sourceVideoTrack.load(.preferredTransform)

        guard let narrationTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { fatalError("Could not create audio track") }

        guard let musicTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else { fatalError("Could not create music track") }
        let musicAsset = AVURLAsset(url: musicURL)
        guard let musicSource = try await musicAsset.loadTracks(withMediaType: .audio).first else {
            fatalError("Music track missing in \(musicURL.lastPathComponent)")
        }
        let musicDuration = try await musicAsset.load(.duration)
        try musicTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: min(duration, musicDuration)),
            of: musicSource,
            at: .zero
        )

        var narrationCursor = 5.0
        for scene in 0..<6 {
            let audioURL = URL(fileURLWithPath: CommandLine.arguments[scene + 2])
            let asset = AVURLAsset(url: audioURL)
            guard let audio = try await asset.loadTracks(withMediaType: .audio).first else {
                fatalError("Audio track missing in \(audioURL.lastPathComponent)")
            }
            let audioDuration = try await asset.load(.duration)
            let start = CMTime(seconds: narrationCursor, preferredTimescale: 600)
            try narrationTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: audioDuration),
                of: audio,
                at: start
            )
            narrationCursor += CMTimeGetSeconds(audioDuration) + pauseAfterScene
        }

        guard let exporter = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else { fatalError("Could not create MP4 exporter") }
        exporter.outputURL = outputURL
        exporter.outputFileType = .mp4
        exporter.shouldOptimizeForNetworkUse = true
        let audioMix = AVMutableAudioMix()
        let voiceMix = AVMutableAudioMixInputParameters(track: narrationTrack)
        voiceMix.audioTimePitchAlgorithm = .timeDomain
        let musicMix = AVMutableAudioMixInputParameters(track: musicTrack)
        musicMix.setVolume(0.55, at: .zero)
        audioMix.inputParameters = [voiceMix, musicMix]
        exporter.audioMix = audioMix
        try await exporter.export()
        print("Created voiced video: \(outputURL.path)")
    }
}
