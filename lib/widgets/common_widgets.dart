import 'package:flutter/material.dart';

class CommonWidgets {
  static Widget elevatedButton({
    required String text,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: isLoading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.analytics),
        label: isLoading ? const Text("Loading...") : Text(text),
        onPressed: isLoading ? null : onPressed,
      ),
    );
  }
}
