// Generates the app launcher icons as PNGs with zero external tooling.
// Pure Dart: rasterises into an RGBA buffer and encodes PNG via dart:io ZLib.
//
//   dart run tool/gen_icon.dart
//
// Produces a glossy, 3D-shaded crown on a vignetted gradient:
//   assets/icon/app_icon.png     (full-bleed)
//   assets/icon/app_icon_fg.png  (transparent foreground for adaptive icons)

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

const int size = 1024;

class Img {
  final Uint8List px = Uint8List(size * size * 4);

  void set(int x, int y, int r, int g, int b, double a) {
    if (x < 0 || y < 0 || x >= size || y >= size) return;
    final i = (y * size + x) * 4;
    final ia = a.clamp(0.0, 1.0);
    px[i] = (r * ia + px[i] * (1 - ia)).round();
    px[i + 1] = (g * ia + px[i + 1] * (1 - ia)).round();
    px[i + 2] = (b * ia + px[i + 2] * (1 - ia)).round();
    px[i + 3] = math.max(px[i + 3], (255 * ia).round());
  }

  void fillCircle(double cx, double cy, double rad, List<int> c, [double alpha = 1]) {
    for (var y = (cy - rad).floor(); y <= (cy + rad).ceil(); y++) {
      for (var x = (cx - rad).floor(); x <= (cx + rad).ceil(); x++) {
        final d = math.sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));
        if (d <= rad) {
          final aa = (rad - d).clamp(0, 1.5) / 1.5;
          set(x, y, c[0], c[1], c[2], aa * alpha);
        }
      }
    }
  }

  /// Filled triangle whose colour is sampled from [shade] using the y value,
  /// giving a vertical gradient (top-lit → shadowed) for a 3D bevel.
  void fillTriShaded(
      List<double> a, List<double> b, List<double> cc, List<int> Function(double y) shade) {
    final minY = [a[1], b[1], cc[1]].reduce(math.min).floor();
    final maxY = [a[1], b[1], cc[1]].reduce(math.max).ceil();
    final minX = [a[0], b[0], cc[0]].reduce(math.min).floor();
    final maxX = [a[0], b[0], cc[0]].reduce(math.max).ceil();
    double sign(List<double> p1, List<double> p2, double px, double py) =>
        (px - p2[0]) * (p1[1] - p2[1]) - (p1[0] - p2[0]) * (py - p2[1]);
    for (var y = minY; y <= maxY; y++) {
      final col = shade(y.toDouble());
      for (var x = minX; x <= maxX; x++) {
        final d1 = sign(a, b, x + 0.5, y + 0.5);
        final d2 = sign(b, cc, x + 0.5, y + 0.5);
        final d3 = sign(cc, a, x + 0.5, y + 0.5);
        final neg = d1 < 0 || d2 < 0 || d3 < 0;
        final pos = d1 > 0 || d2 > 0 || d3 > 0;
        if (!(neg && pos)) set(x, y, col[0], col[1], col[2], 1);
      }
    }
  }

  void fillRectShaded(int x0, int y0, int x1, int y1, List<int> Function(double y) shade) {
    for (var y = y0; y < y1; y++) {
      final col = shade(y.toDouble());
      for (var x = x0; x < x1; x++) {
        set(x, y, col[0], col[1], col[2], 1);
      }
    }
  }

  /// Soft-edged filled ellipse (used for a flat ground shadow).
  void fillEllipse(double cx, double cy, double rx, double ry, List<int> c, double alpha) {
    for (var y = (cy - ry).floor(); y <= (cy + ry).ceil(); y++) {
      for (var x = (cx - rx).floor(); x <= (cx + rx).ceil(); x++) {
        final nx = (x - cx) / rx, ny = (y - cy) / ry;
        final d = math.sqrt(nx * nx + ny * ny);
        if (d <= 1) set(x, y, c[0], c[1], c[2], alpha * (1 - d) );
      }
    }
  }

  /// Glossy sphere: base fill, darkened underside, bright specular highlight.
  void gem(double cx, double cy, double r, List<int> base) {
    fillCircle(cx, cy + r * 0.2, r, [
      (base[0] * 0.45).round(),
      (base[1] * 0.45).round(),
      (base[2] * 0.45).round(),
    ], 0.6); // shadowed underside
    fillCircle(cx, cy, r, base);
    fillCircle(cx - r * 0.3, cy - r * 0.32, r * 0.4, [255, 255, 255], 0.85); // highlight
    fillCircle(cx - r * 0.34, cy - r * 0.36, r * 0.16, [255, 255, 255], 1); // hot spot
  }
}

List<int> lerp(List<int> a, List<int> b, double t) {
  t = t.clamp(0.0, 1.0);
  return [
    (a[0] + (b[0] - a[0]) * t).round(),
    (a[1] + (b[1] - a[1]) * t).round(),
    (a[2] + (b[2] - a[2]) * t).round(),
  ];
}

void drawCrown(Img img, double scale, double shiftY) {
  const cx = size / 2.0;
  final baseY = 660.0 + shiftY;
  final s = scale;
  double mx(double x) => cx + (x - cx) * s;
  double my(double y) => 512 + (y - 512) * s + shiftY;

  // Vertical gold gradient for the 3D bevel.
  const goldTop = [255, 240, 168];
  const goldMid = [255, 198, 62];
  const goldLow = [212, 132, 24];
  final topY = my(baseY - 270);
  final lowY = my(baseY + 96);
  List<int> gold(double y) {
    final t = ((y - topY) / (lowY - topY)).clamp(0.0, 1.0);
    return t < 0.5 ? lerp(goldTop, goldMid, t * 2) : lerp(goldMid, goldLow, (t - 0.5) * 2);
  }

  // Soft flat ground shadow beneath the crown.
  img.fillEllipse(cx, my(baseY + 118), 232 * s, 46 * s, [0, 0, 0], 0.32);

  // Base bar.
  img.fillRectShaded(mx(300).round(), my(baseY).round(), mx(724).round(),
      my(baseY + 96).round(), gold);
  // Dark rim along the very bottom for grounding.
  img.fillRectShaded(mx(300).round(), my(baseY + 78).round(), mx(724).round(),
      my(baseY + 96).round(), (_) => goldLow);

  // Three peaks.
  img.fillTriShaded([mx(300), my(baseY)], [mx(392), my(baseY)], [mx(335), my(baseY - 220)], gold);
  img.fillTriShaded([mx(432), my(baseY)], [mx(592), my(baseY)], [mx(512), my(baseY - 270)], gold);
  img.fillTriShaded([mx(632), my(baseY)], [mx(724), my(baseY)], [mx(689), my(baseY - 220)], gold);

  // Specular highlight streaks near the lit left face of each peak.
  void streak(double x, double y) =>
      img.fillCircle(x, y, 16 * s, [255, 255, 255], 0.5);
  streak(mx(322), my(baseY - 120));
  streak(mx(494), my(baseY - 150));
  streak(mx(676), my(baseY - 120));

  // Glossy jewels.
  img.gem(mx(335), my(baseY - 220), 34 * s, [49, 231, 255]);
  img.gem(mx(512), my(baseY - 270), 40 * s, [255, 90, 170]);
  img.gem(mx(689), my(baseY - 220), 34 * s, [49, 231, 255]);
  img.gem(mx(512), my(baseY + 46), 36 * s, [120, 220, 90]);
  img.gem(mx(410), my(baseY + 46), 24 * s, [49, 231, 255]);
  img.gem(mx(614), my(baseY + 46), 24 * s, [255, 90, 170]);
}

void main() {
  // ---- Full-bleed icon with a vignetted, radial-lit background ----
  final full = Img();
  const c0 = [150, 70, 255]; // lit centre (purple)
  const c1 = [92, 30, 180]; // mid
  const c2 = [40, 12, 74]; // dark corners
  final lightX = size * 0.42, lightY = size * 0.34;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final dx = (x - lightX) / size, dy = (y - lightY) / size;
      final d = math.sqrt(dx * dx + dy * dy);
      final col = d < 0.5 ? lerp(c0, c1, d * 2) : lerp(c1, c2, (d - 0.5) * 2);
      // magenta wash toward the bottom
      final mag = lerp(col, const [255, 46, 139], (y / size) * 0.35);
      final i = (y * size + x) * 4;
      full.px[i] = mag[0];
      full.px[i + 1] = mag[1];
      full.px[i + 2] = mag[2];
      full.px[i + 3] = 255;
    }
  }
  drawCrown(full, 1.0, -10);

  // ---- Adaptive foreground (transparent, crown scaled into the safe zone) ----
  final fg = Img();
  drawCrown(fg, 0.6, -18);

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
    8, 6, 0, 0, 0,
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
