import 'package:flutter/material.dart';

class DisclaimerPrivacyScreen extends StatelessWidget {
  const DisclaimerPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      appBar: AppBar(
        title: const Text('Disclaimer & Privacy Policy'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF663635)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.security,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Face & Skin Analysis',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF22223B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Disclaimer & Consent',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Disclaimer Section
            // _buildSection(
            //   context,
            //   'Disclaimer',
            //   Icons.warning_amber_rounded,
            //   [
            //     'The Attractiveness Index and face/skin analysis provided by this application are AI-generated estimates for informational and entertainment purposes only.',
            //     'Results do not represent a medical diagnosis, dermatological assessment, or professional beauty advice.',
            //     'Factors such as lighting, camera quality, and environmental conditions may influence the outcome.',
            //     'Users should not rely solely on this analysis for making decisions regarding skincare, medical treatments, or personal wellbeing.',
            //     'For any medical or cosmetic concerns, please consult a qualified healthcare or skincare professional.',
            //     'The Service Provider makes no guarantees regarding accuracy, completeness, or suitability of the AI analysis.',
            //   ],
            // ),
            
            // const SizedBox(height: 20),
            
            // // Consent Section
            // _buildSection(
            //   context,
            //   'Consent & Data Usage',
            //   Icons.privacy_tip_rounded,
            //   [
            //     'By proceeding with the analysis, you consent to the capture and processing of your image for the purpose of generating your Attractiveness Index.',
            //     'Images may be temporarily stored and processed by our AI engine. With your explicit consent, anonymized images and related data may also be used to improve and train our AI models to enhance accuracy and user experience.',
            //     'You may withdraw consent at any time, after which no further data will be retained or used for training.',
            //     'All images and data are handled in accordance with our Privacy Policy and applicable data protection laws.',
            //   ],
            // ),
            
            const SizedBox(height: 20),
            
        _buildSection(
              context,
              'Disclaimer',
              Icons.warning_amber_rounded,
              [
                'The Attractiveness Index and face/skin analysis provided by this application are AI-generated estimates for informational and entertainment purposes only.',
                'The results do not represent a medical diagnosis, dermatological assessment, or professional beauty advice. For any skin, health, or cosmetic concerns, please consult a qualified medical or skincare professional.',
                'Factors such as lighting, camera quality, and environmental conditions may influence the outcome of the analysis.',
                'By proceeding with the analysis, you consent to the capture and processing of your image for the purpose of generating your Attractiveness Index.',
                'Images may be temporarily stored and processed by our AI engine. With your explicit consent, anonymized images and related data may also be used to improve and train our AI models to enhance accuracy and user experience.',
                'You may withdraw consent at any time, after which no further data will be retained or used for training.',
                'All images and data are handled in accordance with our Privacy Policy and applicable data protection laws.',
                'The Service Provider makes no guarantees regarding accuracy, completeness, or suitability of the AI analysis.',
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Back',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'I Understand',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Text(
                'Last updated: ${DateTime.now().year}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<String> points,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF22223B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...points.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF484848),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
