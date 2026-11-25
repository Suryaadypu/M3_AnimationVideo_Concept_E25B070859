import Foundation

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "background_music.wav"
let sampleRate = 24_000
let duration = 306.52
let frames = Int(duration * Double(sampleRate))
let bpm = 82.0
let beat = 60.0 / bpm
let bar = beat * 4
let chords: [[Double]] = [
    [146.83, 185.00, 220.00, 277.18], // D
    [123.47, 146.83, 185.00, 220.00], // B minor
    [98.00, 123.47, 146.83, 185.00],  // G
    [110.00, 138.59, 164.81, 220.00]  // A
]
let pattern = [0, 2, 1, 3, 2, 1, 0, 1]
var pcm = [Int16](repeating: 0, count: frames)

for frame in 0..<frames {
    let t = Double(frame) / Double(sampleRate)
    let barIndex = Int(t / bar)
    let chord = chords[barIndex % chords.count]
    let beatPosition = t.truncatingRemainder(dividingBy: beat)
    let barPosition = t.truncatingRemainder(dividingBy: bar)

    var pad = 0.0
    for (i, frequency) in chord.enumerated() {
        let phase = 2 * Double.pi * frequency * t
        let tone = sin(phase) + 0.18 * sin(phase * 2)
        let slowPulse = 0.78 + 0.22 * sin(Double.pi * barPosition / bar)
        pad += tone * slowPulse * (i == 0 ? 0.020 : 0.015)
    }

    let eighth = beat / 2
    let step = Int(t / eighth)
    let stepAge = t.truncatingRemainder(dividingBy: eighth)
    let note = chord[pattern[step % pattern.count]] * 2
    let pluckPhase = 2 * Double.pi * note * stepAge
    let pluckEnvelope = exp(-stepAge * 4.6)
    let pluck = (sin(pluckPhase) + 0.22 * sin(pluckPhase * 2)) * pluckEnvelope * 0.075

    let beatNumber = Int(t / beat) % 4
    var kick = 0.0
    if beatNumber == 0 || beatNumber == 2 {
        let phase = 2 * Double.pi * (54 * beatPosition + 18 * (1 - exp(-beatPosition * 12)))
        kick = sin(phase) * exp(-beatPosition * 9) * 0.065
    }

    let fadeIn = min(1.0, t / 2.0)
    let fadeOut = min(1.0, (duration - t) / 3.0)
    let value = max(-0.82, min(0.82, (pad + pluck + kick) * fadeIn * fadeOut))
    pcm[frame] = Int16(value * Double(Int16.max))
}

func appendLE<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
    var little = value.littleEndian
    withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
}

var header = Data()
header.append(contentsOf: Array("RIFF".utf8))
appendLE(UInt32(36 + frames * 2), to: &header)
header.append(contentsOf: Array("WAVEfmt ".utf8))
appendLE(UInt32(16), to: &header)
appendLE(UInt16(1), to: &header)
appendLE(UInt16(1), to: &header)
appendLE(UInt32(sampleRate), to: &header)
appendLE(UInt32(sampleRate * 2), to: &header)
appendLE(UInt16(2), to: &header)
appendLE(UInt16(16), to: &header)
header.append(contentsOf: Array("data".utf8))
appendLE(UInt32(frames * 2), to: &header)

let file = FileManager.default.createFile(atPath: output, contents: nil)
guard file, let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: output)) else {
    fatalError("Could not create music file at \(output)")
}
try handle.write(contentsOf: header)
pcm.withUnsafeBufferPointer { buffer in
    if let base = buffer.baseAddress {
        try? handle.write(contentsOf: Data(bytes: base, count: buffer.count * MemoryLayout<Int16>.size))
    }
}
try handle.close()
print("Created original quiet instrumental: \(output) (\(Int(duration)) seconds, \(bpm) BPM)")
