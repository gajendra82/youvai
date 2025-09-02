import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TermsConditionsPopup extends StatefulWidget {
  final Function(bool accepted) onAccept;

  const TermsConditionsPopup({
    Key? key,
    required this.onAccept,
  }) : super(key: key);

  @override
  State<TermsConditionsPopup> createState() => _TermsConditionsPopupState();
}

class _TermsConditionsPopupState extends State<TermsConditionsPopup> {
  bool _accepted = false;
  bool _isSubmitting = false;

  // Static terms and conditions content
  static const String _staticTermsContent = '''
Terms and Conditions

Welcome to our Skin Analysis Application. By using this application, you agree to the following terms and conditions:

1. **Data Collection and Privacy**
   - We collect and process your facial images for skin analysis purposes
   - Your personal data is protected under our privacy policy
   - We do not share your data with third parties without your consent

2. **Medical Disclaimer**
   - This application provides general skin analysis and recommendations
   - It is not a substitute for professional medical advice
   - Always consult with a dermatologist for serious skin concerns

3. **User Responsibilities**
   - You must provide accurate information
   - You are responsible for maintaining the confidentiality of your account
   - You agree not to misuse the application or its features

4. **Service Availability**
   - We strive to maintain service availability but cannot guarantee uninterrupted access
   - We may update or modify the service at any time

5. **Limitation of Liability**
   - We are not liable for any damages arising from the use of this application
   - Our liability is limited to the amount paid for the service

6. **Acceptance**
   - By accepting these terms, you acknowledge that you have read and understood them
   - You agree to be bound by these terms and conditions

If you have any questions about these terms, please contact our support team.
''';

  Widget _buildFormattedText(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldRegex = RegExp(r'\*\*(.*?)\*\*');
    
    int lastIndex = 0;
    
    for (final Match match in boldRegex.allMatches(text)) {
      // Add text before the bold section
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
        ));
      }
      
      // Add the bold text
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      
      lastIndex = match.end;
    }
    
    // Add any remaining text after the last bold section
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
      ));
    }
    
    return RichText(
      text: TextSpan(
        children: spans,
        style: const TextStyle(
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Terms and Conditions',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: _buildFormattedText(_staticTermsContent),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: _accepted,
                  onChanged: (value) {
                    setState(() {
                      _accepted = value ?? false;
                    });
                  },
                ),
                const Expanded(
                  child: Text(
                    'I have read and agree to the Terms and Conditions',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () async {
            // User must accept terms to proceed
            if (_accepted) {
              setState(() {
                _isSubmitting = true;
              });
              
              try {
                // Call API to update policy acceptance
                await ApiService.updatePolicyAcceptance(true);
                
                // Call the callback
                widget.onAccept(true);
                
                // Close the popup
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              } catch (e) {
                // Show error but don't close popup
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error accepting terms: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() {
                    _isSubmitting = false;
                  });
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please accept the terms and conditions to continue.'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: _isSubmitting 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text(
                'Accept & Continue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
        ),
      ],
    );
  }
}
