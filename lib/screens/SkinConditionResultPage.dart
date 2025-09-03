import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_web/razorpay_web.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:skin_assessment/widgets/CustomSpiderChart.dart';
import 'package:skin_assessment/widgets/doctor_card.dart';
import 'package:http/http.dart' as http;

class SkinConditionResultPage extends StatefulWidget {
  final Map<String, dynamic> gradioResult;

  SkinConditionResultPage({
    Key? key,
    required this.gradioResult,
  }) : super(key: key);

  @override
  State<SkinConditionResultPage> createState() =>
      _SkinConditionResultPageState();
}

class _SkinConditionResultPageState extends State<SkinConditionResultPage> {
  late Razorpay _razorpay;
  bool _hasPaid = false;
  String paymentStatus = "";

  // Coupon logic
  TextEditingController _couponController = TextEditingController();
  bool _couponApplied = false;
  bool _couponChecking = false;
  String _couponError = "";
  String _appliedCoupon = "";

  @override
  void initState() {
    super.initState();
    checkSubscriptionStatus();
    if (kIsWeb) {
      js.context['flutterPaymentSuccess'] = (String paymentId) {
        setState(() {
          paymentStatus = "Payment Successful: $paymentId";
          _hasPaid = true;
        });
        _handlePaymentSuccess(paymentId);
      };
      js.context['flutterPaymentError'] = (String paymentId) {
        setState(() {
          paymentStatus = "Payment Failed: $paymentId";
        });
        _handlePaymentError(paymentId);
      };
    }
  }

  @override
  void dispose() {
    super.dispose();
    _razorpay.clear();
    _couponController.dispose();
  }

  void checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool('isSubscribe') ?? false;
    setState(() {
      _hasPaid = isSubscribed;
    });
  }

  void _handlePaymentSuccess(String paymentId) async {
    final paymentData = {
      "payment_id": paymentId,
      "amount": 499.00,
      "currency": "INR",
      "status": "completed",
      "payment_method": "razorpay",
      "description": "Unlock Full Report",
      "metadata": {
        "order_id": paymentId ?? "",
        "customer_id": "",
      },
      "transaction_reference": paymentId ?? "",
      "processed_at": DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      prefs.setBool('isSubscribe', true);
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

  void _handlePaymentError(paymentId) async {
    final paymentData = {
      "payment_id": paymentId ?? "",
      "amount": 499.00,
      "currency": "INR",
      "status": "Failed",
      "payment_method": "razorpay",
      "description": "Unlock Full Report",
      "metadata": {
        "order_id": paymentId ?? "",
        "customer_id": "",
      },
      "transaction_reference": paymentId ?? "",
      "processed_at": DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      final uri = Uri.parse(
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/payment/store');
      await http.post(
        uri,
        body: jsonEncode(paymentData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      print("Error storing payment data: $e");
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Payment failed or cancelled. Please try again.")),
    );
  }

  void _startPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLogin') ?? false;
    if (!isLoggedIn) {
      await Navigator.pushNamed(context, AppRoutes.login);
    }
    final isSubscribed = prefs.getBool('isSubscribe') ?? false;
    if (isSubscribed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You already have access to the report.")),
      );
      return;
    }

    // If coupon is applied, skip payment and unlock directly
    if (_couponApplied) {
      // Save subscription
      prefs.setBool('isSubscribe', true);
      setState(() {
        _hasPaid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Coupon applied! Details unlocked.")),
      );
      return;
    }

    var options = {
      'key': 'rzp_test_GD4tLv8EAG4UnR',
      'amount': 49900,
      'name': 'Skin Analysis',
      'description': 'Unlock Full Report',
      'prefill': {'contact': '', 'email': ''},
    };

    String name = '';
    String email = '';
    String number = '';

    final userInfoJson = prefs.getString('userInfo');
    if (userInfoJson != null && userInfoJson.isNotEmpty) {
      final userInfo = json.decode(userInfoJson);
      name = userInfo['name'] ?? '';
      email = userInfo['email'] ?? '';
      number = userInfo['phone'] ?? '';
    } else {
      name = prefs.getString('name') ?? '';
      email = prefs.getString('email') ?? '';
      number = prefs.getString('number') ?? '';
    }

    js.context.callMethod('openRazorpayCheckout', [
      "rzp_live_jBXpBOtKrydrbs",
      "rzp_live_jBXpBOtKrydrbs",
      "49900",
      name,
      email,
      number,
    ]);
  }

  // Coupon validation API call
  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _couponError = "Please enter a coupon code.";
      });
      return;
    }
    setState(() {
      _couponChecking = true;
      _couponError = "";
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      final response = await http.post(
        Uri.parse(
            'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/coupon/verify'),
        body: jsonEncode({"coupon_code": code}),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      //  if (response.statusCode == 200) {
      final body = jsonDecode(response.body);

      // Check message for success (or customize as needed)
      if (body['message'] == "Coupon verified successfully") {
        setState(() {
          _couponApplied = true;
          _appliedCoupon = code;
          _couponError = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Coupon applied! Payment skipped.")),
        );
      } else {
        setState(() {
          _couponError = body['message'] ?? "Invalid coupon.";
          _couponApplied = false;
          _appliedCoupon = "";
        });
      }
      // } else {
      //   setState(() {
      //     _couponError = "Invalid coupon or network error.";
      //     _couponApplied = false;
      //     _appliedCoupon = "";
      //   });
      // }
    } catch (e) {
      setState(() {
        _couponError = "Error validating coupon.";
        _couponApplied = false;
        _appliedCoupon = "";
      });
    } finally {
      setState(() {
        _couponChecking = false;
      });
    }
  }

  List<Map<String, dynamic>> extractSkinSummaries(dynamic gradioResult) {
    try {
      final List<dynamic> outputs = List.from(gradioResult['data']);
      if (outputs.isEmpty) {
        return [];
      }
      return outputs
          .where((o) => o['analysis'] != null)
          .map<Map<String, dynamic>>((result) {
        String analysis = jsonEncode(result['analysis']);
        List<Map<String, String>> percentages = [];
        Set<String> seenConditions = {};
        if (analysis.trim().startsWith('[')) {
          try {
            final decoded = json.decode(analysis);
            if (decoded is List) {
              for (var item in decoded) {
                final lines = item.toString().split(RegExp(r'[,\n]'));
                for (var line in lines) {
                  final fixedLine =
                      line.replaceAll("Skin Redness", "Pigmentation");
                  final match = RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%')
                      .firstMatch(fixedLine);
                  if (match != null) {
                    var condition = match.group(1)!.trim();
                    if (condition.toLowerCase() == 'skin redness') {
                      condition = "Pigmentation";
                    }
                    if (condition.toLowerCase() == "acne" ||
                        condition.toLowerCase() == "acne_scar" ||
                        condition.toLowerCase() == "scar") {
                      // Find if "acne & acne scars" already exists in percentages
                      final existingIdx = percentages.indexWhere((p) =>
                          p['condition']!.toLowerCase() == "acne & acne scars");
                      if (existingIdx != -1) {
                        // Add this percent to the existing "acne & acne scars"
                        final existingPercent = double.tryParse(
                                percentages[existingIdx]['percent'] ?? "0") ??
                            0;
                        final currentPercent =
                            double.tryParse(match.group(2) ?? "0") ?? 0;
                        percentages[existingIdx]['percent'] =
                            (existingPercent + currentPercent)
                                .toStringAsFixed(2);
                        continue; // Skip adding "acne" separately
                      } else {
                        // If not exists, add as "acne & acne scars"
                        percentages.add({
                          'condition': "acne & acne scars",
                          'percent': match.group(2)!
                        });
                        seenConditions.add("Acne & Acne scars");
                        continue; // Skip adding "acne" separately
                      }
                    }
                    if (!seenConditions.contains(condition.toLowerCase())) {
                      percentages.add(
                          {'condition': condition, 'percent': match.group(2)!});
                      seenConditions.add(condition.toLowerCase());
                    }
                  }
                }
              }
            }
          } catch (e) {
            for (var line in analysis.split('\n')) {
              final fixedLine = line.replaceAll("Skin Redness", "Pigmentation");
              final match =
                  RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(fixedLine);
              if (match != null) {
                var condition = match.group(1)!.trim();
                if (condition.toLowerCase() == 'skin redness') {
                  condition = "Pigmentation";
                }
                if (condition.toLowerCase() == "acne" ||
                    condition.toLowerCase() == "acne scar" ||
                    condition.toLowerCase() == "scar") {
                  // Find if "acne & acne scars" already exists in percentages
                  final existingIdx = percentages.indexWhere((p) =>
                      p['condition']!.toLowerCase() == "acne & acne scars");
                  if (existingIdx != -1) {
                    // Add this percent to the existing "acne & acne scars"
                    final existingPercent = double.tryParse(
                            percentages[existingIdx]['percent'] ?? "0") ??
                        0;
                    final currentPercent =
                        double.tryParse(match.group(2) ?? "0") ?? 0;
                    percentages[existingIdx]['percent'] =
                        (existingPercent + currentPercent).toStringAsFixed(2);
                    continue; // Skip adding "acne" separately
                  } else {
                    // If not exists, add as "acne & acne scars"
                    percentages.add({
                      'condition': "Acne & Acne scars",
                      'percent': match.group(2)!
                    });
                    seenConditions.add("Acne & Acne scars");
                    continue; // Skip adding "acne" separately
                  }
                }
                if (!seenConditions.contains(condition.toLowerCase())) {
                  percentages.add(
                      {'condition': condition, 'percent': match.group(2)!});
                  seenConditions.add(condition.toLowerCase());
                }
              }
            }
          }
        } else {
          for (var line in analysis.split('\n')) {
            final fixedLine = line.replaceAll("Skin Redness", "Pigmentation");
            final match =
                RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(fixedLine);
            if (match != null) {
              var condition = match.group(1)!.trim();
              if (condition.toLowerCase() == 'skin redness') {
                condition = "Pigmentation";
              }
              // Combine "acne" and "acne & acne scars" percentages
              if (condition.toLowerCase() == "acne" ||
                  condition.toLowerCase() == "acne_scar" ||
                  condition.toLowerCase() == "scar") {
                // Find if "acne & acne scars" already exists in percentages
                final existingIdx = percentages.indexWhere((p) =>
                    p['condition']!.toLowerCase() == "acne & acne scars");
                if (existingIdx != -1) {
                  // Add this percent to the existing "acne & acne scars"
                  final existingPercent = double.tryParse(
                          percentages[existingIdx]['percent'] ?? "0") ??
                      0;
                  final currentPercent =
                      double.tryParse(match.group(2) ?? "0") ?? 0;
                  percentages[existingIdx]['percent'] =
                      (existingPercent + currentPercent).toStringAsFixed(2);
                  continue; // Skip adding "acne" separately
                } else {
                  // If not exists, add as "acne & acne scars"
                  percentages.add({
                    'condition': "Acne & Acne scars",
                    'percent': match.group(2)!
                  });
                  seenConditions.add("Acne & Acne scars");
                  continue; // Skip adding "acne" separately
                }
              }
              if (!seenConditions.contains(condition.toLowerCase())) {
                percentages
                    .add({'condition': condition, 'percent': match.group(2)!});
                seenConditions.add(condition.toLowerCase());
              }
            }
          }
        }

        double attractivenessScore = calculateAttractivenessScore(percentages);

        return {
          'percentages': percentages,
          'mainDiagnosis': "mainDiagnosis",
          'recommendations': "recommendations",
          'fullOutput': "output",
          'assessment': '',
          'scoreOutOf10': 0.0,
          'primaryCondition': '',
          'imageUrl': result['url'],
          'attractivenessScore': attractivenessScore,
        };
      }).toList();
    } catch (e) {
      print("Error extracting skin summaries: $e");
      return [];
    }
  }

  /// Calculate attractiveness score from percentages (clamped min 6.0, max 10.0)
  /// Calculate attractiveness score from percentages (reduced by 1, clamped min 6.0, max 9.0)
  double calculateAttractivenessScore(List<Map<String, String>> percentages) {
    double score = 8.0;
    double normalPercent = 0.0;
    double negativePercent = 0.0;
    final negativeConditions = [
      "acne",
      "wrinkle",
      "dark spot",
      "blackhead",
      "pores",
      "eye bag",
      "brown spot",
      "mole",
      "comedone",
      "dark circle",
      "Pigmentation",
      "eye pouch",
      "nasolabial fold"
    ];

    for (final entry in percentages) {
      final cond = entry['condition']?.toLowerCase() ?? "";
      final percent = double.tryParse(entry['percent'] ?? "0") ?? 0;
      if (cond.contains("normal")) {
        normalPercent += percent;
      } else if (negativeConditions.any((c) => cond.contains(c))) {
        negativePercent += percent;
      }
    }

    score += (normalPercent / 100) * 2.0;
    score -= (negativePercent / 100) * 2.5;

    // Reduce score by 1 point as requested
    score = score - 1.0;

    // Clamp between 6.0 and 9.0 (reduced from 10.0 to 9.0)
    if (score < 6.0) score = 6.0;
    if (score > 9.0) score = 9.0;

    return double.parse(score.toStringAsFixed(2));
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
    if (cond.contains('mole')) return 30;
    if (cond.contains('comedone')) return 20;
    if (cond.contains('dark circle')) return 20;
    if (cond.contains('Pigmentation')) return 20;
    return 30;
  }

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
    if (cond.contains('Pigmentation')) return Icons.warning;
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
    if (cond.contains('Pigmentation')) return Colors.pinkAccent;
    return Colors.grey;
  }

// ... keep all your imports and code as is above ...

  @override
  Widget build(BuildContext context) {
    final summaries = extractSkinSummaries(widget.gradioResult);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skin Analysis Results',
          style: TextStyle(
            fontFamily: 'SansSerif',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
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
                  final attractivenessScore =
                      summary['attractivenessScore'] as double;

                  final chartData = percentages
                      .map((p) => {
                            "condition": p['condition'].toUpperCase(),
                            "percent":
                                double.tryParse(p['percent'] ?? "0") ?? 0.0
                          })
                      .toList();

                  final averageMap = {
                    "normal": 100.0,
                    "wrinkle": 25.0,
                    "acne": 15.0,
                    "blackhead": 20.0,
                    "dark spot": 15.0,
                    "pores": 25.0,
                    "eye bag": 20.0,
                    "brown spot": 15.0,
                    "mole": 30.0,
                    "comedone": 20.0,
                    "dark circle": 20.0,
                    "Pigmentation": 20.0,
                    "eye pouch": 20.0,
                    "nasolabial fold": 20.0,
                  };

                  return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // const SizedBox(height: 20),
                            Row(
                              children: [
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
                                    elevation: 6,
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 700),
                                      curve: Curves.easeInOut,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            // Theme.of(context)
                                            //     .colorScheme
                                            //     .wh,
                                            Colors.white,
                                            Colors.white,
                                            // Theme.of(context)
                                            //     .colorScheme
                                            //     .primary.withOpacity(0.1),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.deepPurple
                                                .withOpacity(0.08),
                                            blurRadius: 16,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 22, horizontal: 12),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            tween: Tween<double>(
                                                begin: 0,
                                                end: attractivenessScore),
                                            duration: const Duration(
                                                milliseconds: 2700),
                                            curve: Curves.easeOutExpo,
                                            builder: (context, value, child) {
                                              return buildAssessmentChart(value,
                                                  label: "Attractiveness");
                                            },
                                          ),
                                          const SizedBox(height: 10),
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 2700),
                                            child: attractivenessScore >= 9
                                                ? const Row(
                                                    key: ValueKey("excellent"),
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.star,
                                                          color: Colors.amber,
                                                          size: 28),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        "You're in the top 20 people!",
                                                        style: TextStyle(
                                                            color: Colors.green,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16),
                                                      ),
                                                    ],
                                                  )
                                                : attractivenessScore >= 8
                                                    ? Row(
                                                        key: ValueKey("good"),
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                              Icons.thumb_up,
                                                              color:
                                                                  Colors.green,
                                                              size: 24),
                                                          const SizedBox(
                                                              width: 6),
                                                          const Text(
                                                            "You're in the top 20 people!",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .green,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 15),
                                                          ),
                                                        ],
                                                      )
                                                    : Container(),
                                          ),
                                          const SizedBox(height: 8),
                                          AnimatedOpacity(
                                            opacity: 1.0,
                                            duration: const Duration(
                                                milliseconds: 900),
                                            child: Text(
                                              "Your Attractiveness Index is calculated using AI and dermatology standards. Higher scores mean healthier, more radiant skin!",
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics:
                                  NeverScrollableScrollPhysics(), // Prevent scrolling
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio:
                                    MediaQuery.of(context).size.width < 400
                                        ? 1.3
                                        : 2.4,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                              itemCount: percentages.length,
                              itemBuilder: (context, idx) {
                                final p = percentages[idx];
                                return _summaryStat(
                                  p['condition'].toUpperCase() ?? '',
                                  "${p['percent']}%",
                                  _getConditionIcon(p['condition'] ?? ''),
                                  Theme.of(context).colorScheme.primary,
                                  context,
                                  compareTo: getNormalPercentage(p['condition'])
                                      .toDouble(),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            // Replace your existing CustomSpiderChart usage with this:
                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: CustomSpiderChart(
                                data: chartData,
                                averageMap: averageMap,
                                chartRadius:
                                    MediaQuery.of(context).size.width < 400
                                        ? 80.0
                                        : 120.0,
                                tickCount: 5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.yellow.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.yellow.shade700, width: 1),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline,
                                        color: Colors.orange, size: 22),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "This is an AI-generated analysis. Please consult a dermatologist for professional advice.",
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

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
                                    GestureDetector(
                                      onTap: () {
                                        _showImageDialog(context, imageUrl);
                                      },
                                      child: Card(
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
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(height: 24),

                            // Payment or unlocked section (coupon UI moved inside payment box)
                            !_hasPaid
                                ? Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(16),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
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
                                          const SizedBox(height: 20),
                                          // Coupon UI inside payment box
                                          Text(
                                            "Have a coupon?",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.deepPurple.shade200,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextField(
                                                  controller: _couponController,
                                                  enabled: !_couponApplied,
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Enter coupon code",
                                                    hintStyle: TextStyle(
                                                        color: Colors.white54),
                                                    filled: true,
                                                    fillColor: Colors.black,
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .deepPurple
                                                              .shade200),
                                                    ),
                                                    focusedBorder:
                                                        OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                      borderSide: BorderSide(
                                                          color: Colors
                                                              .deepPurple),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              ElevatedButton(
                                                onPressed: _couponApplied ||
                                                        _couponChecking
                                                    ? null
                                                    : _applyCoupon,
                                                child: _couponChecking
                                                    ? const SizedBox(
                                                        width: 16,
                                                        height: 16,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                      )
                                                    : Text(_couponApplied
                                                        ? "Applied"
                                                        : "Apply"),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      _couponApplied
                                                          ? Colors.green
                                                          : Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  minimumSize: Size(90, 48),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (_couponError.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 6.0),
                                              child: Text(
                                                _couponError,
                                                style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          if (_couponApplied &&
                                              _appliedCoupon.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 6.0),
                                              child: Text(
                                                "Coupon \"$_appliedCoupon\" applied!",
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 16),
                                          Text(
                                            _couponApplied
                                                ? "Your coupon is applied! Click below to unlock your report."
                                                : "Reveal your skin’s secrets with our in-depth analysis — just ₹499",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            icon: Icon(_couponApplied
                                                ? Icons.check
                                                : Icons.lock_open),
                                            label: Text(_couponApplied
                                                ? "Unlock with Coupon"
                                                : "Unlock Full Details (₹499)"),
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
                                : Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.deepPurple,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepPurple
                                              .withOpacity(0.08),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12.0),
                                          child: Column(
                                            children: [
                                              Icon(Icons.emoji_events,
                                                  color: Colors.amber,
                                                  size: 60),
                                              const SizedBox(height: 12),
                                              Text(
                                                "Congratulations!",
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "You've unlocked your full skin analysis.",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Your image has been sent to our experts. You will receive a detailed PDF report within 24 hours via email, or you can login to Youvai to view and download your full report.",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black54,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                            // Column(
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   children: [
                            //     const SizedBox(height: 10),
                            //     const Text(
                            //       "Recommended Doctor's",
                            //       style: TextStyle(
                            //         fontSize: 18,
                            //         fontWeight: FontWeight.bold,
                            //         color: Colors.black,
                            //       ),
                            //     ),
                            //     const SizedBox(height: 10),
                            //     SizedBox(
                            //       height: 300,
                            //       child: ListView.builder(
                            //         physics: const BouncingScrollPhysics(),
                            //         padding: const EdgeInsets.only(right: 16),
                            //         scrollDirection: Axis.horizontal,
                            //         itemCount: doctorList.length,
                            //         itemBuilder: (context, index) {
                            //           final doctor = doctorList[index];
                            //           return DoctorCard(
                            //             title: doctor["name"],
                            //             speciality:
                            //                 doctor["speciality"].toString(),
                            //             stars:
                            //                 doctor["reviewStars"].toString(),
                            //             totalReviews:
                            //                 doctor["totalReviews"].toString(),
                            //           );
                            //         },
                            //       ),
                            //     ),
                            //   ],
                            // )
                          ],
                        ),
                      ));
                },
              ),
            ),
    );
  }
// ... keep the rest of your code as is ...

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
              "$label Index Score",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
      ],
    );
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
    "combination skin": {
      "type": "Combination Skin",
      "meaning":
          "A skin type where some areas of the face are oily (commonly the T-zone: forehead, nose, chin) while other areas, like the cheeks and jawline, are dry or normal.",
      "cause":
          "Genetics, hormonal changes, uneven oil (sebum) production, seasonal changes, or use of unsuitable skincare products.",
      "suggestion":
          "Use a gentle cleanser, apply lightweight non-comedogenic moisturizer on oily zones, richer hydration on dry zones, and balance with products designed for combination skin.",
      "ageInfo": {
        "typicalAge":
            "Can occur at any age, but often noticeable during teens to early adulthood.",
        "averageRange": "30–40% of people",
        "under":
            "Below 30% – Skin is mostly uniform (either dry, normal, or oily).",
        "normal": "30–40% – Balanced mix of oily T-zone and dry/normal cheeks.",
        "high":
            "Above 40% – Pronounced difference between oily and dry zones; requires tailored skincare routine.",
        "statusThresholds": {"under": 30, "normal": 40}
      },
    },
    "oily skin": {
      "type": "Oily Skin",
      "meaning":
          "A skin type where sebaceous glands produce excess sebum, leading to shine, enlarged pores, and higher risk of acne and blackheads.",
      "cause":
          "Genetics, hormonal imbalance, humidity, or overuse of harsh skincare that triggers oil rebound.",
      "suggestion":
          "Use oil-free, non-comedogenic products, gel-based moisturizers, gentle exfoliation, and avoid heavy creams.",
      "ageInfo": {
        "typicalAge": "13–30 years",
        "averageRange": "20–30%",
        "under": "Below 20% – Minimal oil, skin tends toward normal/dry.",
        "normal": "20–30% – Balanced oil production with some shine.",
        "high": "Above 30% – Excess sebum, frequent breakouts, enlarged pores.",
        "statusThresholds": {"under": 20, "normal": 30}
      },
    },
    "dry skin": {
      "type": "Dry Skin",
      "meaning":
          "A skin type that lacks sufficient moisture and natural oils, resulting in tightness, rough texture, and flakiness.",
      "cause":
          "Genetics, low humidity, cold weather, excessive washing, or aging-related decrease in oil production.",
      "suggestion":
          "Use hydrating cleansers, ceramide-based moisturizers, avoid harsh soaps, and apply sunscreen to prevent further dryness.",
      "ageInfo": {
        "typicalAge": "Any age, more common in adults and elderly",
        "averageRange": "15–25%",
        "under": "Below 15% – Well-hydrated skin, minimal dryness.",
        "normal": "15–25% – Mild dryness, occasional tightness.",
        "high":
            "Above 25% – Persistent flakiness, irritation, needs medical care.",
        "statusThresholds": {"under": 15, "normal": 25}
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
    "pigmentation": {
      "type": "Pigmentation",
      "meaning":
          "A condition where certain areas of the skin become darker than the surrounding skin due to excess melanin production.",
      "cause":
          "Sun exposure, hormonal changes, skin inflammation, aging, or certain medications.",
      "suggestion":
          "Use sunscreen daily (SPF 30+), avoid direct sunlight, consider brightening agents like vitamin C or niacinamide, and seek dermatological treatments if severe.",
      "ageInfo": {
        "typicalAge": "20–50 years",
        "averageRange": "5–20%",
        "under": "Below 5% – Even-toned skin, minimal pigmentation signs",
        "normal": "5–20% – Mild pigmentation, common in adults",
        "high":
            "Above 20% – Moderate to severe pigmentation, may require professional treatment",
        "statusThresholds": {"under": 5, "normal": 20}
      }
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
    "Pigmentation": {
      "type": "Pigmentation",
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
    "scars": {
      "type": "Scars",
      "meaning":
          "A skin condition that occurs when the skin heals after an injury, acne, or surgery, leaving marks or indentations on the surface. Scars can appear as flat, raised, or pitted areas.",
      "cause":
          "Damage to the deeper layers of skin due to acne, wounds, burns, surgery, or infections. The body produces excess or irregular collagen during healing.",
      "suggestion":
          "Use sunscreen to prevent darkening, consider silicone gels/patches, gentle exfoliation, or dermatologist treatments like chemical peels, microneedling, or laser therapy for deeper scars.",
      "ageInfo": {
        "typicalAge":
            "Can occur at any age, more common after acne (teens–30s) or injuries.",
        "averageRange": "10–20% of people have visible scars.",
        "under": "Below 10% – Minimal or no visible scarring.",
        "normal":
            "10–20% – Mild scarring, usually from acne or small injuries.",
        "high":
            "Above 20% – Moderate to severe scarring, may need medical/dermatological intervention.",
        "statusThresholds": {"under": 10, "normal": 20}
      },
    },
    "melasma": {
      "type": "Melasma",
      "meaning":
          "A common skin condition that causes dark, discolored patches on the skin, usually on the face (cheeks, forehead, upper lip, nose). It is often symmetrical and worsens with sun exposure.",
      "cause":
          "Overproduction of melanin due to hormonal changes (pregnancy, birth control, thyroid issues), genetics, sun exposure, or certain medications.",
      "suggestion":
          "Use broad-spectrum sunscreen daily, wear protective clothing, and consider dermatologist treatments like chemical peels, topical lightening creams (hydroquinone, azelaic acid), or laser therapy. Avoid excessive sun exposure.",
      "ageInfo": {
        "typicalAge": "20–50 years, more common in women.",
        "averageRange":
            "15–25% of adults (higher prevalence in women with darker skin types).",
        "under": "Below 15% – Rare or minimal pigmentation issues.",
        "normal":
            "15–25% – Mild to moderate patches, common in women of childbearing age.",
        "high":
            "Above 25% – Severe pigmentation, widespread patches; requires medical intervention.",
        "statusThresholds": {"under": 15, "normal": 25}
      },
    },
    "wrinkle": {
      "type": "Wrinkles",
      "meaning":
          "Fine lines or creases that form in the skin due to aging, loss of elasticity, and repeated facial expressions. They can appear on the forehead, around the eyes (crow’s feet), mouth, and neck.",
      "cause":
          "Natural aging process, decreased collagen and elastin, sun exposure (photoaging), smoking, dehydration, stress, or genetics.",
      "suggestion":
          "Use sunscreen daily, apply moisturizers with hyaluronic acid or peptides, consider retinoids, antioxidant serums (Vitamin C, E), and professional treatments like Botox, fillers, or laser resurfacing for deeper wrinkles.",
      "ageInfo": {
        "typicalAge": "30+ years (earlier with sun damage or smoking).",
        "averageRange": "20–30% of adults show visible wrinkles by mid-30s.",
        "under": "Below 20% – Minimal fine lines, usually in younger adults.",
        "normal":
            "20–30% – Mild to moderate wrinkles, typical with age progression.",
        "high":
            "Above 30% – Pronounced/deep wrinkles; may need medical/cosmetic treatments.",
        "statusThresholds": {"under": 20, "normal": 30}
      },
    },
    "normal skin": {
      "type": "Normal Skin",
      "meaning":
          "A balanced skin type with neither excessive oiliness nor dryness; smooth texture, few imperfections, and minimal sensitivity.",
      "cause":
          "Genetics, well-balanced sebum production, and healthy lifestyle factors.",
      "suggestion":
          "Maintain routine with gentle cleanser, lightweight moisturizer, and sunscreen; avoid overusing harsh products.",
      "ageInfo": {
        "typicalAge": "Any age, more common in children and young adults",
        "averageRange": "25–35%",
        "under": "Below 25% – Some imbalance toward oily/dry tendencies.",
        "normal": "25–35% – Even tone, good hydration, minimal issues.",
        "high": "Above 35% – Ideal balanced skin, least prone to problems.",
        "statusThresholds": {"under": 25, "normal": 35}
      },
    },
    "acne & acne scars": {
      "type": "Acne & Acne Scars",
      "meaning":
          "This combines active acne (pimples, cysts, blackheads) and the marks left behind after acne heals (scars, indentations, or dark spots). Both conditions can affect skin texture and appearance.",
      "cause":
          "Hormonal changes, excess oil production, bacteria, genetics, poor hygiene, and improper acne treatment can lead to acne. Scarring occurs when deeper layers of skin are damaged during healing.",
      "suggestion":
          "Use gentle cleansers, non-comedogenic products, and topical treatments with salicylic acid or benzoyl peroxide for active acne. For scars, consider products with retinoids, vitamin C, or consult a dermatologist for procedures like chemical peels, microneedling, or laser therapy.",
      "ageInfo": {
        "typicalAge":
            "10–35 years (acne most common in teens and young adults; scars can persist longer)",
        "averageRange": "15–30% of people experience both acne and scarring",
        "under": "Below 15% – Clear skin, minimal active acne or scarring.",
        "normal":
            "15–30% – Mild to moderate acne and some scarring, common in teens and young adults.",
        "high":
            "Above 30% – Frequent breakouts and visible scars, may need medical/dermatological intervention.",
        "statusThresholds": {"under": 15, "normal": 30}
      },
    },
  };

  Widget _summaryStat(String label, String value, IconData? icon, Color? color,
      BuildContext context,
      {String? status, double? compareTo}) {
    double currentValue = double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    String? compareText;
    Color? compareColor;

    if (compareTo != null) {
      if (currentValue > compareTo) {
        compareText = "Higher than average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.redAccent;
      } else if (currentValue < compareTo) {
        compareText = "Lower than average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.blueGrey;
      } else {
        compareText = "Equal to average (${compareTo.toStringAsFixed(1)}%)";
        compareColor = Colors.blueGrey;
      }
    }

    return InkWell(
      onTap: () {
        final info = conditionInfo[label.toLowerCase()];
        if (info != null) {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            builder: (context) {
              return SingleChildScrollView(
                child: Padding(
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
                      if (info['ageInfo'] != null &&
                          info['ageInfo'] is Map) ...[
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
                ),
              );
            },
          );
        }
      },
      child: Container(
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

  final List<Map<String, dynamic>> doctorList = [
    {
      "name": "Dr. Shushant Shetty",
      "speciality": "Dermatology Specialist",
      "reviewStars": 5,
      "totalReviews": "1,952",
      "imageUrl": "https://randomuser.me/api/portraits/men/32.jpg",
    },
    {
      "name": "Dr. Viral Desai",
      "speciality": "Celebrity Cosmetic & Plastic Surgeon",
      "reviewStars": 4.8,
      "totalReviews": "1,200",
      "imageUrl": "https://randomuser.me/api/portraits/women/44.jpg",
    },
    {
      "name": "Dr.Neha ",
      "speciality": " Dermatologist ",
      "reviewStars": 4.9,
      "totalReviews": "1,500",
      "imageUrl": "https://randomuser.me/api/portraits/women/65.jpg",
    },
  ];

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1,
          maxScale: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 320,
                height: 320,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image, size: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
