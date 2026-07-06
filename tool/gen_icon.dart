// Generates the app launcher icons as PNGs with zero external tooling.
// Pure Dart: rasterises into an RGBA buffer and encodes PNG via dart:io ZLib.
//
//   dart run tool/gen_icon.dart
//
// Produces assets/icon/app_icon.png (full-bleed) and app_icon_fg.png
// (transparent foreground for Android adaptive icons).

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

const int size = 1024;

class Img {
  final Uint8List px = Uint8List(size * size * 4);

  void set(int x, int y, int r, int g, int b, int a) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;
    final i = (y * size + x) * 4;
    // simple source-over blend
    final ia = a / 255.0;
    px[i] = (r * ia + px[i] * (1 - ia)).round();
    px[i + 1] = (g * ia + px[i + 1] * (1 - ia)).round();
    px[i + 2] = (b * ia + px[i + 2] * (1 - ia)).round();
    px[i + 3] = math.max(px[i + 3], a);
  }

  void fillRect(int x0, int y0, int x1, int y1, List<int> c) {
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        set(x, y, c[0], c[1], c[2], c.length > 3 ? c[3] : 255);
      }
    }
  }

  void fillCircle(double cx, double cy, double rad, List<int> c) {
    for (var y = (cy - rad).floor(); y <= (cy + rad).ceil(); y++) {
      for (var x = (cx - rad).floor(); x <= (cx + rad).ceil(); x++) {
        final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
        if (d <= rad) {
          final edge = (rad - d).clamp(0, 1.5) / 1.5; // AA
          set(x, y, c[0], c[1], c[2], (255 * edge).round());
        }
      }
    }
  }

  void fillTriangle(List<double> a, List<double> b, List<double> cc, List<int> col) {
    final minY = [a[1], b[1], cc[1]].reduce(math.min).floor();
    final maxY = [a[1], b[1], cc[1]].reduce(math.max).ceil();
    final minX = [a[0], b[0], cc[0]].reduce(math.min).floor();
    final maxX = [a[0], b[0], cc[0]].reduce(math.max).ceil();
    double sign(List<double> p1, List<double> p2, double px, double py) =>
        (px - p2[0]) * (p1[1] - p2[1]) - (p1[0] - p2[0]) * (py - p2[1]);
    for (var y = minY; y <= maxY; y++) {
      for (var x = minX; x <= maxX; x++) {
        final d1 = sign(a, b, x + 0.5, y + 0.5);
        final d2 = sign(b, cc, x + 0.5, y + 0.5);
        final d3 = sign(cc, a, x + 0.5, y + 0.5);
        final neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
        final pos = (d1 > 0) || (d2 > 0) || (d3 > 0);
        if (!(neg && pos)) {
          set(x, y, col[0], col[1], col[2], 255);
        }
      }
    }
  }
}

List<int> lerp(List<int> a, List<int> b, double t) => [
      (a[0] + (b[0] - a[0]) * t).round(),
      (a[1] + (b[1] - a[1]) * t).round(),
      (a[2] + (b[2] - a[2]) * t).round(),
    ];

void drawCrown(Img img, double scale, double shiftY) {
  const cx = size / 2.0;
  final baseY = 640.0 + shiftY;
  final s = scale;
  double mx(double x) => cx + (x - cx) * s;
  double my(double y) => 512 + (y - 512) * s + shiftY;

  const gold = [255, 201, 60];
  const goldDeep = [255, 150, 20];
  const cyan = [49, 231, 255];
  const white = [255, 255, 255];

  // Shadow
  img.fillRect(mx(300).round(), (my(baseY) + 14).round(), mx(724).round(),
      (my(baseY + 96) + 14).round(), [0, 0, 0, 60]);

  // Base bar
  img.fillRect(mx(300).round(), my(baseY).round(), mx(724).round(),
      my(baseY + 96).round(), gold);
  // Deeper bottom edge
  img.fillRect(mx(300).round(), my(baseY + 70).round(), mx(724).round(),
      my(baseY + 96).round(), goldDeep);

  // Three peaks
  img.fillTriangle([mx(300), my(baseY)], [mx(392), my(baseY)],
      [mx(335), my(baseY - 210)], gold);
  img.fillTriangle([mx(432), my(baseY)], [mx(592), my(baseY)],
      [mx(512), my(baseY - 260)], gold);
  img.fillTriangle([mx(632), my(baseY)], [mx(724), my(baseY)],
      [mx(689), my(baseY - 210)], gold);

  // Jewels on the peaks and base
  img.fillCircle(mx(335), my(baseY - 210), 30 * s, cyan);
  img.fillCircle(mx(512), my(baseY - 260), 36 * s, white);
  img.fillCircle(mx(689), my(baseY - 210), 30 * s, cyan);
  img.fillCircle(mx(512), my(baseY + 48), 34 * s, cyan);
  img.fillCircle(mx(410), my(baseY + 48), 22 * s, white);
  img.fillCircle(mx(614), my(baseY + 48), 22 * s, white);
}

void main() {
  // ---- Full-bleed icon ----
  final full = Img();
  const topCol = [123, 44, 255]; // purple
  const botCol = [255, 46, 139]; // magenta
  for (var y = 0; y < size; y++) {
    final t = y / size;
    final row = lerp(topCol, botCol, t);
    for (var x = 0; x < size; x++) {
      final i = (y * size + x) * 4;
      full.px[i] = row[0];
      full.px[i + 1] = row[1];
      full.px[i + 2] = row[2];
      full.px[i + 3] = 255;
    }
  }
  // Soft top-left glow
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final d = math.sqrt(x * x + y * y) / (size * 1.1);
      final glow = ((1 - d).clamp(0, 1) * 60).round();
      if (glow > 0) full.set(x, y, 255, 255, 255, glow);
    }
  }
  drawCrown(full, 1.0, 0);

  // ---- Adaptive foreground (transparent, crown scaled into safe zone) ----
  final fg = Img();
  drawCrown(fg, 0.62, -10);

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/app_icon.png').writeAsBytesSync(encodePng(full.px));
  File('assets/icon/app_icon_fg.png').writeAsBytesSync(encodePng(fg.px));
  stdout.writeln('Wrote assets/icon/app_icon.png and app_icon_fg.png');
}

// ---------------------------------------------------------------- PNG encoder
Uint8List encodePng(Uint8List rgba) {
  final raw = BytesBuilder();
  for (var y = 0; y < size; y++) {
    raw.addByte(0); // filter: none
    raw.add(Uint8List.sublistView(rgba, y * size * 4, (y + 1) * size * 4));
  }
  final compressed = ZLibCodec(level: 6).encode(raw.toBytes());

  final out = BytesBuilder();
  out.add([137, 80, 78, 71, 13, 10, 26, 10]); // signature

  void chunk(String type, List<int> data) {
    final len = data.length;
    out.add([(len >> 24) & 255, (len >> 16) & 255, (len >> 8) & 255, len & 255]);
    final typeBytes = type.codeUnits;
    final body = <int>[...typeBytes, ...data];
    out.add(typeBytes);
    out.add(data);
    final crc = _crc32(body);
    out.add([(crc >> 24) & 255, (crc >> 16) & 255, (crc >> 8) & 255, crc & 255]);
  }

  final ihdr = <int>[
    (size >> 24) & 255, (size >> 16) & 255, (size >> 8) & 255, size & 255,
    (size >> 24) & 255, (size >> 16) & 255, (size >> 8) & 255, size & 255,
    8, 6, 0, 0, 0, // bit depth 8, color type 6 (RGBA)
  ];
  chunk('IHDR', ihdr);
  chunk('IDAT', compressed);
  chunk('IEND', const []);
  return out.toBytes();
}

final List<int> _crcTable = () {
  final t = List<int>.filled(256, 0);
  for (var n = 0; n < 256; n++) {
    var c = n;
    for (var k = 0; k < 8; k++) {
      c = (c & 1) != 0 ? (0xEDB88320 ^ (c >> 1)) : (c >> 1);
    }
    t[n] = c;
  }
  return t;
}();

int _crc32(List<int> data) {
  var crc = 0xFFFFFFFF;
  for (final b in data) {
    crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
  }
  return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}
