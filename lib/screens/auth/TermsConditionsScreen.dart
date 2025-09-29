import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Terms and Conditions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            '''
Terms and Conditions

1. Use of this app is subject to acceptance of these terms.
2. You agree to provide true information.
3. Your data may be shared for service improvement.
4. You must be at least 18 years old to register.
5. For full terms, please visit our website.

By using this app, you agree to these terms.
''',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
