// Cleans up assets/images/loading.gif so it blends into the app background.
//
// The source animation has two baked-in artifacts:
//  1. GIF transparency is 1-bit, so anti-aliased edges were flattened into a
//     dark fringe line along the artwork's outline.
//  2. Palette dithering left stray light speckles inside flat fills.
//
// This tool composites every frame onto AppColors.paper (#F6F4EF), then
// removes the dark fringe (dark pixels touching the background get recolored
// to the majority of their light neighbors) and despeckles flat areas.
//
// Run after replacing the animation (or changing AppColors.paper):
//   dart run tool/rematte_gif.dart
import 'dart:io';

import 'package:image/image.dart' as img;

// Keep in sync with AppColors.paper.
const _paperR = 0xF6, _paperG = 0xF4, _paperB = 0xEF;

bool _isPaper(num r, num g, num b) =>
    (r - _paperR).abs() < 14 &&
    (g - _paperG).abs() < 14 &&
    (b - _paperB).abs() < 14;

double _lum(num r, num g, num b) => 0.299 * r + 0.587 * g + 0.114 * b;

void main() {
  const path = 'assets/images/loading.gif';
  final paper = img.ColorRgb8(_paperR, _paperG, _paperB);

  final source = img.decodeGif(File(path).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode $path');
    exit(1);
  }

  img.Image? result;
  for (final frame in source.frames) {
    // ── Pass 1: matte onto paper ─────────────────────────────────────────
    final base = img.Image(
      width: source.width,
      height: source.height,
      numChannels: 3,
    );
    img.fill(base, color: paper);
    img.compositeImage(base, frame);

    // ── Pass 2: remove the dark fringe along the background boundary ────
    // Read from an untouched copy so fixes don't cascade into each other.
    final ref = img.Image.from(base);
    for (var y = 0; y < base.height; y++) {
      for (var x = 0; x < base.width; x++) {
        final p = ref.getPixel(x, y);
        if (_lum(p.r, p.g, p.b) >= 185 || _isPaper(p.r, p.g, p.b)) continue;

        // Only treat dark pixels that touch the paper background — interior
        // darks (the fish's eye) are legitimate artwork.
        var touchesPaper = false;
        var paperCount = 0;
        num sumR = 0, sumG = 0, sumB = 0;
        var lightCount = 0;
        for (var dy = -2; dy <= 2 && true; dy++) {
          for (var dx = -2; dx <= 2; dx++) {
            final nx = x + dx, ny = y + dy;
            if (nx < 0 || ny < 0 || nx >= base.width || ny >= base.height) {
              continue;
            }
            final n = ref.getPixel(nx, ny);
            if (_isPaper(n.r, n.g, n.b)) {
              touchesPaper = true;
              paperCount++;
            } else if (_lum(n.r, n.g, n.b) >= 185) {
              sumR += n.r;
              sumG += n.g;
              sumB += n.b;
              lightCount++;
            }
          }
        }
        if (!touchesPaper) continue;

        // Majority vote: mostly-background neighbors → paper; otherwise the
        // average of the light artwork neighbors (the hexagon fill).
        if (lightCount == 0 || paperCount >= lightCount) {
          base.setPixelRgb(x, y, _paperR, _paperG, _paperB);
        } else {
          base.setPixelRgb(x, y, (sumR / lightCount).round(),
              (sumG / lightCount).round(), (sumB / lightCount).round());
        }
      }
    }

    // ── Pass 3: despeckle — lone dots that disagree with all neighbors ──
    final ref2 = img.Image.from(base);
    for (var y = 1; y < base.height - 1; y++) {
      for (var x = 1; x < base.width - 1; x++) {
        final p = ref2.getPixel(x, y);
        var outliers = 0;
        num sumR = 0, sumG = 0, sumB = 0;
        for (var dy = -1; dy <= 1; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (dx == 0 && dy == 0) continue;
            final n = ref2.getPixel(x + dx, y + dy);
            sumR += n.r;
            sumG += n.g;
            sumB += n.b;
            final delta = (n.r - p.r).abs() + (n.g - p.g).abs() + (n.b - p.b).abs();
            if (delta > 90) outliers++;
          }
        }
        if (outliers >= 7) {
          base.setPixelRgb(x, y, (sumR / 8).round(), (sumG / 8).round(),
              (sumB / 8).round());
        }
      }
    }

    base.frameDuration = frame.frameDuration;
    if (result == null) {
      result = base;
    } else {
      result.addFrame(base);
    }
  }

  File(path).writeAsBytesSync(img.encodeGif(result!));
  stdout.writeln(
      'Wrote $path — ${result.numFrames} frames, fringe removed, on paper');
}
