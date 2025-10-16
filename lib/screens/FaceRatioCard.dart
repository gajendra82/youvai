import 'package:flutter/material.dart';
import 'package:skin_assessment/models/FaceRatioLine.dart';
import 'package:skin_assessment/widgets/FaceRatioPainter.dart';

class FaceRatioPrettyCard extends StatefulWidget {
  final FaceRatioData data;
  final ValueChanged<RatioMode>? onModeChanged; // callback to parent

  const FaceRatioPrettyCard({
    Key? key,
    required this.data,
    this.onModeChanged,
  }) : super(key: key);

  @override
  State<FaceRatioPrettyCard> createState() => _FaceRatioPrettyCardState();
}

class _FaceRatioPrettyCardState extends State<FaceRatioPrettyCard> {
  RatioMode _mode = RatioMode.vertical;

  // Centralized setter so EVERY mode change also notifies the parent.
  void _setMode(RatioMode m) {
    if (_mode == m) return;
    setState(() => _mode = m);
    widget.onModeChanged?.call(m);
  }

  bool get _hasVertical => widget.data.verticalLines.isNotEmpty;
  bool get _hasHorizontal => widget.data.horizontalLines.isNotEmpty;
  bool get _hasEyes =>
      widget.data.leftEye != null || widget.data.rightEye != null;
  bool get _hasFace => widget.data.faceBox != null;
  bool get _hasNLC => widget.data.noseLipChinLines.isNotEmpty;
  bool get _hasLips => widget.data.lipLines.isNotEmpty;
  bool get _hasJaw => widget.data.jaw != null;

  @override
  Widget build(BuildContext context) {
    final img = widget.data.imageBytes;

    // If current mode has no data (e.g., after loading a new JSON),
    // auto-fallback to the first available mode and notify the parent.
    if ((_mode == RatioMode.vertical && !_hasVertical) ||
        (_mode == RatioMode.horizontal && !_hasHorizontal) ||
        (_mode == RatioMode.eyes && !_hasEyes) ||
        (_mode == RatioMode.faceBox && !_hasFace) ||
        (_mode == RatioMode.noseLipChin && !_hasNLC) ||
        (_mode == RatioMode.lips && !_hasLips) ||
        (_mode == RatioMode.jaw && !_hasJaw)) {
      final ordered = <MapEntry<RatioMode, bool>>[
        MapEntry(RatioMode.vertical, _hasVertical),
        MapEntry(RatioMode.horizontal, _hasHorizontal),
        MapEntry(RatioMode.eyes, _hasEyes),
        MapEntry(RatioMode.faceBox, _hasFace),
        MapEntry(RatioMode.noseLipChin, _hasNLC),
        MapEntry(RatioMode.lips, _hasLips),
        MapEntry(RatioMode.jaw, _hasJaw),
      ];
      final firstAvail = ordered
          .firstWhere((e) => e.value, orElse: () => MapEntry(_mode, true))
          .key;
      if (firstAvail != _mode) {
        // schedule after build to avoid setState during build
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _setMode(firstAvail));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + SCROLLABLE chips
        Row(
          children: [
            const Icon(Icons.grid_view_rounded,
                size: 18, color: Colors.black54),
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text("Vertical"),
                      selected: _mode == RatioMode.vertical,
                      onSelected: _hasVertical
                          ? (_) => _setMode(RatioMode.vertical)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Horizontal"),
                      selected: _mode == RatioMode.horizontal,
                      onSelected: _hasHorizontal
                          ? (_) => _setMode(RatioMode.horizontal)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Eyes"),
                      selected: _mode == RatioMode.eyes,
                      onSelected:
                          _hasEyes ? (_) => _setMode(RatioMode.eyes) : null,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Face"),
                      selected: _mode == RatioMode.faceBox,
                      onSelected:
                          _hasFace ? (_) => _setMode(RatioMode.faceBox) : null,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Nose-Lip-Chin"),
                      selected: _mode == RatioMode.noseLipChin,
                      onSelected: _hasNLC
                          ? (_) => _setMode(RatioMode.noseLipChin)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Lips"),
                      selected: _mode == RatioMode.lips,
                      onSelected:
                          _hasLips ? (_) => _setMode(RatioMode.lips) : null,
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text("Jaw"),
                      selected: _mode == RatioMode.jaw,
                      onSelected:
                          _hasJaw ? (_) => _setMode(RatioMode.jaw) : null,
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Image + painter — IMPORTANT: keep image and painter in the same pixel space
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: (widget.data.imageW == 0 || widget.data.imageH == 0)
                ? 3 / 4
                : widget.data.imageW / widget.data.imageH,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (img != null)
                  // Keep raw pixel space (contain) so all coordinates line up
                  FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: widget.data.imageW,
                      height: widget.data.imageH,
                      child: Image.memory(img, fit: BoxFit.fill),
                    ),
                  ),
                if (img != null)
                  // Match painter canvas exactly to the same pixel space
                  FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: widget.data.imageW,
                      height: widget.data.imageH,
                      child: CustomPaint(
                        painter: PrettyRatioPainter(widget.data, _mode),
                      ),
                    ),
                  ),
                if (img == null)
                  const Center(
                    child: Text(
                      "No image bytes",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
