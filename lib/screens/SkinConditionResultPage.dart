import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_web/razorpay_web.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/widgets/doctor_card.dart';
import 'package:http/http.dart' as http;

class SkinConditionResultPage extends StatefulWidget {
  final Map<String, dynamic> gradioResult;
  final Map<String, dynamic>? patchJson; // <-- Pass the first API JSON here

  SkinConditionResultPage({
    Key? key,
    required this.gradioResult,
    this.patchJson,
  }) : super(key: key);

  @override
  State<SkinConditionResultPage> createState() =>
      _SkinConditionResultPageState();
}

class _SkinConditionResultPageState extends State<SkinConditionResultPage> {
  late Razorpay _razorpay;
  bool _hasPaid = false;
  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay(); // No event wiring for web!
  }

  @override
  void dispose() {
    super.dispose(); // No need to clear for web
    _razorpay.clear();
  }

  void _handlePaymentSuccess(response) async {
    print("Payment successful: $response");
    // Extract IDs if needed, response is Map<String, dynamic>
    final paymentData = {
      "payment_id": response['razorpay_payment_id'] ?? "",
      "amount": 499.00,
      "currency": "INR",
      "status": "completed",
      "payment_method": "razorpay",
      "description": "Unlock Full Report",
      "metadata": {
        "order_id": response['razorpay_order_id'] ?? "",
        "customer_id": "", // Fill if available
      },
      "transaction_reference": response['razorpay_signature'] ?? "",
      "processed_at": DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      print(token);

      final uri = Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/payment/store');
      final res = await http.post(
        uri,
        body: jsonEncode(paymentData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (res.statusCode == 201) {
        print("Payment data stored successfully.");
      } else {
        print("Failed to store payment data: ${res.body}");
      }
    } catch (e) {
      print("Error storing payment data: $e");
    }

    setState(() {
      _hasPaid = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment successful! Details unlocked.")),
    );
  }

  void _handlePaymentError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Payment failed or cancelled. Please try again.")),
    );
  }

  void _startPayment() async {
    var options = {
      'key': 'rzp_test_GD4tLv8EAG4UnR', // TODO: Replace with your Razorpay key!
      'amount': 49900, // amount in paise (499.00 INR)
      'name': 'Skin Analysis',
      'description': 'Unlock Full Report',
      'prefill': {'contact': '', 'email': ''},
      // 'handler': (response) {
      //   print('Payment Success: $response');
      //   // Success logic here
      // }, // Success handler
      // 'modal': {
      //   'ondismiss': () {
      //     print('Payment Modal Closed');
      //     // Error/cancel logic here
      //   }
      // }, // Error/dismiss handler
    };
    _razorpay.on('payment.error', _handlePaymentError);
    _razorpay.on('payment.success', _handlePaymentSuccess);
    // _razorpay.on('external.wallet', );
    _razorpay.open(options);
  }

  List<Map<String, dynamic>> extractSkinSummaries(
      dynamic gradioResult, dynamic patchJson) {
    final List<dynamic> outputs = gradioResult['data']?['outpUt'] ?? [];
    final patchStats = extractPatchStats(patchJson);

    return outputs
        .where((o) => o['analysis'] != null && o['output'] != null)
        .map<Map<String, dynamic>>((result) {
      String analysis = result['analysis'];
      List<Map<String, String>> percentages = [];

      if (analysis.trim().startsWith('[')) {
        try {
          final decoded = json.decode(analysis);
          // print(decoded);
          if (decoded is List) {
            for (var item in decoded) {
              // Each item may be a string with multiple conditions separated by commas or newlines
              final lines = item.toString().split(RegExp(r'[,\n]'));
              for (var line in lines) {
                final match =
                    RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
                if (match != null) {
                  final condition = match.group(1)!.trim();
                  if (condition.toLowerCase().contains('skin redness')) {
                    percentages.add({
                      'condition': "Pigmentation",
                      'percent': match.group(2)!
                    });
                  } else {
                    percentages.add(
                        {'condition': condition, 'percent': match.group(2)!});
                  }
                }
              }
            }
          }
        } catch (e) {
          for (var line in analysis.split('\n')) {
            final match =
                RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
            if (match != null) {
              final condition = match.group(1)!.trim();
              if (!condition.toLowerCase().contains('skin redness')) {
                percentages
                    .add({'condition': condition, 'percent': match.group(2)!});
              }
            }
          }
        }
      } else {
        for (var line in analysis.split('\n')) {
          final match =
              RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
          if (match != null) {
            final condition = match.group(1)!.trim();
            if (!condition.toLowerCase().contains('skin redness')) {
              percentages
                  .add({'condition': condition, 'percent': match.group(2)!});
            }
          }
        }
      }

      String output = result['output'];
      String mainDiagnosis = '';
      final diagnosisRegex = RegExp(
          r'Confirmed Diagnosis[:\s]*([\s\S]*?)(\n\n|$)',
          caseSensitive: false);
      final diagnosisMatch = diagnosisRegex.firstMatch(output);
      if (diagnosisMatch != null) {
        mainDiagnosis = diagnosisMatch.group(1)!.trim();
      } else {
        mainDiagnosis = output.split('\n').first.trim();
      }

      String recommendations = '';
      final recRegex =
          RegExp(r'Recommended Medicines[:\s]*([\s\S]*)', caseSensitive: false);
      final recMatch = recRegex.firstMatch(output);
      if (recMatch != null) {
        recommendations = recMatch.group(1)!.trim();
      } else {
        recommendations = output.trim();
      }

      Map<String, dynamic> assessmentData = getAssessment(percentages);

      double attractivenessScore =
          calculateCombinedAttractivenessScore(percentages, patchStats);

      return {
        'percentages': percentages,
        'mainDiagnosis': mainDiagnosis,
        'recommendations': recommendations,
        'fullOutput': output,
        'assessment': assessmentData['assessment'],
        'scoreOutOf10': assessmentData['scoreOutOf10'],
        'primaryCondition': assessmentData['primaryCondition'],
        'imageUrl': result['image_url'],
        'attractivenessScore': attractivenessScore,
      };
    }).toList();
  }

  /// Extract counts/statistics from the first (patch) JSON
  Map<String, dynamic> extractPatchStats(dynamic patchJson) {
    if (patchJson == null || patchJson['result'] == null) return {};
    final r = patchJson['result'];
    final Map<String, int> patchCounts = {};

    // Example: count for acne, brown_spot etc, using count field or rectangles
    for (final k in [
      'acne',
      'brown_spot',
      'closed_comedones',
      'acne_mark',
      'acne_nodule',
      'acne_pustule',
      'mole',
    ]) {
      if (r[k] != null) {
        if (r[k]['count'] != null) {
          patchCounts[k] = int.tryParse(r[k]['count'].toString()) ?? 0;
        } else if (r[k]['rectangle'] != null &&
            r[k]['rectangle'] is List &&
            r[k]['rectangle'].isNotEmpty) {
          patchCounts[k] = (r[k]['rectangle'] as List).length;
        }
      }
    }
    // Wrinkle counts as sum of all wrinkle_count fields
    if (r['wrinkle_count'] != null && r['wrinkle_count'] is Map) {
      int wrinkleSum = 0;
      r['wrinkle_count']
          .forEach((k, v) => wrinkleSum += int.tryParse(v.toString()) ?? 0);
      patchCounts['wrinkle'] = wrinkleSum;
    }
    // Dark Circle
    if (r['dark_circle'] != null && r['dark_circle']['value'] != null) {
      patchCounts['dark_circle'] =
          int.tryParse(r['dark_circle']['value'].toString()) ?? 0;
    }
    // Eye Pouch
    if (r['eye_pouch'] != null && r['eye_pouch']['value'] != null) {
      patchCounts['eye_pouch'] =
          int.tryParse(r['eye_pouch']['value'].toString()) ?? 0;
    }
    // Add more as needed for your logic.

    return patchCounts;
  }

  // Map condition names to icons and colors
  IconData _getConditionIcon(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('normal')) return Icons.check_circle;
    if (cond.contains('wrinkle')) return Icons.blur_on;
    if (cond.contains('acne')) return Icons.bubble_chart;
    if (cond.contains('blackhead')) return Icons.circle;
    if (cond.contains('dark spot')) return Icons.brightness_3;
    if (cond.contains('pores')) return Icons.grain;
    if (cond.contains('eye bag')) return Icons.remove_red_eye;
    if (cond.contains('brown spot')) return Icons.brightness_2;
    if (cond.contains('mole')) return Icons.adjust;
    if (cond.contains('comedone')) return Icons.bubble_chart;
    if (cond.contains('dark circle')) return Icons.remove_red_eye;
    if (cond.contains('skin redness')) return Icons.warning;
    return Icons.info_outline;
  }

  Color _getConditionColor(String condition) {
    final cond = condition.toLowerCase();
    if (cond.contains('normal')) return Colors.green;
    if (cond.contains('wrinkle')) return Colors.orange;
    if (cond.contains('acne')) return Colors.redAccent;
    if (cond.contains('blackhead')) return Colors.brown;
    if (cond.contains('dark spot')) return Colors.deepPurple;
    if (cond.contains('pores')) return Colors.blueGrey;
    if (cond.contains('eye bag')) return Colors.indigo;
    if (cond.contains('brown spot')) return Colors.deepOrange;
    if (cond.contains('mole')) return Colors.black;
    if (cond.contains('comedone')) return Colors.purple;
    if (cond.contains('dark circle')) return Colors.blue;
    if (cond.contains('skin redness')) return Colors.pinkAccent;
    return Colors.grey;
  }

  int getNormalPercentage(String condition) {
    final cond = condition.toLowerCase();

    if (cond.contains('normal')) return 100;
    if (cond.contains('wrinkle')) return 25;
    if (cond.contains('acne')) return 15;
    if (cond.contains('blackhead')) return 20;
    if (cond.contains('dark spot')) return 15;
    if (cond.contains('pores')) return 25;
    if (cond.contains('eye bag')) return 20;
    if (cond.contains('brown spot')) return 15;
    if (cond.contains('mole'))
      return 30; // Moles aren't usually by %, but this is acceptable
    if (cond.contains('comedone')) return 20;
    if (cond.contains('dark circle')) return 20;
    if (cond.contains('skin redness')) return 20;

    return 30; // Default threshold for unknown or uncategorized conditions
  }

  String _getConditionStatus(String condition, double percent) {
    if (condition.toLowerCase().contains('normal')) {
      return percent >= 70 ? "Normal" : "Not Normal";
    }
    if (percent >= 70) return "High";
    if (percent >= 40) return "Moderate";
    if (percent >= 20) return "Mild";
    return "Minimal";
  }

  final conditionInfo = {
    "normal": {
      "type": "Normal Skin",
      "meaning":
          "Your skin is well-balanced — not too oily or too dry. It feels smooth and has minimal blemishes or sensitivity.",
      "cause":
          "Typically maintained by genetics, a consistent skincare routine, proper hydration, and a healthy lifestyle.",
      "suggestion":
          "Continue your current skincare habits and protect your skin with sunscreen daily.",
      "ageInfo": {
        "typicalAge": "All ages",
        "averageRange": "100%",
        "under": "-",
        "normal": "Perfect skin condition",
        "high": "-",
        "statusThresholds": {"under": 100, "normal": 100}
      },
    },
    "wrinkles": {
      "type": "Wrinkles",
      "meaning":
          "Fine lines or deep creases that appear on the skin as a natural sign of aging. Most commonly seen around eyes, forehead, and mouth.",
      "cause":
          "Aging, repeated facial expressions, sun exposure, dehydration, or lifestyle factors like smoking.",
      "suggestion":
          "Use anti-aging serums, moisturizers with retinol, and always apply sunscreen to prevent further aging.",
      "ageInfo": {
        "typicalAge": "After 30 years, common in 40s–50s",
        "averageRange": "15–30%",
        "under": "Below 15% – Youthful skin, minimal wrinkles",
        "normal": "15–30% – Fine lines, normal for age 30–45",
        "high": "Above 30% – Visible wrinkles, signs of aging",
        "statusThresholds": {"under": 15, "normal": 30}
      },
    },
    "acne": {
      "type": "Acne",
      "meaning":
          "A skin condition that occurs when hair follicles become plugged with oil and dead skin cells, leading to pimples or cysts.",
      "cause":
          "Hormonal imbalance, excess oil (sebum), bacteria, poor hygiene, or stress.",
      "suggestion":
          "Use non-comedogenic skincare, cleanse twice daily, and consider seeing a dermatologist for severe acne.",
      "ageInfo": {
        "typicalAge": "10–30 years",
        "averageRange": "10–25%",
        "under": "Below 10% – Clear skin, minimal acne signs",
        "normal": "10–25% – Mild acne, common in teens & early adults",
        "high": "Above 25% – Moderate to severe acne, consult a dermatologist",
        "statusThresholds": {"under": 10, "normal": 25}
      },
    },
    "blackheads": {
      "type": "Blackheads",
      "meaning":
          "Small, dark bumps that form when pores become clogged with oil and dead skin and remain open.",
      "cause": "Overactive sebaceous glands and poor exfoliation habits.",
      "suggestion":
          "Use salicylic acid or charcoal-based cleansers and exfoliate 2–3 times a week to clear pores.",
      "ageInfo": {
        "typicalAge": "Teenagers to 30s",
        "averageRange": "10–25%",
        "under": "Below 10% – Clean pores, minimal blackheads",
        "normal": "10–25% – Mild blackheads, common for most people",
        "high": "Above 25% – Prominent blackheads, oily skin likely",
        "statusThresholds": {"under": 10, "normal": 25}
      },
    },
    "dark spots": {
      "type": "Dark Spots",
      "meaning":
          "Patches of skin that appear darker due to excess melanin production, commonly on cheeks, forehead, or chin.",
      "cause": "Sun exposure, acne scarring, hormonal changes, or aging.",
      "suggestion":
          "Use products with vitamin C, niacinamide, or alpha arbutin. Apply SPF 30+ daily to prevent darkening.",
      "ageInfo": {
        "typicalAge": "After 25–30 years, especially with sun exposure",
        "averageRange": "10–20%",
        "under": "Below 10% – Even skin tone, minimal pigmentation",
        "normal": "10–20% – Mild pigmentation, often due to sun",
        "high": "Above 20% – Dark spots visible, aging or sun damage",
        "statusThresholds": {"under": 10, "normal": 20}
      },
    },
    "pores": {
      "type": "Enlarged Pores",
      "meaning":
          "Visibly large skin openings, mostly on the nose, cheeks, or forehead, making skin texture uneven.",
      "cause": "Excess sebum, aging, genetics, or sun damage.",
      "suggestion":
          "Use clay masks or products with niacinamide and retinol to tighten pores.",
      "ageInfo": {
        "typicalAge": "Any age, often increases with age or oiliness",
        "averageRange": "15–30%",
        "under": "Below 15% – Tight, smooth skin",
        "normal": "15–30% – Mild pore visibility, normal for most",
        "high": "Above 30% – Enlarged pores, oily or aging skin",
        "statusThresholds": {"under": 15, "normal": 30}
      },
    },
    "eye bags": {
      "type": "Eye Bags",
      "meaning":
          "Swelling or puffiness under the eyes, often accompanied by loose skin or mild discoloration.",
      "cause": "Aging, lack of sleep, water retention, or genetics.",
      "suggestion":
          "Use cold compresses, caffeine-infused eye creams, and ensure adequate sleep and hydration.",
      "ageInfo": {
        "typicalAge": "After 30 years",
        "averageRange": "10–25%",
        "under": "Below 10% – Fresh under-eye area",
        "normal": "10–25% – Mild puffiness, common in 30s–40s",
        "high": "Above 25% – Puffy or sagging eyes, fatigue or aging",
        "statusThresholds": {"under": 10, "normal": 25}
      },
    },
    "dark circle": {
      "type": "Dark Circles",
      "meaning":
          "Dark discoloration under the eyes, making the face look tired or aged.",
      "cause": "Fatigue, aging, thin under-eye skin, genetics, or allergies.",
      "suggestion":
          "Apply brightening eye creams, get enough rest, and use sunscreen around the eyes.",
      "ageInfo": {
        "typicalAge": "After teenage years, worsens with age or stress",
        "averageRange": "10–25%",
        "under": "Below 10% – Bright under-eye area",
        "normal": "10–25% – Slight darkness, common with stress or genetics",
        "high": "Above 25% – Prominent dark circles, fatigue or aging",
        "statusThresholds": {"under": 10, "normal": 25}
      },
    },
    "mole": {
      "type": "Mole",
      "meaning":
          "Small, usually brown or black skin growths formed by clusters of pigmented cells. Can be flat or raised.",
      "cause":
          "Genetics and sun exposure. Most are benign but should be monitored for changes.",
      "suggestion":
          "Check moles regularly for changes in size, shape, or color. Consult a dermatologist for unusual moles.",
      "ageInfo": {
        "typicalAge": "Any age (some are congenital)",
        "averageRange": "10–30%",
        "under": "Below 10% – Few or no moles",
        "normal": "10–30% – Common moles, generally benign",
        "high": "Above 30% – Multiple or large moles, needs observation",
        "statusThresholds": {"under": 10, "normal": 30}
      },
    },
    "brown spot": {
      "type": "Brown Spots",
      "meaning":
          "Flat brown patches often found on sun-exposed areas such as the face, hands, and shoulders.",
      "cause":
          "UV exposure, hormonal fluctuations, or aging (also known as liver spots or sun spots).",
      "suggestion":
          "Apply brightening serums and sunscreen. Consider dermatological treatments like chemical peels if persistent.",
      "ageInfo": {
        "typicalAge": "After 30, mostly due to sun damage",
        "averageRange": "10–20%",
        "under": "Below 10% – Clear skin, minimal sun damage",
        "normal": "10–20% – Mild brown spots, sun exposure",
        "high": "Above 20% – Visible pigmentation, aging skin",
        "statusThresholds": {"under": 10, "normal": 20}
      },
    },
    "comedone": {
      "type": "Comedones",
      "meaning":
          "Blocked hair follicles; open comedones are blackheads, and closed ones are whiteheads.",
      "cause":
          "Accumulation of oil and dead skin cells, especially on oily skin types.",
      "suggestion":
          "Use exfoliating cleansers with BHA (salicylic acid) to prevent pore blockages.",
      "ageInfo": {
        "typicalAge": "Teens to 30s",
        "averageRange": "10–25%",
        "under": "Below 10% – Clear skin",
        "normal": "10–25% – Mild clogged pores, common for oily skin",
        "high": "Above 25% – Frequent clogged pores, acne risk",
        "statusThresholds": {"under": 10, "normal": 25}
      },
    },
    "skin redness": {
      "type": "Skin Redness",
      "meaning":
          "Inflammation or irritation leading to visibly red or blotchy skin, sometimes with burning or itching.",
      "cause":
          "Allergies, rosacea, harsh products, sunburn, or skin sensitivity.",
      "suggestion":
          "Use calming skincare products with aloe vera or chamomile and avoid known irritants.",
      "ageInfo": {
        "typicalAge": "Any age, more in sensitive or dry skin types",
        "averageRange": "10–25%",
        "under": "Below 10% – Even skin tone",
        "normal": "10–25% – Mild redness, common for dry or sensitive skin",
        "high": "Above 25% – Flushed appearance, irritation or skin issues",
        "statusThresholds": {"under": 10, "normal": 25}
      },
    },
    "eye pouch": {
      "type": "Under-Eye Puffiness",
      "meaning":
          "Slight bulging or loose skin under the eyes, often associated with tiredness or age.",
      "cause":
          "Loss of skin elasticity, fluid retention, or hereditary factors.",
      "suggestion":
          "Try gentle massage, cooling eye gels, and reduce salt intake.",
      "ageInfo": {
        "average": "15–30%",
        "under": "Youthful, tight under-eye skin. Common in 20s.",
        "normal": "Mild puffiness, normal in 30s–40s.",
        "high": "Noticeable sagging or puffiness, often 40+."
      }
    },
    "nasolabial fold": {
      "type": "Nasolabial Folds",
      "meaning":
          "Deep lines running from the sides of the nose to the corners of the mouth, visible more with age.",
      "cause": "Loss of collagen and fat in the face due to aging.",
      "suggestion":
          "Use firming creams, facial exercises, or consult for fillers if the lines are deep.",
      "ageInfo": {
        "average": "15–30%",
        "under": "Soft or invisible folds. Common in people under 25.",
        "normal": "Shallow lines, visible in 30s–40s.",
        "high": "Deep folds from nose to mouth. Common after 45."
      }
    },
  };

  Widget _summaryStat(String label, String value, IconData? icon, Color? color,
      BuildContext context,
      {String? status, double? compareTo}) {
    // Parse the value as double for comparison
    double currentValue = double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    String? compareText;
    Color? compareColor;

    if (compareTo != null) {
      if (currentValue > compareTo) {
        compareText = "Higher than average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.redAccent; // High is usually a concern
      } else if (currentValue < compareTo) {
        compareText = "Lower than average (${compareTo.toStringAsFixed(1)}%)";
        // compareColor =
        //     Colors.green; // Lower can mean healthier or under control
        compareColor = Colors.blueGrey;
      } else {
        compareText = "Equal to average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.blueGrey; // Neutral
      }
    }

    return InkWell(
      onTap: () {
        print("clcikc");
        final info = conditionInfo[label.toLowerCase()];
        if (info != null) {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(
                            text: "Meaning: ",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: "${info['meaning']}",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                              text: "Inital Cause: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: "${info['cause']}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          TextSpan(
                              text: "Suggestions: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: "${info['suggestion']}"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (info['ageInfo'] != null && info['ageInfo'] is Map) ...[
                      const SizedBox(height: 8),
                      Text(
                        "Age Information:",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      if ((info['ageInfo'] as Map?)?['typicalAge'] != null)
                        Text(
                            "Typical Age: ${(info['ageInfo'] as Map)['typicalAge']}"),
                      if ((info['ageInfo'] as Map?)?['averageRange'] != null)
                        Text(
                            "Average Range: ${(info['ageInfo'] as Map)['averageRange']}"),
                      if ((info['ageInfo'] as Map?)?['under'] != null)
                        Text("Under: ${(info['ageInfo'] as Map)['under']}"),
                      if ((info['ageInfo'] as Map?)?['normal'] != null)
                        Text("Normal: ${(info['ageInfo'] as Map)['normal']}"),
                      if ((info['ageInfo'] as Map?)?['high'] != null)
                        Text("High: ${(info['ageInfo'] as Map)['high']}"),
                    ],
                  ],
                ),
              );
            },
          );
        }
      },
      child: Container(
        // padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.06),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  (color ?? Theme.of(context).colorScheme.secondary)
                      .withOpacity(0.15),
              child: Icon(icon ?? Icons.info_outline,
                  color: color ?? Theme.of(context).colorScheme.secondary,
                  size: 22),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                        color: compareColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (status != null)
                    Text(
                      status,
                      style: TextStyle(
                          color: color ?? Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  if (compareText != null)
                    Text(
                      compareText,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                          fontSize: 13),
                      maxLines: 1,
                    ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> getAssessment(List<Map<String, String>> percentages) {
    if (percentages.isEmpty) {
      return {
        'assessment': "Insufficient data for assessment.",
        'scoreOutOf10': 0.0,
        'primaryCondition': ""
      };
    }
    Map<String, String>? highest = percentages.reduce((a, b) =>
        double.tryParse(a['percent'] ?? "0")! >
                double.tryParse(b['percent'] ?? "0")!
            ? a
            : b);
    double value = double.tryParse(highest['percent'] ?? "0") ?? 0.0;
    String condition = highest['condition'] ?? "";

    String risk;
    if (value >= 70) {
      risk = "High";
    } else if (value >= 40) {
      risk = "Moderate";
    } else if (value >= 20) {
      risk = "Mild";
    } else {
      risk = "Minimal";
    }
    double score = (value / 10).clamp(0.0, 10.0);
    return {
      'assessment':
          "Primary Concern: $condition ($value%)\nAssessment: $risk risk for this condition.",
      'scoreOutOf10': score,
      'primaryCondition': condition,
    };
  }

  /// Combine both JSONs for more accurate attractiveness score.
  double calculateCombinedAttractivenessScore(
      List<Map<String, String>> percentages, Map<String, dynamic> patchStats) {
    double normal = 0;
    double negative = 0;
    final negativeConditions = [
      "dry",
      "acne",
      "wrinkles",
      "dark spots",
      "blackheads",
      "pores",
      "eye bags",
      "dark circle",
      "mole",
      "brown spot",
      "comedone",
      "eye pouch",
      "nasolabial fold"
    ];
    for (var entry in percentages) {
      final cond = entry['condition']?.toLowerCase() ?? "";
      final val = double.tryParse(entry['percent'] ?? "0") ?? 0;
      if (cond.contains("normal")) {
        normal += val;
      } else if (negativeConditions.any((c) => cond.contains(c))) {
        negative += val;
      }
    }

    // Patch count penalties
    double patchPenalty = 0.0;
    for (final k in patchStats.keys) {
      final v = patchStats[k];
      if (v is int && v > 0) {
        if (['acne', 'brown_spot', 'closed_comedones', 'mole'].contains(k)) {
          patchPenalty += v * 0.18;
        } else if (['wrinkle', 'dark_circle', 'eye_pouch'].contains(k)) {
          patchPenalty += v * 0.12;
        }
      }
    }

    // Score: start from 8, add positive, subtract negative and patch penalty
    double score =
        8.0 + (normal / 100) * 2.0 - (negative / 100) * 2.0 - patchPenalty;
    return score.clamp(6.01, 10.0);
  }

  Widget buildAssessmentChart(double score, {String? label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 80,
          width: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  value: (score / 10).clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    // score >= 8.5
                    //     ? Colors.green
                    //     : score >= 7.5
                    //         ? Colors.lightGreen
                    //         : score >= 6.5
                    //             ? Colors.orange
                    //             : Colors.red,
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              Text(
                "${score.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
              const Positioned(
                bottom: 10,
                child: Text(
                  "/ 10",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 15),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              "$label Assessment Score",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
      ],
    );
  }

  Widget buildAttractivenessChart(double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 2.0),
          child: Text(
            "Attractiveness Score",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 28,
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (score / 10).clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: score >= 8.5
                        ? Colors.green
                        : score >= 7.5
                            ? Colors.lightGreen
                            : score >= 6.5
                                ? Colors.orange
                                : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    "${score.toStringAsFixed(2)} / 10",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildIndividualPercentagesChart(
      List<Map<String, String>> percentages) {
    if (percentages.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Condition Percentages",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...percentages.map((p) {
          final cond = p['condition'];
          final val = double.tryParse(p['percent'] ?? "0") ?? 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(cond!,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ),
                Expanded(
                  flex: 6,
                  child: LinearProgressIndicator(
                    value: (val / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Text('${val.toStringAsFixed(1)}%'),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaries =
        extractSkinSummaries(widget.gradioResult, widget.patchJson);
    print(summaries[0]['percentages']);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skin Analysis Results',
          style: TextStyle(
            fontFamily: 'SansSerif',
          ),
        ),
        // backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: summaries.isEmpty
          ? const Center(child: Text('No skin condition data found.'))
          : Container(
              width: kIsWeb ? 600 : double.infinity,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: summaries.isEmpty ? 0 : 1,
                itemBuilder: (context, i) {
                  final summary = summaries[i];
                  final percentages = summary['percentages'] as List<dynamic>;
                  final imageUrl = summary['imageUrl'] as String?;
                  final mainDiagnosis = summary['mainDiagnosis'] as String;
                  final assessment = summary['assessment'] as String;
                  final scoreOutOf10 = summary['scoreOutOf10'] as double;
                  final attractivenessScore =
                      summary['attractivenessScore'] as double;
                  final primaryCondition =
                      summary['primaryCondition'] as String;
                  final fullOutput = summary['fullOutput'] as String;

                  return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GridView.builder(
                                shrinkWrap: true,
                                // physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2, // Two cards per row
                                  childAspectRatio:
                                      MediaQuery.of(context).size.width < 400
                                          ? 1.3
                                          : 2.4, // More square on mobile
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 14,
                                ),
                                itemCount: percentages.length,
                                itemBuilder: (context, idx) {
                                  final p = percentages[idx];
                                  return _summaryStat(
                                      p['condition'] ?? '',
                                      "${p['percent']}%",
                                      _getConditionIcon(p['condition'] ?? ''),
                                      // _getConditionColor(p['condition'] ?? ''),
                                      Theme.of(context).colorScheme.primary,
                                      context,
                                      compareTo:
                                          getNormalPercentage(p['condition'])
                                              .toDouble());
                                },
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  // Expanded(
                                  //   child: Card(
                                  //     shape: RoundedRectangleBorder(
                                  //         borderRadius:
                                  //             BorderRadius.circular(16)),
                                  //     elevation: 3,
                                  //     child: Container(
                                  //       decoration: BoxDecoration(
                                  //         gradient: LinearGradient(
                                  //           colors: [
                                  //             Theme.of(context)
                                  //                 .colorScheme
                                  //                 .primary,
                                  //             Theme.of(context)
                                  //                 .colorScheme
                                  //                 .secondary,
                                  //             Theme.of(context)
                                  //                 .colorScheme
                                  //                 .secondary,
                                  //             Theme.of(context)
                                  //                 .colorScheme
                                  //                 .secondary,
                                  //           ],
                                  //           begin: Alignment.topLeft,
                                  //           end: Alignment.bottomRight,
                                  //         ),
                                  //         borderRadius:
                                  //             BorderRadius.circular(16),
                                  //       ),
                                  //       padding: const EdgeInsets.symmetric(
                                  //           vertical: 18, horizontal: 8),
                                  //       child: Column(
                                  //         mainAxisSize: MainAxisSize.min,
                                  //         children: [
                                  //           buildAssessmentChart(scoreOutOf10,
                                  //               label: primaryCondition),
                                  //           const SizedBox(height: 8),
                                  //         ],
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                  // const SizedBox(width: 16),
                                  Expanded(
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 3,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              // Theme.of(context)
                                              //     .colorScheme
                                              //     .secondary,
                                              // Theme.of(context)
                                              //     .colorScheme
                                              //     .secondary,
                                              // Theme.of(context)
                                              //     .colorScheme
                                              //     .secondary,
                                              // Theme.of(context)
                                              //     .colorScheme
                                              //     .primary,
                                              // Theme.of(context)
                                              //     .colorScheme
                                              //     .,
                                              Colors.white,
                                              Colors.white,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 18, horizontal: 8),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            buildAssessmentChart(
                                                attractivenessScore,
                                                label: "Attractive"),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // buildAttractivenessChart(attractivenessScore),
                              //     color: Colors.deepPurple),
                              // ),
                              const SizedBox(height: 10),
                              Text("From Recently Uploaded Image",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              const SizedBox(height: 10),
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                SizedBox(
                                  height: 110,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: [
                                      Card(
                                        margin:
                                            const EdgeInsets.only(right: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            imageUrl,
                                            width: 140,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              width: 140,
                                              height: 100,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                  Icons.broken_image,
                                                  size: 40,
                                                  color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Add more cards for other images if available in your data
                                    ],
                                  ),
                                ),
                              const Divider(height: 24),
                              // ExpansionTiles for Q&A style extraction
                              !_hasPaid
                                  ? Center(
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 8,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.lock,
                                                color: Colors.white, size: 40),
                                            const SizedBox(height: 12),
                                            Text(
                                              "Unlock Full Details",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Pay ₹499 to view diagnosis, treatment notes, and recommendations.",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              icon: const Icon(Icons.lock_open),
                                              label: const Text(
                                                  "Unlock Full Details (₹499)"),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.deepPurple,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: _startPayment,
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        ExpansionTile(
                                          title: const Text(
                                              "What's the diagnosis?",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(mainDiagnosis,
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ),
                                          ],
                                        ),
                                        // ExpansionTile(
                                        //   title: const Text("What medicines are recommended?",
                                        //       style: TextStyle(fontWeight: FontWeight.bold)),
                                        //   children: [
                                        //     Padding(
                                        //       padding: const EdgeInsets.all(8.0),
                                        //       child: Builder(
                                        //         builder: (context) {
                                        //           // Try to extract "Recommended Medicines" section
                                        //           final recRegex = RegExp(
                                        //               r'Recommended Medicines[:\s]*([\s\S]*?)(\n\n|$)',
                                        //               caseSensitive: false);
                                        //           final recMatch =
                                        //               recRegex.firstMatch(fullOutput);
                                        //           if (recMatch != null) {
                                        //             return Text(recMatch.group(1)!.trim(),
                                        //                 style: const TextStyle(fontSize: 15));
                                        //           }
                                        //           // Fallback: show all recommendations
                                        //           return Text(summary['recommendations'] ?? '',
                                        //               style: const TextStyle(fontSize: 15));
                                        //         },
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),
                                        ExpansionTile(
                                          title: const Text(
                                              "What are the treatment notes?",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Builder(
                                                builder: (context) {
                                                  // Try to extract "Treatment Notes" or similar section
                                                  final notesRegex = RegExp(
                                                      r'(Treatment Notes|Treatment|Advice|Notes)[:\s]*([\s\S]*?)(\n\n|$)',
                                                      caseSensitive: false);
                                                  final notesMatch = notesRegex
                                                      .firstMatch(fullOutput);
                                                  if (notesMatch != null) {
                                                    return Text(
                                                        notesMatch
                                                            .group(2)!
                                                            .trim(),
                                                        style: const TextStyle(
                                                            fontSize: 15));
                                                  }
                                                  // Fallback: show full output
                                                  return Text(fullOutput,
                                                      style: const TextStyle(
                                                          fontSize: 15));
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        ExpansionTile(
                                          title: const Text("Show full details",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(fullOutput,
                                                  style: const TextStyle(
                                                      fontSize: 15)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 10),
                                  const Text(
                                    "Recommended Doctor's",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 👇 Fixed horizontal ListView inside a SizedBox
                                  SizedBox(
                                    height:
                                        300, // Adjust based on your DoctorCard height
                                    child: ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(right: 16),
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 5,
                                      itemBuilder: (context, index) {
                                        return const DoctorCard(); // Replace with actual data if needed
                                      },
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ));
                },
              ),
            ),
    );
  }
}
