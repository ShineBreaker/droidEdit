import 'dart:math' as math;
import 'dart:ui';

import '../../core/core.dart';

/// Pinch zoom of the playfield view: a magnification over the fitted size
/// and the osu!pixel point shown at the centre of the area.
class PlayfieldZoom {
  final double factor;
  final Vec2 centre;

  const PlayfieldZoom(this.factor, this.centre);

  static const minFactor = 1.0;
  static const maxFactor = 8.0;

  static const none = PlayfieldZoom(1, Vec2(OsuRules.playfieldWidth / 2, OsuRules.playfieldHeight / 2));

  bool get isZoomed => factor > minFactor + 1e-3;

  /// Clamped: [factor] within [minFactor, maxFactor] (snapping to [none]
  /// near 1) and [centre] inside the playfield, so it can't be panned away.
  factory PlayfieldZoom.clamped(double factor, Vec2 centre) {
    final f = factor.clamp(minFactor, maxFactor);
    if (f < 1.02) return none;
    return PlayfieldZoom(
      f,
      Vec2(centre.x.clamp(0, OsuRules.playfieldWidth), centre.y.clamp(0, OsuRules.playfieldHeight)),
    );
  }
}

/// Maps osu!pixels (512x384 playfield) to widget pixels, letterboxed and
/// centred. The fitted box is the whole 640x480 gameplay screen the
/// playfield sits in (64px left/right, 56px top/bottom in osu!pixels), so
/// notes keep the same on-screen proportion as in the game.
class PlayfieldTransform {
  final double scale;
  final Offset origin;

  const PlayfieldTransform(this.scale, this.origin);

  /// The gameplay screen around the 512x384 playfield in osu!pixels
  /// (640x480, the playfield at offset 64,56): what the game fits to the
  /// display, so an edge circle reaches as far off the playfield as it
  /// does there. [screenLeft]/[screenTop] are the playfield's offset in
  /// that screen.
  static const screenLeft = 64.0, screenTop = 56.0;
  static const screenWidth = 640.0, screenHeight = 480.0;

  /// The fitted transform, magnified by [zoom] around its centre point.
  factory PlayfieldTransform.fit(Size size, [PlayfieldZoom zoom = PlayfieldZoom.none]) {
    const w = screenWidth;
    const h = screenHeight;
    final fitted = math.min(size.width / w, size.height / h);
    final s = (fitted <= 0 ? 1 : fitted) * zoom.factor;
    final ox = size.width / 2 - zoom.centre.x * s;
    final oy = size.height / 2 - zoom.centre.y * s;
    return PlayfieldTransform(s, Offset(ox, oy));
  }

  Offset toScreen(Vec2 p) => Offset(origin.dx + p.x * scale, origin.dy + p.y * scale);

  Vec2 toOsu(Offset o) => Vec2((o.dx - origin.dx) / scale, (o.dy - origin.dy) / scale);

  /// The zoom that shows osu!pixel [p] at [screen] with magnification
  /// [factor] (clamped, so [p] may end up elsewhere at the limits).
  static PlayfieldZoom zoomKeeping(Size size, Vec2 p, Offset screen, double factor) {
    final base = PlayfieldTransform.fit(size).scale;
    final s = base * factor.clamp(PlayfieldZoom.minFactor, PlayfieldZoom.maxFactor);
    final centre = Vec2(p.x + (size.width / 2 - screen.dx) / s, p.y + (size.height / 2 - screen.dy) / s);
    return PlayfieldZoom.clamped(factor, centre);
  }

  /// Applies this transform to [canvas] so subsequent drawing can use
  /// osu!pixel coordinates directly.
  void apply(Canvas canvas) {
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
  }
}
