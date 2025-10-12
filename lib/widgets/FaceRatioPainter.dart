// widgets/PrettyRatioPainter.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:skin_assessment/models/FaceRatioLine.dart';

class PrettyRatioPainter extends CustomPainter {
  final FaceRatioData data;
  final RatioMode mode;
  PrettyRatioPainter(this.data, this.mode);

  // ---------- text helpers ----------
  TextPainter _txt(
    String s, {
    double fs = 14,
    FontWeight fw = FontWeight.w700,
    Color c = Colors.white,
  }) {
    final tp = TextPainter(
      text: TextSpan(
          text: s, style: TextStyle(fontSize: fs, fontWeight: fw, color: c)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    );
    tp.layout();
    return tp;
  }

  /// Two-line pill: title (big) + subtitle (small). Stays centered and inside the card.
  void _pill2(
    Canvas canvas,
    Size size, {
    required String title,
    String? subtitle,
  }) {
    final titleTp = _txt(title, fs: 16, fw: FontWeight.w800);
    final subTp = (subtitle != null && subtitle.trim().isNotEmpty)
        ? _txt(subtitle,
            fs: 12.5, fw: FontWeight.w600, c: Colors.white.withOpacity(.92))
        : null;

    const padH = 18.0;
    const padV = 8.0;
    const gap = 3.0;

    final w = math.max(titleTp.width, subTp?.width ?? 0) + padH * 2;
    final h =
        titleTp.height + (subTp == null ? 0 : gap + subTp.height) + padV * 2;

    final cx = size.width / 2;
    final cy = 30.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: w, height: h),
      const Radius.circular(22),
    );

    final bg = Paint()..color = Colors.black.withOpacity(.58);
    canvas.drawRRect(rect, bg);

    final titleTop = cy - h / 2 + padV;
    titleTp.paint(canvas, Offset(cx - titleTp.width / 2, titleTop));

    if (subTp != null) {
      final subTop = titleTop + titleTp.height + gap;
      subTp.paint(canvas, Offset(cx - subTp.width / 2, subTop));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    // scale server (full-image) coordinates -> canvas
    final sx = size.width / (data.imageW == 0 ? size.width : data.imageW);
    final sy = size.height / (data.imageH == 0 ? size.height : data.imageH);

    // veil
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withOpacity(0.06),
    );

    // paints
    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..isAntiAlias = true;
    final edge = Paint()
      ..color = Colors.white.withOpacity(.65)
      ..strokeWidth = 2
      ..isAntiAlias = true;
    final dash = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..isAntiAlias = true;
    final pink = Paint()..color = const Color(0xFFE91E63);

    // ================== VERTICAL ==================
    if (mode == RatioMode.vertical) {
      if (data.verticalLines.isEmpty) return;

      final xs = <double>[];
      double top = double.infinity, bottom = -double.infinity;

      for (int i = 0; i < data.verticalLines.length; i++) {
        final l = data.verticalLines[i];
        final x = l.x1 * sx, y1 = l.y1 * sy, y2 = l.y2 * sy;
        top = y1 < top ? y1 : top;
        bottom = y2 > bottom ? y2 : bottom;
        xs.add(x);
        canvas.drawLine(
          Offset(x, y1),
          Offset(x, y2),
          (i == 0 || i == data.verticalLines.length - 1) ? edge : white,
        );
      }
      xs.sort();

      final vals = (data.verticalPerc.length >= 5)
          ? data.verticalPerc.take(5).toList()
          : const [20.0, 20.0, 20.0, 20.0, 20.0];

      _pill2(
        canvas,
        size,
        title:
            "Your ${vals.map((e) => '${e.toStringAsFixed(0)}%').join(' : ')}",
        subtitle: "Golden ${data.idealVertical}",
      );

      final baseY = (bottom - 14).clamp(0, size.height);
      for (int i = 0; i < 5 && i + 1 < xs.length; i++) {
        final left = xs[i], right = xs[i + 1];

        // dashed ruler
        const d = 8.0, g = 6.0;
        double x = left + 10;
        while (x < right - 10) {
          final x2 = (x + d).clamp(left + 10, right - 10);
          canvas.drawLine(
              Offset(x, baseY.toDouble()), Offset(x2, baseY.toDouble()), dash);
          x += d + g;
        }

        // value bubble
        final cx = (left + right) / 2;
        final t = _txt("${vals[i].toStringAsFixed(0)}%");
        final rr = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, ((baseY + 16).clamp(0, size.height) as double)),
            width: t.width + 16,
            height: t.height + 8,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(rr, pink);
        t.paint(canvas, Offset(cx - t.width / 2, (baseY + 16) - t.height / 2));
      }
      return;
    }

    // ================== HORIZONTAL ==================
    if (mode == RatioMode.horizontal) {
      if (data.horizontalLines.isEmpty) return;

      final ys = data.horizontalLines.map((l) => l.y1 * sy).toList()..sort();
      if (ys.length < 4) return;

      final topY = ys.first;
      final mid1Y = ys[1];
      final mid2Y = ys[2];
      final botY = ys.last;

      // Clamp to face bounds if possible
      double leftBound, rightBound;
      if (data.faceBox != null) {
        leftBound = data.faceBox!.rect.left * sx;
        rightBound = data.faceBox!.rect.right * sx;
      } else if (data.verticalLines.length >= 2) {
        final xs = data.verticalLines.map((l) => l.x1 * sx).toList()..sort();
        leftBound = xs.first;
        rightBound = xs.last;
      } else {
        leftBound = size.width * .18;
        rightBound = size.width * .82;
      }

      final vals = (data.horizontalPerc.length >= 3)
          ? data.horizontalPerc.take(3).toList()
          : const [33.0, 33.0, 33.0];

      _pill2(
        canvas,
        size,
        title:
            "Your ${vals.map((e) => '${e.toStringAsFixed(0)}%').join(' : ')}",
        subtitle: "Golden ${data.idealHorizontal}",
      );

      // horizontal band lines (bounded)
      void hLine(double y, {required bool edgeLine}) {
        canvas.drawLine(
          Offset(leftBound, y),
          Offset(rightBound, y),
          edgeLine ? edge : white,
        );
      }

      hLine(topY, edgeLine: true);
      hLine(mid1Y, edgeLine: false);
      hLine(mid2Y, edgeLine: false);
      hLine(botY, edgeLine: true);

      // right-side vertical dashed ruler between top/bottom
      final guideX = rightBound - 12;
      const dashLen = 8.0, gap = 6.0;
      double y = topY + 2;
      while (y < botY - 2) {
        final y2 = (y + dashLen).clamp(topY + 2, botY - 2);
        canvas.drawLine(Offset(guideX, y), Offset(guideX, y2), dash);
        y += dashLen + gap;
      }
      // arrowheads
      canvas.drawLine(
          Offset(guideX, topY), Offset(guideX - 6, topY + 10), dash);
      canvas.drawLine(
          Offset(guideX, topY), Offset(guideX + 6, topY + 10), dash);
      canvas.drawLine(
          Offset(guideX, botY), Offset(guideX - 6, botY - 10), dash);
      canvas.drawLine(
          Offset(guideX, botY), Offset(guideX + 6, botY - 10), dash);

      // value bubbles per band
      final bands = <(double, double, double)>[
        (topY, mid1Y, vals[0]),
        (mid1Y, mid2Y, vals[1]),
        (mid2Y, botY, vals[2]),
      ];
      for (final (double a, double b, double pct) in bands) {
        final cy = (a + b) / 2;
        final txt = _txt("${pct.toStringAsFixed(0)}%", fs: 12);
        final rr = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(guideX + 24, cy),
            width: txt.width + 16,
            height: txt.height + 8,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(rr, pink);
        txt.paint(
          canvas,
          Offset(rr.outerRect.center.dx - txt.width / 2,
              rr.outerRect.center.dy - txt.height / 2),
        );
      }
      return;
    }

    // ================== EYES ==================
// ================== EYES ==================
    if (mode == RatioMode.eyes) {
      final l = data.leftEye, r = data.rightEye;
      if (l == null && r == null) return;

      final overall =
          l?.measured.isNotEmpty == true ? l!.measured : (r?.measured ?? "");
      // Title pill
      _pill2(
        canvas,
        size,
        title: overall.isNotEmpty ? "Your Ratio $overall" : "Eye Aspect Ratio",
      );

      // dashed helpers + arrowheads
      void dashedH(double x1, double x2, double y,
          {double dash = 7, double gap = 5, required Paint p}) {
        double x = x1;
        while (x < x2) {
          final x2c = (x + dash).clamp(x1, x2);
          canvas.drawLine(Offset(x, y), Offset(x2c.toDouble(), y), p);
          x += dash + gap;
        }
      }

      void dashedV(double x, double y1, double y2,
          {double dash = 7, double gap = 5, required Paint p}) {
        double y = y1;
        while (y < y2) {
          final y2c = (y + dash).clamp(y1, y2);
          canvas.drawLine(Offset(x, y), Offset(x, y2c.toDouble()), p);
          y += dash + gap;
        }
      }

      void arrowUp(Offset tip, Paint p) {
        canvas.drawLine(tip, tip + const Offset(-6, 8), p);
        canvas.drawLine(tip, tip + const Offset(6, 8), p);
      }

      void arrowDown(Offset tip, Paint p) {
        canvas.drawLine(tip, tip + const Offset(-6, -8), p);
        canvas.drawLine(tip, tip + const Offset(6, -8), p);
      }

      void arrowLeft(Offset tip, Paint p) {
        canvas.drawLine(tip, tip + const Offset(8, -6), p);
        canvas.drawLine(tip, tip + const Offset(8, 6), p);
      }

      void arrowRight(Offset tip, Paint p) {
        canvas.drawLine(tip, tip + const Offset(-8, -6), p);
        canvas.drawLine(tip, tip + const Offset(-8, 6), p);
      }

      final dashPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..isAntiAlias = true;

      void drawEye(EyeBox eye, {required bool placeTagOnRight}) {
        // scale rect to canvas
        final rect = Rect.fromLTRB(
          eye.rect.left * sx,
          eye.rect.top * sy,
          eye.rect.right * sx,
          eye.rect.bottom * sy,
        );

        // soft fill + border (rounded)
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
        canvas.drawRRect(
          rrect,
          Paint()..color = Colors.white.withOpacity(.12),
        );
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke,
        );

        // vertical dashed ruler INSIDE the box at the left edge
        final vx = rect.left + 8;
        dashedV(vx, rect.top + 6, rect.bottom - 6, p: dashPaint);
        arrowUp(Offset(vx, rect.top + 6), dashPaint);
        arrowDown(Offset(vx, rect.bottom - 6), dashPaint);

        // horizontal dashed ruler INSIDE the box at mid-height
        final hy = rect.center.dy;
        dashedH(rect.left + 6, rect.right - 6, hy, p: dashPaint);
        arrowLeft(Offset(rect.left + 6, hy), dashPaint);
        arrowRight(Offset(rect.right - 6, hy), dashPaint);

        // tiny pink "1" tag near outer corner (matches reference)
        final tagTxt = _txt("1", fs: 12);
        final tagCenter = placeTagOnRight
            ? rect.topRight + const Offset(12, 0)
            : rect.topLeft + const Offset(-12, 0);
        final tagRR = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: tagCenter,
            width: tagTxt.width + 16,
            height: tagTxt.height + 8,
          ),
          const Radius.circular(12),
        );
        canvas.drawRRect(tagRR, Paint()..color = const Color(0xFFE91E63));
        tagTxt.paint(
          canvas,
          Offset(tagRR.outerRect.center.dx - tagTxt.width / 2,
              tagRR.outerRect.center.dy - tagTxt.height / 2),
        );

        // measured value bubble centered just below the box
        final valTxt = _txt(eye.measured, fs: 13);
        final valRR = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: rect.bottomCenter + const Offset(0, 18),
            width: valTxt.width + 18,
            height: valTxt.height + 10,
          ),
          const Radius.circular(12),
        );
        canvas.drawRRect(valRR, Paint()..color = const Color(0xFFE91E63));
        valTxt.paint(
          canvas,
          Offset(valRR.outerRect.center.dx - valTxt.width / 2,
              valRR.outerRect.center.dy - valTxt.height / 2),
        );
      }

      // Left eye: tag on right side; Right eye: tag on left side (like mock)
      if (l != null) drawEye(l, placeTagOnRight: true);
      if (r != null) drawEye(r, placeTagOnRight: false);

      // Optional: “Golden …” line just under the main pill (kept inside card)
      if ((l?.golden ?? r?.golden ?? "").isNotEmpty) {
        final g = _txt("Golden ${l?.golden ?? r?.golden}",
            fs: 13, fw: FontWeight.w600);
        final y = 26 + 12 + 16; // just below the top pill
        final bg = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, y.toDouble()),
            width: g.width + 22,
            height: g.height + 8,
          ),
          const Radius.circular(12),
        );
        canvas.drawRRect(bg, Paint()..color = Colors.black.withOpacity(.35));
        g.paint(canvas, Offset(size.width / 2 - g.width / 2, y - g.height / 2));
      }
      return;
    }

    // ================== FACE BOX ==================
    if (mode == RatioMode.faceBox) {
      final fb = data.faceBox;
      if (fb == null) return;

      // Scale rect
      final rect = Rect.fromLTRB(
        fb.rect.left * sx,
        fb.rect.top * sy,
        fb.rect.right * sx,
        fb.rect.bottom * sy,
      );

      // Draw box
      final boxR = RRect.fromRectAndRadius(rect, const Radius.circular(12));
      canvas.drawRRect(
          boxR,
          Paint()
            ..color = Colors.white.withOpacity(0.10)
            ..style = PaintingStyle.fill);
      canvas.drawRRect(
          boxR,
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);

      // Pill (two lines)
      _pill2(canvas, size,
          title: "Your ${fb.yours}", subtitle: "Golden ${fb.golden}");

      // Parse "1:1.46"
      double _safe(String s) => double.tryParse(s.trim()) ?? 0.0;
      double wVal = 1.0, hVal = 0.0;
      if (fb.yours.contains(':')) {
        final parts = fb.yours.split(':');
        if (parts.length >= 2) {
          wVal = _safe(parts[0]);
          hVal = _safe(parts[1]);
        }
      }

      // Vertical dashed ruler (inside right)
      double vx = rect.right - 10;
      const dv = 8.0, gv = 6.0;
      double vy = rect.top + 14;
      while (vy < rect.bottom - 14) {
        final v2 = (vy + dv).clamp(rect.top + 14, rect.bottom - 14);
        canvas.drawLine(Offset(vx, vy), Offset(vx, v2), dash);
        vy += dv + gv;
      }
      // arrowheads
      canvas.drawLine(
          Offset(vx - 6, rect.top + 14), Offset(vx, rect.top + 6), dash);
      canvas.drawLine(
          Offset(vx + 6, rect.top + 14), Offset(vx, rect.top + 6), dash);
      canvas.drawLine(
          Offset(vx - 6, rect.bottom - 14), Offset(vx, rect.bottom - 6), dash);
      canvas.drawLine(
          Offset(vx + 6, rect.bottom - 14), Offset(vx, rect.bottom - 6), dash);

      // Vertical value bubble (height value)
      final vTxt = _txt(hVal == 0 ? fb.yours : hVal.toStringAsFixed(3), fs: 14);
      final vRR = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(vx - 36, rect.center.dy),
          width: vTxt.width + 18,
          height: vTxt.height + 10,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(vRR, pink);
      vTxt.paint(
        canvas,
        Offset(vRR.outerRect.center.dx - vTxt.width / 2,
            vRR.outerRect.center.dy - vTxt.height / 2),
      );

      // Bottom dashed ruler (width = "1")
      final by = rect.bottom - 10;
      const dh = 8.0, gh = 6.0;
      double x = rect.left + 14;
      while (x < rect.right - 14) {
        final x2 = (x + dh).clamp(rect.left + 14, rect.right - 14);
        canvas.drawLine(Offset(x, by), Offset(x2, by), dash);
        x += dh + gh;
      }
      // arrowheads
      canvas.drawLine(
          Offset(rect.left + 14, by - 6), Offset(rect.left + 6, by), dash);
      canvas.drawLine(
          Offset(rect.left + 14, by + 6), Offset(rect.left + 6, by), dash);
      canvas.drawLine(
          Offset(rect.right - 14, by - 6), Offset(rect.right - 6, by), dash);
      canvas.drawLine(
          Offset(rect.right - 14, by + 6), Offset(rect.right - 6, by), dash);

      // "1" bubble
      final hTxt = _txt(wVal.toStringAsFixed(0), fs: 14);
      final hRR = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.center.dx, by + 22),
          width: hTxt.width + 16,
          height: hTxt.height + 10,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(hRR, pink);
      hTxt.paint(
        canvas,
        Offset(hRR.outerRect.center.dx - hTxt.width / 2,
            hRR.outerRect.center.dy - hTxt.height / 2),
      );
      return;
    }

    // ================== NOSE-LIP-CHIN ==================
    if (mode == RatioMode.noseLipChin) {
      if (data.noseLipChinLines.isEmpty) return;

      final ys = data.noseLipChinLines.map((l) => l.y1 * sy).toList()..sort();
      if (ys.length < 3) return;
      final top = ys.first, mid = ys[1], bottom = ys.last;

      // Clamp to face bounds
      double leftBound, rightBound;
      if (data.faceBox != null) {
        leftBound = data.faceBox!.rect.left * sx;
        rightBound = data.faceBox!.rect.right * sx;
      } else if (data.verticalLines.length >= 2) {
        final xs = data.verticalLines.map((l) => l.x1 * sx).toList()..sort();
        leftBound = xs.first;
        rightBound = xs.last;
      } else {
        leftBound = size.width * .18;
        rightBound = size.width * .82;
      }

      _pill2(
        canvas,
        size,
        title: "Your Ratio ${data.noseLipChinRatio ?? ''}",
        subtitle: "Golden ${data.noseLipChinIdeal ?? ''}",
      );

      // subtle fill on top band
      final leftFill = Rect.fromLTRB(
        leftBound,
        top,
        leftBound + (rightBound - leftBound) * 0.55,
        mid,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(leftFill, const Radius.circular(8)),
        Paint()..color = Colors.white.withOpacity(.12),
      );

      // three confined lines
      for (final y in ys) {
        final isEdge = (y == top || y == bottom);
        canvas.drawLine(
          Offset(leftBound, y),
          Offset(rightBound, y),
          isEdge ? edge : white,
        );
      }

      // right dashed ruler (top..bottom)
      final guideX = rightBound - 12;
      const d = 8.0, g = 6.0;
      double y = top + 2;
      while (y < bottom - 2) {
        final y2 = (y + d).clamp(top + 2, bottom - 2);
        canvas.drawLine(Offset(guideX, y), Offset(guideX, y2), dash);
        y += d + g;
      }
      // arrowheads
      canvas.drawLine(Offset(guideX, top), Offset(guideX - 6, top + 10), dash);
      canvas.drawLine(Offset(guideX, top), Offset(guideX + 6, top + 10), dash);
      canvas.drawLine(
          Offset(guideX, bottom), Offset(guideX - 6, bottom - 10), dash);
      canvas.drawLine(
          Offset(guideX, bottom), Offset(guideX + 6, bottom - 10), dash);

      // tag "1" near top of ruler
      final tag = _txt("1", fs: 11);
      final tagRR = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(guideX + 18, top + (mid - top) * 0.15),
          width: tag.width + 16,
          height: tag.height + 8,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(tagRR, pink);
      tag.paint(
        canvas,
        Offset(tagRR.outerRect.center.dx - tag.width / 2,
            tagRR.outerRect.center.dy - tag.height / 2),
      );

      // ratio bubble centered in lower band
      String valueOnly = (data.noseLipChinRatio ?? '')
          .replaceFirst(RegExp(r'^\s*1\s*:\s*'), '');
      if (valueOnly.isEmpty) valueOnly = (data.noseLipChinRatio ?? '');
      final t = _txt(valueOnly, fs: 12);
      final rr = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(guideX + 10, (mid + bottom) / 2),
          width: t.width + 16,
          height: t.height + 8,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(rr, pink);
      t.paint(
        canvas,
        Offset(rr.outerRect.center.dx - t.width / 2,
            rr.outerRect.center.dy - t.height / 2),
      );
      return;
    }

    // ================== LIPS ==================
    if (mode == RatioMode.lips) {
      if (data.lipLines.isEmpty) return;

      final lips = [...data.lipLines]..sort((a, b) => a.y1.compareTo(b.y1));

      // draw the three segments with each own x-span
      for (int i = 0; i < lips.length; i++) {
        final l = lips[i];
        final y = l.y1 * sy;
        final x1 = l.x1 * sx;
        final x2 = l.x2 * sx;

        final p = Paint()
          ..color = (i == 1) ? Colors.white : Colors.white.withOpacity(.85)
          ..strokeWidth = 2
          ..isAntiAlias = true;

        canvas.drawLine(Offset(x1, y), Offset(x2, y), p);
      }

      if (lips.length >= 3) {
        final top = lips.first;
        final middle = lips[1];
        final bottom = lips.last;

        // slim vertical ruler near shortest right edge
        final rightMost = [
          top.x2 * sx,
          middle.x2 * sx,
          bottom.x2 * sx,
        ].reduce((a, b) => a < b ? a : b);
        final rulerX = rightMost - 8;

        final yTop = top.y1 * sy + 6;
        final yBot = bottom.y1 * sy - 6;

        final slimDash = Paint()
          ..color = Colors.white
          ..strokeWidth = 1.6
          ..isAntiAlias = true;

        double y = yTop;
        const d = 6.0, g = 4.0;
        while (y < yBot) {
          final y2 = (y + d).clamp(yTop, yBot);
          canvas.drawLine(
              Offset(rulerX, y), Offset(rulerX, y2.toDouble()), slimDash);
          y += d + g;
        }
        // tiny arrows
        canvas.drawLine(
            Offset(rulerX, yTop), Offset(rulerX - 5, yTop + 6), slimDash);
        canvas.drawLine(
            Offset(rulerX, yTop), Offset(rulerX + 5, yTop + 6), slimDash);
        canvas.drawLine(
            Offset(rulerX, yBot), Offset(rulerX - 5, yBot - 6), slimDash);
        canvas.drawLine(
            Offset(rulerX, yBot), Offset(rulerX + 5, yBot - 6), slimDash);

        // "1" bubble at middle line
        final oneTxt = _txt("1", fs: 12);
        final oneRR = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              (lips[0].x1 * sx + lips[0].x2 * sx) / 2,
              middle.y1 * sy - 12,
            ),
            width: oneTxt.width + 14,
            height: oneTxt.height + 8,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(oneRR, pink);
        oneTxt.paint(
          canvas,
          Offset(oneRR.outerRect.center.dx - oneTxt.width / 2,
              oneRR.outerRect.center.dy - oneTxt.height / 2),
        );

        // ratio bubble next to ruler
        final ratioTxt = _txt(data.lipRatio ?? "", fs: 12);
        final ratioRR = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(rulerX + 34, (yTop + yBot) / 2),
            width: ratioTxt.width + 16,
            height: ratioTxt.height + 8,
          ),
          const Radius.circular(10),
        );
        canvas.drawRRect(ratioRR, pink);
        ratioTxt.paint(
          canvas,
          Offset(ratioRR.outerRect.center.dx - ratioTxt.width / 2,
              ratioRR.outerRect.center.dy - ratioTxt.height / 2),
        );
      }

      _pill2(
        canvas,
        size,
        title: "Your ${data.lipRatio ?? ''}",
        subtitle: "Golden ${data.lipIdeal ?? ''}",
      );
      return;
    }

    // ================== JAW ==================
    if (mode == RatioMode.jaw) {
      final j = data.jaw;
      if (j == null) return;

      Offset sc(Offset o) => Offset(o.dx * sx, o.dy * sy);

      final a = sc(j.leftJaw);
      final b = sc(j.rightJaw);
      final c = sc(j.chin);
      final dPt = sc(j.noseBottom);

      final dashPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..isAntiAlias = true;

      final stroke = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;

      // lower face frame
      final frame = Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, c.dy - 18, a.dx, a.dy);
      canvas.drawPath(
          frame,
          Paint()
            ..color = Colors.white.withOpacity(0.08)
            ..style = PaintingStyle.fill);
      canvas.drawPath(frame, stroke);

      // dots
      void dot(Offset p) =>
          canvas.drawCircle(p, 3, Paint()..color = Colors.white);
      dot(a);
      dot(b);
      dot(c);
      dot(dPt);

      // dashed helpers
      void dashedH(double x1, double x2, double y,
          {double dash = 8, double gap = 6}) {
        double x = x1;
        while (x < x2) {
          final x2c = (x + dash).clamp(x1, x2);
          canvas.drawLine(Offset(x, y), Offset(x2c.toDouble(), y), dashPaint);
          x += dash + gap;
        }
      }

      void dashedV(double x, double y1, double y2,
          {double dash = 8, double gap = 6}) {
        double y = y1;
        while (y < y2) {
          final y2c = (y + dash).clamp(y1, y2);
          canvas.drawLine(Offset(x, y), Offset(x, y2c.toDouble()), dashPaint);
          y += dash + gap;
        }
      }

      // arrows
      void arrowHLeft(Offset p) {
        canvas.drawLine(p, p + const Offset(8, -6), dashPaint);
        canvas.drawLine(p, p + const Offset(8, 6), dashPaint);
      }

      void arrowHRight(Offset p) {
        canvas.drawLine(p, p + const Offset(-8, -6), dashPaint);
        canvas.drawLine(p, p + const Offset(-8, 6), dashPaint);
      }

      void arrowUp(Offset p) {
        canvas.drawLine(p, p + const Offset(-6, 8), dashPaint);
        canvas.drawLine(p, p + const Offset(6, 8), dashPaint);
      }

      void arrowDown(Offset p) {
        canvas.drawLine(p, p + const Offset(-6, -8), dashPaint);
        canvas.drawLine(p, p + const Offset(6, -8), dashPaint);
      }

      // jaw width ruler
      final yJaw = (a.dy + b.dy) / 2 - 10;
      dashedH(a.dx + 8, b.dx - 8, yJaw);
      arrowHLeft(Offset(a.dx + 8, yJaw));
      arrowHRight(Offset(b.dx - 8, yJaw));

      // height ruler (noseBottom -> chin)
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      final xMid = mid.dx;
      final yTop = dPt.dy + 8;
      final yBot = c.dy - 8;
      dashedV(xMid, yTop, yBot);
      arrowUp(Offset(xMid, yTop));
      arrowDown(Offset(xMid, yBot));

      _pill2(
        canvas,
        size,
        title: "Your ${j.ratio.toStringAsFixed(3)}",
        subtitle: "Golden ${j.ideal.toStringAsFixed(3)}",
      );

      // pink bubbles: width→"1", height→ratio
      final wTxt = _txt("1", fs: 14);
      final wRR = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset((a.dx + b.dx) / 2, yJaw - 16),
          width: wTxt.width + 16,
          height: wTxt.height + 10,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(wRR, pink);
      wTxt.paint(
        canvas,
        Offset(wRR.outerRect.center.dx - wTxt.width / 2,
            wRR.outerRect.center.dy - wTxt.height / 2),
      );

      final hTxt = _txt(j.ratio.toStringAsFixed(3), fs: 14);
      final hRR = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(xMid + 40, (yTop + yBot) / 2),
          width: hTxt.width + 18,
          height: hTxt.height + 10,
        ),
        const Radius.circular(12),
      );
      canvas.drawRRect(hRR, pink);
      hTxt.paint(
        canvas,
        Offset(hRR.outerRect.center.dx - hTxt.width / 2,
            hRR.outerRect.center.dy - hTxt.height / 2),
      );
      return;
    }
  }

  @override
  bool shouldRepaint(covariant PrettyRatioPainter old) =>
      old.data != data || old.mode != mode;
}
