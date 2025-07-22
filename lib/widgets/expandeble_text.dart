import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ExpandableRichText extends StatefulWidget {
  final String fullText;
  final int trimLength;

  const ExpandableRichText({
    super.key,
    required this.fullText,
    this.trimLength = 120,
  });

  @override
  State<ExpandableRichText> createState() => _ExpandableRichTextState();
}

class _ExpandableRichTextState extends State<ExpandableRichText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final String visibleText = _isExpanded
        ? widget.fullText
        : widget.fullText.length > widget.trimLength
            ? widget.fullText.substring(0, widget.trimLength) + "..."
            : widget.fullText;

    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87, fontSize: 14),
        children: [
          TextSpan(text: visibleText),
          if (widget.fullText.length > widget.trimLength)
            TextSpan(
              text: _isExpanded ? " Show less" : " Read more",
              style: const TextStyle(color: Color(0xFF8F5FE8)),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
            ),
        ],
      ),
    );
  }
}
