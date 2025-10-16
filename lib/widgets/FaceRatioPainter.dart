import 'package:flutter/material.dart';
import 'package:skin_assessment/models/FaceRatioLine.dart';

class PrettyRatioPainter extends CustomPainter {
  final FaceRatioData data;
  final RatioMode mode;
  PrettyRatioPainter(this.data, this.mode);

  // ===== Brand palette (approx. from logo) =====
  static const _rose = Color(0xFFE07B82); // primary
  static const _roseDeep = Color(0xFFD56A73);
  static const _mauve = Color(0xFFB15E66);
  static const _plum = Color(0xFF8A4750); // dark stroke
  static const _maroon = Color(0xFF6E3A40); // darkest accents
  static const _veil = Color(0x0F000000); // 6% black
  static const _pillBg = Color(0xCC1E1E1E); // pill back (80% dark)

  // ===== Brand paints (thin, rounded) =====
  Paint get _edge => Paint()
    ..color = _plum.withOpacity(.95)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  Paint get _line => Paint()
    ..color = _roseDeep
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  Paint get _dash => Paint()
    ..color = _mauve
    ..strokeWidth = 1.4
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  Paint get _softFill => Paint()
    ..color = _rose.withOpacity(.10)
    ..style = PaintingStyle.fill;

  Paint _bubblePaint(RRect r) => Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [_rose, _mauve],
    ).createShader(r.outerRect);

  // ---- tiny helpers ----
  TextPainter _tp(String s,
      {double fs = 13,
      FontWeight fw = FontWeight.w700,
      Color c = Colors.white}) {
    final t = TextPainter(
      text: TextSpan(
          text: s, style: TextStyle(fontSize: fs, fontWeight: fw, color: c)),
      textDirection: TextDirection.ltr,
    );
    t.layout();
    return t;
  }

  void _pill(Canvas canvas, Size size, {required String your, String? golden}) {
    final title = _tp(your, fs: 16, fw: FontWeight.w800);
    final sub = golden != null && golden.trim().isNotEmpty
        ? _tp(golden, fs: 13, fw: FontWeight.w700, c: Colors.white70)
        : null;

    final w = sub == null
        ? (title.width + 34)
        : (title.width > (sub.width) ? title.width : sub.width) + 34;
    final h =
        sub == null ? (title.height + 14) : (title.height + sub.height + 20);

    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(size.width / 2, 30), width: w, height: h),
      const Radius.circular(22),
    );
    canvas.drawRRect(r, Paint()..color = _pillBg);

    final topLeft = Offset(size.width / 2 - title.width / 2, 30 - (h / 2) + 10);
    title.paint(canvas, topLeft);

    if (sub != null) {
      final subTop =
          topLeft + Offset((title.width - sub.width) / 2, title.height + 2);
      sub.paint(canvas, subTop);
    }
  }

  // dashed line helpers
  void _dashedH(Canvas c, double x1, double x2, double y,
      {double dash = 7, double gap = 5}) {
    double x = x1;
    while (x < x2) {
      final x2c = (x + dash).clamp(x1, x2);
      c.drawLine(Offset(x, y), Offset(x2c.toDouble(), y), _dash);
      x += dash + gap;
    }
  }

  void _dashedV(Canvas c, double x, double y1, double y2,
      {double dash = 7, double gap = 5}) {
    double y = y1;
    while (y < y2) {
      final y2c = (y + dash).clamp(y1, y2);
      c.drawLine(Offset(x, y), Offset(x, y2c.toDouble()), _dash);
      y += dash + gap;
    }
  }

  void _arrowUp(Canvas c, Offset p) {
    c.drawLine(p, p + const Offset(-5, 7), _dash);
    c.drawLine(p, p + const Offset(5, 7), _dash);
  }

  void _arrowDown(Canvas c, Offset p) {
    c.drawLine(p, p + const Offset(-5, -7), _dash);
    c.drawLine(p, p + const Offset(5, -7), _dash);
  }

  void _arrowLeft(Canvas c, Offset p) {
    c.drawLine(p, p + const Offset(7, -5), _dash);
    c.drawLine(p, p + const Offset(7, 5), _dash);
  }

  void _arrowRight(Canvas c, Offset p) {
    c.drawLine(p, p + const Offset(-7, -5), _dash);
    c.drawLine(p, p + const Offset(-7, 5), _dash);
  }

  RRect _bubbleAt(Offset center, TextPainter txt) => RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: center, width: txt.width + 16, height: txt.height + 9),
        const Radius.circular(12),
      );

  @override
  void paint(Canvas canvas, Size size) {
    // veil
    canvas.drawRect(Offset.zero & size, Paint()..color = _veil);

    // scale (full-image coordinates)
    final sx = size.width / (data.imageW == 0 ? size.width : data.imageW);
    final sy = size.height / (data.imageH == 0 ? size.height : data.imageH);

    // ================= VERTICAL =================
    if (mode == RatioMode.vertical) {
      if (data.verticalLines.isEmpty) return;

      final xs = <double>[];
      double top = 1e9, bot = -1e9;
      for (int i = 0; i < data.verticalLines.length; i++) {
        final l = data.verticalLines[i];
        final x = l.x1 * sx, y1 = l.y1 * sy, y2 = l.y2 * sy;
        xs.add(x);
        top = y1 < top ? y1 : top;
        bot = y2 > bot ? y2 : bot;
        canvas.drawLine(Offset(x, y1), Offset(x, y2),
            (i == 0 || i == data.verticalLines.length - 1) ? _edge : _line);
      }
      xs.sort();

      final vals = (data.verticalPerc.length >= 5)
          ? data.verticalPerc.take(5).toList()
          : const [20, 20, 20, 20, 20];
      _pill(canvas, size,
          your:
              "Your ${vals.map((e) => '${e.toStringAsFixed(0)}%').join(' : ')}",
          golden: "Golden ${data.idealVertical}");

      final baseY = (bot - 12).clamp(0, size.height).toDouble();
      for (int i = 0; i < 5 && i + 1 < xs.length; i++) {
        final left = xs[i], right = xs[i + 1];
        _dashedH(canvas, left + 8, right - 8, baseY);
        _arrowLeft(canvas, Offset(left + 8, baseY));
        _arrowRight(canvas, Offset(right - 8, baseY));

        final txt = _tp("${vals[i].toStringAsFixed(0)}%", fs: 12);
        final rr = _bubbleAt(Offset((left + right) / 2, baseY + 16), txt);
        canvas.drawRRect(rr, _bubblePaint(rr));
        txt.paint(
            canvas,
            Offset(rr.outerRect.center.dx - txt.width / 2,
                rr.outerRect.center.dy - txt.height / 2));
      }
      return;
    }

    // ================= HORIZONTAL =================
    if (mode == RatioMode.horizontal) {
      if (data.horizontalLines.isEmpty) return;

      final ys = data.horizontalLines.map((l) => l.y1 * sy).toList()..sort();
      if (ys.length < 4) return;
      final topY = ys.first, mid1Y = ys[1], mid2Y = ys[2], botY = ys.last;

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
          : const [33, 33, 33];
      _pill(canvas, size,
          your:
              "Your Ratio ${vals.map((e) => '${e.toStringAsFixed(0)}%').join(' : ')}",
          golden: "Golden ${data.idealHorizontal}");

      void h(double y, bool edge) {
        canvas.drawLine(
            Offset(leftBound, y), Offset(rightBound, y), edge ? _edge : _line);
      }

      h(topY, true);
      h(mid1Y, false);
      h(mid2Y, false);
      h(botY, true);

      final guideX = rightBound - 12;
      _dashedV(canvas, guideX, topY + 2, botY - 2);
      _arrowUp(canvas, Offset(guideX, topY + 2));
      _arrowDown(canvas, Offset(guideX, botY - 2));

      final bands = <(double, double, num)>[
        (topY, mid1Y, vals[0]),
        (mid1Y, mid2Y, vals[1]),
        (mid2Y, botY, vals[2])
      ];
      for (final (a, b, pct) in bands) {
        final cy = (a + b) / 2;
        final txt = _tp("${pct.toStringAsFixed(0)}%", fs: 12);
        final rr = _bubbleAt(Offset(guideX + 24, cy), txt);
        canvas.drawRRect(rr, _bubblePaint(rr));
        txt.paint(
            canvas,
            Offset(rr.outerRect.center.dx - txt.width / 2,
                rr.outerRect.center.dy - txt.height / 2));
      }
      return;
    }

    // ================= EYES =================
    if (mode == RatioMode.eyes) {
      final l = data.leftEye, r = data.rightEye;
      if (l == null && r == null) return;

      final overall =
          l?.measured.isNotEmpty == true ? l!.measured : (r?.measured ?? "");
      _pill(canvas, size,
          your: "Your Ratio $overall",
          golden: "Golden ${l?.golden ?? r?.golden ?? ''}");

      void eye(EyeBox e, String tag) {
        final rect = Rect.fromLTRB(e.rect.left * sx, e.rect.top * sy,
            e.rect.right * sx, e.rect.bottom * sy);
        final rr = RRect.fromRectAndRadius(rect, const Radius.circular(9));
        // soft highlight + thin border
        canvas.drawRRect(rr, _softFill);
        canvas.drawRRect(rr, _line);

        // OUTSIDE dashed rulers (←→) under the box, and (↑↓) at the left side
        final belowY = rr.outerRect.bottom + 10;
        _dashedH(canvas, rr.outerRect.left + 8, rr.outerRect.right - 8, belowY);
        _arrowLeft(canvas, Offset(rr.outerRect.left + 8, belowY));
        _arrowRight(canvas, Offset(rr.outerRect.right - 8, belowY));

        final leftX = rr.outerRect.left - 10;
        _dashedV(canvas, leftX, rr.outerRect.top + 6, rr.outerRect.bottom - 6);
        _arrowUp(canvas, Offset(leftX, rr.outerRect.top + 6));
        _arrowDown(canvas, Offset(leftX, rr.outerRect.bottom - 6));

        // corner tag bubble (small)
        final tagTxt = _tp(tag, fs: 11);
        final tagRR =
            _bubbleAt(rr.outerRect.topLeft + const Offset(-16, -16), tagTxt);
        canvas.drawRRect(tagRR, _bubblePaint(tagRR));
        tagTxt.paint(
            canvas,
            Offset(tagRR.outerRect.center.dx - tagTxt.width / 2,
                tagRR.outerRect.center.dy - tagTxt.height / 2));

        // measured bubble centered below
        final mTxt = _tp(e.measured, fs: 13);
        final mRR =
            _bubbleAt(Offset(rr.outerRect.center.dx, belowY + 18), mTxt);
        canvas.drawRRect(mRR, _bubblePaint(mRR));
        mTxt.paint(
            canvas,
            Offset(mRR.outerRect.center.dx - mTxt.width / 2,
                mRR.outerRect.center.dy - mTxt.height / 2));
      }

      if (l != null) eye(l, "1");
      if (r != null) eye(r, "1");
      return;
    }

    // ================= FACE BOX =================
    if (mode == RatioMode.faceBox) {
      final fb = data.faceBox;
      if (fb == null) return;

      final rect = Rect.fromLTRB(fb.rect.left * sx, fb.rect.top * sy,
          fb.rect.right * sx, fb.rect.bottom * sy);
      final rr = RRect.fromRectAndRadius(rect, const Radius.circular(14));
      canvas.drawRRect(rr, _softFill);
      canvas.drawRRect(rr, _edge);

      double wVal = 1.0, hVal = 0.0;
      if (fb.yours.contains(':')) {
        final p = fb.yours.split(':');
        if (p.length >= 2) {
          wVal = double.tryParse(p[0].trim()) ?? 1.0;
          hVal = double.tryParse(p[1].trim()) ?? 0.0;
        }
      }

      _pill(canvas, size,
          your: "Your Ratio ${fb.yours}", golden: "Golden ${fb.golden}");

      // vertical ruler inside right edge
      final vx = rect.right - 10;
      _dashedV(canvas, vx, rect.top + 14, rect.bottom - 14);
      _arrowUp(canvas, Offset(vx, rect.top + 14));
      _arrowDown(canvas, Offset(vx, rect.bottom - 14));

      final vTxt = _tp(hVal == 0 ? fb.yours : hVal.toStringAsFixed(3), fs: 13);
      final vRR = _bubbleAt(Offset(vx - 34, rect.center.dy), vTxt);
      canvas.drawRRect(vRR, _bubblePaint(vRR));
      vTxt.paint(
          canvas,
          Offset(vRR.outerRect.center.dx - vTxt.width / 2,
              vRR.outerRect.center.dy - vTxt.height / 2));

      // bottom ruler
      final by = rect.bottom - 10;
      _dashedH(canvas, rect.left + 14, rect.right - 14, by);
      _arrowLeft(canvas, Offset(rect.left + 14, by));
      _arrowRight(canvas, Offset(rect.right - 14, by));

      final hTxt = _tp(wVal.toStringAsFixed(0), fs: 13);
      final hRR = _bubbleAt(Offset(rect.center.dx, by + 20), hTxt);
      canvas.drawRRect(hRR, _bubblePaint(hRR));
      hTxt.paint(
          canvas,
          Offset(hRR.outerRect.center.dx - hTxt.width / 2,
              hRR.outerRect.center.dy - hTxt.height / 2));
      return;
    }

    // ================= NOSE–LIP–CHIN =================
    if (mode == RatioMode.noseLipChin) {
      if (data.noseLipChinLines.isEmpty) return;

      final ys = data.noseLipChinLines.map((l) => l.y1 * sy).toList()..sort();
      final top = ys.first, mid = ys[1], bot = ys.last;

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

      _pill(canvas, size,
          your: "Your ${data.noseLipChinRatio ?? ''}",
          golden: "Golden ${data.noseLipChinIdeal ?? ''}");

      final leftFill = Rect.fromLTRB(
          leftBound, top, leftBound + (rightBound - leftBound) * .55, mid);
      canvas.drawRRect(
          RRect.fromRectAndRadius(leftFill, const Radius.circular(8)),
          _softFill);

      for (final y in ys) {
        canvas.drawLine(Offset(leftBound, y), Offset(rightBound, y),
            (y == top || y == bot) ? _edge : _line);
      }

      final guideX = rightBound - 12;
      _dashedV(canvas, guideX, top + 2, bot - 2);
      _arrowUp(canvas, Offset(guideX, top + 2));
      _arrowDown(canvas, Offset(guideX, bot - 2));

      final tag = _tp("1", fs: 11);
      final tagRR =
          _bubbleAt(Offset(guideX + 18, top + (mid - top) * .15), tag);
      canvas.drawRRect(tagRR, _bubblePaint(tagRR));
      tag.paint(
          canvas,
          Offset(tagRR.outerRect.center.dx - tag.width / 2,
              tagRR.outerRect.center.dy - tag.height / 2));

      String valueOnly = (data.noseLipChinRatio ?? '')
          .replaceFirst(RegExp(r'^\s*1\s*:\s*'), '');
      if (valueOnly.isEmpty) valueOnly = (data.noseLipChinRatio ?? '');
      final t = _tp(valueOnly, fs: 12);
      final rr = _bubbleAt(Offset(guideX + 12, (mid + bot) / 2), t);
      canvas.drawRRect(rr, _bubblePaint(rr));
      t.paint(
          canvas,
          Offset(rr.outerRect.center.dx - t.width / 2,
              rr.outerRect.center.dy - t.height / 2));
      return;
    }

    // ================= LIPS =================
    if (mode == RatioMode.lips) {
      if (data.lipLines.isEmpty) return;

      final lips = [...data.lipLines]..sort((a, b) => a.y1.compareTo(b.y1));
      for (int i = 0; i < lips.length; i++) {
        final l = lips[i];
        final y = l.y1 * sy, x1 = l.x1 * sx, x2 = l.x2 * sx;
        final p = (i == 1) ? _edge : _line
          ..color = _roseDeep.withOpacity(.9);
        canvas.drawLine(Offset(x1, y), Offset(x2, y), p);
      }

      if (lips.length >= 3) {
        final top = lips.first, mid = lips[1], bot = lips.last;
        final rightMost = [top.x2 * sx, mid.x2 * sx, bot.x2 * sx]
            .reduce((a, b) => a < b ? a : b);
        final rulerX = rightMost - 8;
        final yTop = top.y1 * sy + 6, yBot = bot.y1 * sy - 6;

        _dashedV(canvas, rulerX, yTop, yBot, dash: 6, gap: 4);
        _arrowUp(canvas, Offset(rulerX, yTop));
        _arrowDown(canvas, Offset(rulerX, yBot));

        final one = _tp("1", fs: 12);
        final oneRR = _bubbleAt(
            Offset((top.x1 * sx + top.x2 * sx) / 2, mid.y1 * sy - 12), one);
        canvas.drawRRect(oneRR, _bubblePaint(oneRR));
        one.paint(
            canvas,
            Offset(oneRR.outerRect.center.dx - one.width / 2,
                oneRR.outerRect.center.dy - one.height / 2));

        final ratio = _tp(data.lipRatio ?? "", fs: 12);
        final ratioRR =
            _bubbleAt(Offset(rulerX + 30, (yTop + yBot) / 2), ratio);
        canvas.drawRRect(ratioRR, _bubblePaint(ratioRR));
        ratio.paint(
            canvas,
            Offset(ratioRR.outerRect.center.dx - ratio.width / 2,
                ratioRR.outerRect.center.dy - ratio.height / 2));
      }

      _pill(canvas, size,
          your: "Your ${data.lipRatio ?? ''}",
          golden: "Golden ${data.lipIdeal ?? ''}");
      return;
    }

    // ================= JAW =================
    if (mode == RatioMode.jaw) {
      final j = data.jaw;
      if (j == null) return;
      Offset sc(Offset o) => Offset(o.dx * sx, o.dy * sy);
      final a = sc(j.leftJaw),
          b = sc(j.rightJaw),
          c = sc(j.chin),
          d = sc(j.noseBottom);

      // elegant lower-face curve (soft)
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, c.dy - 14, b.dx, b.dy)
        ..quadraticBezierTo((a.dx + b.dx) / 2, c.dy - 22, a.dx, a.dy);
      canvas.drawPath(path, _softFill);
      canvas.drawPath(path, _line);

      // landmark dots
      void dot(Offset p) => canvas.drawCircle(p, 2.6, Paint()..color = _plum);
      dot(a);
      dot(b);
      dot(c);
      dot(d);

      // jaw width (↔) a bit above jaw line
      final yJaw = (a.dy + b.dy) / 2 - 10;
      _dashedH(canvas, a.dx + 8, b.dx - 8, yJaw);
      _arrowLeft(canvas, Offset(a.dx + 8, yJaw));
      _arrowRight(canvas, Offset(b.dx - 8, yJaw));

      // nose-bottom → chin (↕)
      final xMid = (a.dx + b.dx) / 2, yTop = d.dy + 8, yBot = c.dy - 8;
      _dashedV(canvas, xMid, yTop, yBot);
      _arrowUp(canvas, Offset(xMid, yTop));
      _arrowDown(canvas, Offset(xMid, yBot));

      _pill(canvas, size,
          your: "Your ${j.ratio.toStringAsFixed(3)}",
          golden: "Golden ${j.ideal.toStringAsFixed(3)}");

      // width bubble "1"
      final wTxt = _tp("1", fs: 13);
      final wRR = _bubbleAt(Offset((a.dx + b.dx) / 2, yJaw - 14), wTxt);
      canvas.drawRRect(wRR, _bubblePaint(wRR));
      wTxt.paint(
          canvas,
          Offset(wRR.outerRect.center.dx - wTxt.width / 2,
              wRR.outerRect.center.dy - wTxt.height / 2));

      // height bubble (ratio)
      final hTxt = _tp(j.ratio.toStringAsFixed(3), fs: 13);
      final hRR = _bubbleAt(Offset(xMid + 38, (yTop + yBot) / 2), hTxt);
      canvas.drawRRect(hRR, _bubblePaint(hRR));
      hTxt.paint(
          canvas,
          Offset(hRR.outerRect.center.dx - hTxt.width / 2,
              hRR.outerRect.center.dy - hTxt.height / 2));
      return;
    }
  }

  @override
  bool shouldRepaint(covariant PrettyRatioPainter old) =>
      old.data != data || old.mode != mode;
}
