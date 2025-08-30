import 'dart:convert';
import 'dart:js' as js;
import 'dart:typed_data';
import 'dart:ui' as ui;
// Web-only helper (this file already targets web via dart:js)
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_web/razorpay_web.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:skin_assessment/widgets/CustomSpiderChart.dart';
import 'package:skin_assessment/widgets/doctor_card.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // for Multipart content type
// import 'package:qr_flutter/qr_flutter.dart'; // <-- REMOVED: no longer needed

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

  // Key to capture a beautiful PNG of the Attractiveness card
  final GlobalKey _attractivenessShareKey = GlobalKey();

  // ---------- NEW: capture-only extras (QR + link) ----------
  bool _captureExtras = false; // true only while generating image
  static const String _landingUrl = 'https://aesthetic.youv.ai/';
  late final ImageProvider _qrProvider = NetworkImage(
      'https://api.qrserver.com/v1/create-qr-code/?size=120x120&data=${Uri.encodeComponent(_landingUrl)}');
  bool _qrReady = false;
  // ----------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Initialize Razorpay to avoid null errors on dispose
    try {
      _razorpay = Razorpay();
    } catch (_) {
      _razorpay = Razorpay();
    }

    // Precache the QR image so it paints before we capture
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await precacheImage(_qrProvider, context);
        if (mounted) setState(() => _qrReady = true);
      } catch (_) {}
    });

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
        "order_id": paymentId,
        "customer_id": "",
      },
      "transaction_reference": paymentId,
      "processed_at": DateTime.now().toIso8601String(),
    };

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';
      prefs.setBool('isSubscribe', true);
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
          'https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/payment/store'); // fixed
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
      prefs.setBool('isSubscribe', true);
      setState(() {
        _hasPaid = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coupon applied! Details unlocked.")),
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

      final body = jsonDecode(response.body);

      if (body['message'] == "Coupon verified successfully") {
        setState(() {
          _couponApplied = true;
          _appliedCoupon = code;
          _couponError = "";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Coupon applied! Payment skipped.")),
        );
      } else {
        setState(() {
          _couponError = body['message'] ?? "Invalid coupon.";
          _couponApplied = false;
          _appliedCoupon = "";
        });
      }
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

    // Clamp between 6.0 and 9.0
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
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share),
            onPressed: () async {
              Uint8List? bytes;
              double score = 0.0;

              try {
                final summaries = extractSkinSummaries(widget.gradioResult);
                if (summaries.isNotEmpty) {
                  score =
                      summaries.first['attractivenessScore'] as double? ?? 0.0;
                }

                // Capture with extras ON (QR + link only in image)
                bytes = await _captureAttractivenessImage();
                if (bytes != null) {
                  _downloadPng(bytes,
                      filenameHint: 'youvai_attractiveness.png');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Image prepared! Use it while sharing/uploading.'),
                    ),
                  );
                }
              } catch (_) {}

              // Upload to get public link
              String? uploadedUrl;
              if (bytes != null) {
                uploadedUrl = await _uploadShareImageMultipart(bytes, score);
              }

              // Open sharing sheet with URL if available
              _openShareOptions(publicImageUrl: uploadedUrl);
            },
          ),
        ],
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
                            "condition": p['condition'],
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
                            Row(
                              children: [
                                Expanded(
                                  child: RepaintBoundary(
                                    key: _attractivenessShareKey,
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
                                          gradient: const LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.white,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                            const Text(
                                              "Youvai — Attractiveness Index",
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 8),
                                            TweenAnimationBuilder<double>(
                                              tween: Tween<double>(
                                                  begin: 0,
                                                  end: attractivenessScore),
                                              duration: const Duration(
                                                  milliseconds: 2700),
                                              curve: Curves.easeOutExpo,
                                              builder: (context, value, child) {
                                                return buildAssessmentChart(
                                                  value,
                                                  label: "Attractiveness",
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 10),
                                            AnimatedSwitcher(
                                              duration: const Duration(
                                                  milliseconds: 2700),
                                              child: attractivenessScore >= 9
                                                  ? const Row(
                                                      key:
                                                          ValueKey("excellent"),
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(Icons.star,
                                                            color: Colors.amber,
                                                            size: 28),
                                                        SizedBox(width: 6),
                                                        Text(
                                                          "You're in the top 20 people!",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.green,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16),
                                                        ),
                                                      ],
                                                    )
                                                  : attractivenessScore >= 8
                                                      ? Row(
                                                          key: const ValueKey(
                                                              "good"),
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(Icons.thumb_up,
                                                                color: Colors
                                                                    .green,
                                                                size: 24),
                                                            SizedBox(width: 6),
                                                            Text(
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
                                                      : const SizedBox.shrink(),
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
                                            const SizedBox(height: 6),
                                            Text(
                                              "Generated on ${DateFormat('MMM d, yyyy – HH:mm').format(DateTime.now())}",
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black54),
                                            ),

                                            // ---- CALL TO ACTION / LINK + QR (capture-only) ----
                                            const SizedBox(height: 12),
                                            Visibility(
                                              visible: _captureExtras,
                                              replacement:
                                                  const SizedBox.shrink(),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 10,
                                                        horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: Color(0xFFF4F1FF),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Color(0xFF7C4DFF)
                                                        .withOpacity(0.35),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      "Do your own AI skin analysis",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Color(0xFF5E35B1),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    const Text(
                                                      "aesthetic.youv.ai",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        decoration:
                                                            TextDecoration
                                                                .underline,
                                                        color:
                                                            Color(0xFF311B92),
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Center(
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        child: Container(
                                                          color: Colors.white,
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(6),
                                                          child: _qrReady
                                                              ? Image(
                                                                  image:
                                                                      _qrProvider,
                                                                  width: 72,
                                                                  height: 72,
                                                                  fit: BoxFit
                                                                      .contain,
                                                                )
                                                              : const Icon(
                                                                  Icons
                                                                      .qr_code_2,
                                                                  size: 48),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // ---------------------------------------------------
                                            const SizedBox(height: 4),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
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
                                  p['condition'] ?? '',
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
                            // Spider chart
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
                                  children: const [
                                    Icon(Icons.info_outline,
                                        color: Colors.orange, size: 22),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "This is an AI-generated analysis. Please consult a dermatologist for professional advice.",
                                        style: TextStyle(
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
                            const Text("From Recently Uploaded Image",
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

                            // Payment or unlocked section
                            !_hasPaid
                                ? Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [
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
                                          const Icon(Icons.lock,
                                              color: Colors.white, size: 40),
                                          const SizedBox(height: 12),
                                          const Text(
                                            "Unlock Full Details",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
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
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        "Enter coupon code",
                                                    hintStyle: const TextStyle(
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
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      _couponApplied
                                                          ? Colors.green
                                                          : Colors.deepPurple,
                                                  foregroundColor: Colors.white,
                                                  minimumSize:
                                                      const Size(90, 48),
                                                ),
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
                                              ),
                                            ],
                                          ),
                                          if (_couponError.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 6.0),
                                              child: Text(
                                                _couponError,
                                                style: const TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                          if (_couponApplied &&
                                              _appliedCoupon.isNotEmpty)
                                            const Padding(
                                              padding:
                                                  EdgeInsets.only(top: 6.0),
                                              child: Text(
                                                "Coupon applied!",
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
                                            style: const TextStyle(
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
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12.0),
                                          child: Column(
                                            children: const [
                                              Icon(Icons.emoji_events,
                                                  color: Colors.amber,
                                                  size: 60),
                                              SizedBox(height: 12),
                                              Text(
                                                "Congratulations!",
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.deepPurple,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                "You've unlocked your full skin analysis.",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                              SizedBox(height: 8),
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
                          ],
                        ),
                      ));
                },
              ),
            ),
    );
  }

  // ------- SHARE HELPERS -------

  Future<Uint8List?> _captureAttractivenessImage() async {
    try {
      // Turn on extras (QR + link) only for the capture frame
      if (mounted) setState(() => _captureExtras = true);

      // Give Flutter a frame to lay out & paint with extras visible
      await Future.delayed(const Duration(milliseconds: 40));
      await WidgetsBinding.instance.endOfFrame;

      final boundary = _attractivenessShareKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Turn extras off immediately after capture so they are NOT in the UI
      if (mounted) setState(() => _captureExtras = false);

      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Capture error: $e');
      // Make sure to reset the flag on error too
      if (mounted) setState(() => _captureExtras = false);
      return null;
    }
  }

  /// Upload captured image to backend to get a public URL
  Future<String?> _uploadShareImageMultipart(
      Uint8List bytes, double score) async {
    try {
      final uri = Uri.parse(
        "https://aestheticai.globalspace.in/youvai/youvai_backend/public/api/shareimage/upload-image",
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('_token') ?? '';

      final request = http.MultipartRequest('POST', uri)
        ..fields['score'] = score.toStringAsFixed(2)
        ..fields['title'] = 'Youvai — Attractiveness Index'
        ..files.add(http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: 'youvai_attractiveness.png',
          contentType: MediaType('image', 'png'),
        ));

      if (token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final decoded = jsonDecode(res.body) as Map<String, dynamic>;

        // handle both shapes: {"url": "..."} OR {"data":{"url":"..."}}
        final url = (decoded['url'] ??
            (decoded['data'] is Map<String, dynamic>
                ? (decoded['data'] as Map<String, dynamic>)['url']
                : null)) as String?;

        if (url != null && url.isNotEmpty) {
          debugPrint("Upload (multipart) success: $url");
          return url; // already unescaped by jsonDecode
        }
        debugPrint("Upload (multipart) success but no url found: ${res.body}");
        return null;
      }

      debugPrint("Upload (multipart) failed: ${res.statusCode} ${res.body}");
    } catch (e) {
      debugPrint("Upload (multipart) error: $e");
    }
    return null;
  }

  void _downloadPng(Uint8List bytes, {String filenameHint = 'share.png'}) {
    if (kIsWeb) {
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..download = filenameHint
        ..style.display = 'none';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    }
  }

  void _openShareOptions({String? publicImageUrl}) {
    final summaries = extractSkinSummaries(widget.gradioResult);
    double score = 0.0;
    if (summaries.isNotEmpty) {
      score = summaries.first['attractivenessScore'] as double? ?? 0.0;
    }

    final landing = _landingUrl; // updated landing link
    final linkToInclude = Uri.encodeComponent(publicImageUrl ?? landing);
    final msg = Uri.encodeComponent(
        "My Youvai Attractiveness Index is ${score.toStringAsFixed(2)}/10 ✨\nTry your AI skin analysis at aesthetic.youv.ai\n${publicImageUrl ?? landing}");

    // Facebook: share a URL; add our link for preview (ensure og tags on server)
    final fbShare =
        "https://www.facebook.com/sharer/sharer.php?u=$linkToInclude&quote=$msg";

    // WhatsApp: share text + link (shows rich preview)
    final waShare = "https://api.whatsapp.com/send?text=$msg";

    // Instagram Web: requires manual upload of the downloaded PNG
    const instaOpen = "https://www.instagram.com/";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                height: 4,
                width: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Share your results",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: const Text('Share on WhatsApp'),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse(waShare),
                      mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.facebook),
                title: const Text('Share on Facebook'),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse(fbShare),
                      mode: LaunchMode.externalApplication);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Open Instagram (upload your image)'),
                subtitle: const Text(
                    'We downloaded the image for you — add it to your post or story.'),
                onTap: () async {
                  Navigator.pop(context);
                  await launchUrl(Uri.parse(instaOpen),
                      mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ------- UI bits -------

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
        const SizedBox(height: 15),
        if (label != null)
          const Padding(
            padding: EdgeInsets.only(bottom: 2.0),
            child: Text(
              "Attractiveness Index Score",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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
    // ... (unchanged conditionInfo map)
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
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                                text: "Inital Cause: ",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text("${info['cause']}"),
                      const SizedBox(height: 8),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.black),
                          children: [
                            TextSpan(
                                text: "Suggestions: ",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text("${info['suggestion']}"),
                      const SizedBox(height: 8),
                      if (info['ageInfo'] != null &&
                          info['ageInfo'] is Map) ...[
                        const SizedBox(height: 8),
                        const Text(
                          "Age Information:",
                          style: TextStyle(fontWeight: FontWeight.bold),
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
                      style: const TextStyle(
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
