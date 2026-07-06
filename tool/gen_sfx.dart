// Synthesises the game's sound effects as 16-bit PCM WAV files — no external
// tooling, no downloaded audio.
//
//   dart run tool/gen_sfx.dart
//
// Writes assets/sfx/*.wav (tap, summon, merge, bigmerge, waveclear, boss, error).

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const int sampleRate = 44100;

/// One additive tone with its own frequency glide and volume.
class Tone {
  final double f0, f1, amp;
  final bool square;
  Tone(this.f0, this.f1, {this.amp = 1, this.square = false});
}

/// Render [tones] over [ms] with an attack/exponential-decay envelope.
Uint8List render(double ms, List<Tone> tones,
    {double attack = 0.005, double decay = 4, double gain = 0.36, double tremolo = 0}) {
  final n = (sampleRate * ms / 1000).round();
  final samples = Int16List(n);
  for (var i = 0; i < n; i++) {
    final t = i / sampleRate;
    final prog = i / n;
    // envelope
    final atk = (t / attack).clamp(0.0, 1.0);
    final env = atk * math.exp(-decay * prog);
    final trem = tremolo > 0 ? (0.75 + 0.25 * math.sin(2 * math.pi * tremolo * t)) : 1.0;
    double v = 0;
    for (final tone in tones) {
      final f = tone.f0 + (tone.f1 - tone.f0) * prog;
      final phase = 2 * math.pi * f * t;
      final wave = tone.square ? (math.sin(phase) >= 0 ? 1.0 : -1.0) : math.sin(phase);
      v += wave * tone.amp;
    }
    final s = (v * env * trem * gain / _sumAmp(tones)).clamp(-1.0, 1.0);
    samples[i] = (s * 32767).round();
  }
  return _wav(samples);
}

double _sumAmp(List<Tone> tones) {
  var s = 0.0;
  for (final t in tones) {
    s += t.amp;
  }
  return s == 0 ? 1 : s;
}

Uint8List _wav(Int16List samples) {
  final dataBytes = samples.buffer.asUint8List();
  final b = BytesBuilder();
  void s(String x) => b.add(x.codeUnits);
  void u32(int v) => b.add([v & 255, (v >> 8) & 255, (v >> 16) & 255, (v >> 24) & 255]);
  void u16(int v) => b.add([v & 255, (v >> 8) & 255]);

  s('RIFF');
  u32(36 + dataBytes.length);
  s('WAVE');
  s('fmt ');
  u32(16);
  u16(1); // PCM
  u16(1); // mono
  u32(sampleRate);
  u32(sampleRate * 2); // byte rate
  u16(2); // block align
  u16(16); // bits
  s('data');
  u32(dataBytes.length);
  b.add(dataBytes);
  return b.toBytes();
}

void main() {
  Directory('assets/sfx').createSync(recursive: true);

  final sounds = <String, Uint8List>{
    // crisp UI click
    'tap': render(70, [Tone(1400, 1200)], decay: 6, gain: 0.28),
    // upward summon whoosh
    'summon': render(190, [Tone(420, 880, amp: 1), Tone(840, 1760, amp: 0.4)], decay: 3.5),
    // pleasant two-note merge
    'merge': render(240, [Tone(660, 990, amp: 1), Tone(990, 1320, amp: 0.5)], decay: 3.2, gain: 0.4),
    // big triumphant chord for high-tier merges
    'bigmerge': render(430, [
      Tone(523, 523, amp: 1),
      Tone(659, 659, amp: 0.9),
      Tone(784, 880, amp: 0.9),
    ], decay: 2.2, gain: 0.42),
    // shiny rising wave-clear
    'waveclear': render(300, [Tone(600, 1200, amp: 1), Tone(900, 1500, amp: 0.4)], decay: 2.6, gain: 0.4),
    // deep boss boom with tremolo
    'boss': render(560, [
      Tone(120, 90, amp: 1),
      Tone(180, 140, amp: 0.6),
      Tone(60, 55, amp: 0.8),
    ], decay: 2.0, gain: 0.5, tremolo: 12),
    // low error buzz
    'error': render(160, [Tone(200, 150, amp: 1, square: true)], decay: 5, gain: 0.22),
  };

  sounds.forEach((name, bytes) {
    File('assets/sfx/$name.wav').writeAsBytesSync(bytes);
  });
  stdout.writeln('Wrote ${sounds.length} sfx to assets/sfx/');
}
