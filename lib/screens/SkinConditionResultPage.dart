import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_web/razorpay_web.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/models/FaceRatioLine.dart';
import 'package:skin_assessment/screens/FaceRatioCard.dart';
import 'package:skin_assessment/services/face_ratio_api.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:http/http.dart' as http;

import 'package:skin_assessment/bloc/auth/auth_bloc.dart';
import 'package:skin_assessment/bloc/auth/auth_state.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:js_util' as js_util;
import 'package:image/image.dart' as img;

class SkinConditionResultPage extends StatefulWidget {
  final Map<String, dynamic> gradioResult;
  final Map<String, dynamic>? faceRatioJson;

  SkinConditionResultPage({
    Key? key,
    required this.gradioResult,
    this.faceRatioJson,
  }) : super(key: key);

  @override
  State<SkinConditionResultPage> createState() =>
      _SkinConditionResultPageState();
}

class FaceOverlayPayload {
  final FaceRatioData data;
  final Uint8List croppedBytes;
  FaceOverlayPayload({required this.data, required this.croppedBytes});
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
  final Map<String, Future<FaceRatioData?>> _faceRatioFutureByImage = {};

  // Dynamic aspect label state
  String _currentAspectLabel = "Vertical Sections";
  void _onAspectModeChanged(RatioMode mode) {
    setState(() {
      _currentAspectLabel = _labelForMode(mode);
    });
  }

  String _labelForMode(RatioMode mode) {
    switch (mode) {
      case RatioMode.vertical:
        return "Vertical Sections";
      case RatioMode.horizontal:
        return "Horizontal Sections";
      case RatioMode.eyes:
        return "Eye Aspect Ratio";
      case RatioMode.faceBox:
        return "Face Aspect Ratio";
      case RatioMode.noseLipChin:
        return "Nose–Lip–Chin";
      case RatioMode.lips:
        return "Lips Ratio";
      case RatioMode.jaw:
        return "Jaw Ratio";
      default:
        return "Facial Ratio";
    }
  }

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

    if (_couponApplied) {
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
          SnackBar(content: Text("Coupon applied! Payment skipped.")),
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

  // --------------------- SCORING HELPERS ---------------------

  double _safeDiv(double a, double b) => b == 0 ? 0 : a / b;

  double? _parseRatioToNumber(String? s) {
    if (s == null) return null;
    final parts = s.split(':').map((e) => e.trim()).toList();
    if (parts.length != 2) return double.tryParse(s);
    final left = double.tryParse(parts[0]);
    final right = double.tryParse(parts[1]);
    if (left == null || right == null || left == 0) return null;
    return right / left;
  }

  /// Deviation-based score 0..10 (10 == perfect)
  double _scoreFromRatio(double? measured, double? ideal) {
    if (measured == null || ideal == null || ideal == 0) return 0;
    final err = (measured - ideal).abs() / ideal;
    final norm = (err > 1.5) ? 1.5 : err;
    final s = 10.0 * (1.0 - norm / 1.5);
    return s.clamp(0.0, 10.0);
  }

  /// Uniform sections (percent lists) -> 0..10
  double _scoreFromUniformSections(List<double> vals) {
    if (vals.isEmpty) return 0;
    final n = vals.length;
    final sum = vals.fold(0.0, (a, b) => a + b);
    if (sum <= 0) return 0;

    final perc = (sum - 100).abs() < 2
        ? vals
        : vals.map((v) => v / sum * 100.0).toList();

    final ideal = 100.0 / n;
    final avgAbsDev =
        perc.map((v) => (v - ideal).abs()).fold(0.0, (a, b) => a + b) / n;

    double normalized = 1.0 - _safeDiv(avgAbsDev, ideal);
    if (normalized < 0) normalized = 0;
    if (normalized > 1) normalized = 1;
    return (10.0 * normalized).clamp(0.0, 10.0);
  }

  /// Symmetry subscore from FaceRatioData: 0..10
  double calculateSymmetryScoreFromFaceData(FaceRatioData? d) {
    if (d == null) return 7.0; // neutral

    final components = <double>[];
    final weights = <double>[];

    // Vertical (5 sections)
    if (d.verticalPerc.isNotEmpty) {
      components.add(_scoreFromUniformSections(d.verticalPerc));
      weights.add(30);
    }

    // Horizontal (3 sections)
    if (d.horizontalPerc.isNotEmpty) {
      components.add(_scoreFromUniformSections(d.horizontalPerc));
      weights.add(30);
    }

    // Face box ratio
    final faceGolden = _parseRatioToNumber(d.faceBox?.golden);
    final faceYours = _parseRatioToNumber(d.faceBox?.yours);
    if (faceGolden != null && faceYours != null) {
      components.add(_scoreFromRatio(faceYours, faceGolden));
      weights.add(10);
    }

    // Nose-lip-chin
    final nlcMeasured = _parseRatioToNumber(d.noseLipChinRatio);
    final nlcIdeal = _parseRatioToNumber(d.noseLipChinIdeal);
    if (nlcMeasured != null && nlcIdeal != null) {
      components.add(_scoreFromRatio(nlcMeasured, nlcIdeal));
      weights.add(10);
    }

    // Lips
    final lipsMeasured = _parseRatioToNumber(d.lipRatio);
    final lipsIdeal = _parseRatioToNumber(d.lipIdeal);
    if (lipsMeasured != null && lipsIdeal != null) {
      components.add(_scoreFromRatio(lipsMeasured, lipsIdeal));
      weights.add(10);
    }

    // Eyes (avg of L/R)
    double? _eyeScore(EyeBox? e) {
      if (e == null) return null;
      final g = _parseRatioToNumber(e.golden);
      final m = _parseRatioToNumber(e.measured);
      if (g == null || m == null) return null;
      return _scoreFromRatio(m, g);
    }

    final lScore = _eyeScore(d.leftEye);
    final rScore = _eyeScore(d.rightEye);
    double? eyeScore;
    if (lScore != null && rScore != null) {
      eyeScore = (lScore + rScore) / 2.0;
    } else {
      eyeScore = lScore ?? rScore;
    }
    if (eyeScore != null) {
      components.add(eyeScore);
      weights.add(5);
    }

    // Jaw
    if (d.jaw != null && d.jaw!.ideal > 0 && d.jaw!.ratio > 0) {
      components.add(_scoreFromRatio(d.jaw!.ratio, d.jaw!.ideal));
      weights.add(5);
    }

    if (components.isEmpty) return 7.0;

    final totalW = weights.fold(0.0, (a, b) => a + b);
    final sym = components
        .asMap()
        .entries
        .map((e) => e.value * (weights[e.key] / totalW))
        .fold(0.0, (a, b) => a + b);

    return sym.clamp(3.0, 9.5);
  }

  /// Final attractiveness score based 100% on symmetry
  double calculateSymmetryBasedAttractiveness({
    FaceRatioData? symmetryData,
    Map<String, dynamic>? symmetryJson,
  }) {
    FaceRatioData? data = symmetryData;
    if (data == null && symmetryJson != null) {
      try {
        data = FaceRatioData.fromMap(symmetryJson);
      } catch (_) {}
    }

    return calculateSymmetryScoreFromFaceData(data);
  }

  // ---------------------------------------------------------------

  List<Map<String, dynamic>> extractSkinSummaries(dynamic gradioResult) {
    try {
      final List<dynamic> outputs = List.from(gradioResult['data']);
      if (outputs.isEmpty) {
        return [];
      }
      return outputs
          .where((o) => o['analysis'] != null)
          .map<Map<String, dynamic>>((result) {
        // Calculate attractiveness based 100% on symmetry
        final attractivenessScore = calculateSymmetryBasedAttractiveness(
          symmetryJson: widget.faceRatioJson,
        );

        return {
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

  @override
  Widget build(BuildContext context) {
    final summaries = extractSkinSummaries(widget.gradioResult);
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogout) {
          if (ModalRoute.of(context)?.isCurrent == true) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.onboard,
              (route) => false,
            );
          }
        }
      },
      child: Scaffold(
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
                    final imageUrl = summary['imageUrl'] as String?;
                    final attractivenessScore =
                        summary['attractivenessScore'] as double;

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
                                                    label: "Attractiveness");
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
                                                          "You're in the top 20% of people!",
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
                                                          key: ValueKey("good"),
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            const Icon(
                                                                Icons.thumb_up,
                                                                color: Colors
                                                                    .green,
                                                                size: 24),
                                                            const SizedBox(
                                                                width: 6),
                                                            const Text(
                                                              "You're in the top 20% of people!",
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
                                                "Your Attractiveness Index is calculated using facial symmetry and golden ratio standards.",
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
                                            const SizedBox(height: 12),
                                            if (widget.faceRatioJson !=
                                                null) ...[
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 8.0),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(.65),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            18),
                                                  ),
                                                  child: Text(
                                                    "Facial Ratio ($_currentAspectLabel)",
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Builder(
                                                builder: (_) {
                                                  try {
                                                    final data = FaceRatioData
                                                        .fromMap(widget
                                                            .faceRatioJson!);
                                                    return Column(
                                                      children: [
                                                        FaceRatioPrettyCard(
                                                          data: data,
                                                          onModeChanged:
                                                              _onAspectModeChanged,
                                                        ),
                                                      ],
                                                    );
                                                  } catch (e) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                },
                                              ),
                                            ] else if (imageUrl != null &&
                                                imageUrl.isNotEmpty) ...[
                                              FutureBuilder<FaceRatioData?>(
                                                future: FaceRatioApi()
                                                    .analyzeByImageUrl(imageUrl,
                                                        draw: false),
                                                builder: (context, snap) {
                                                  if (snap.connectionState ==
                                                      ConnectionState.waiting) {
                                                    return const Padding(
                                                      padding: EdgeInsets.only(
                                                          top: 12),
                                                      child: SizedBox(
                                                        height: 36,
                                                        child: Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2)),
                                                      ),
                                                    );
                                                  }
                                                  if (!snap.hasData ||
                                                      snap.data == null) {
                                                    return const SizedBox
                                                        .shrink();
                                                  }
                                                  return Column(
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 8.0),
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      12,
                                                                  vertical: 6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    .65),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        18),
                                                          ),
                                                          child: Text(
                                                            "Facial Ratio ($_currentAspectLabel)",
                                                            style:
                                                                const TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      FaceRatioPrettyCard(
                                                        data: snap.data!,
                                                        onModeChanged:
                                                            _onAspectModeChanged,
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
                                        color: Colors.yellow.shade700,
                                        width: 1),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Disclaimer",
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "• The Attractiveness Index and face/skin analysis provided by this application are AI-generated estimates for informational and entertainment purposes only.\n\n"
                                              "• Results do not represent a medical diagnosis, dermatological assessment, or professional beauty advice.\n\n"
                                              "• Factors such as lighting, camera quality, and environmental conditions may influence the outcome.\n\n"
                                              "• Users should not rely solely on this analysis for making decisions regarding skincare, medical treatments, or personal wellbeing.\n\n"
                                              "• For any medical or cosmetic concerns, please consult a qualified healthcare or skincare professional.\n\n"
                                              "• The Service Provider makes no guarantees regarding accuracy, completeness, or suitability of the AI analysis.",
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Divider(height: 24),
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
                                            Text(
                                              "Have a coupon?",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .secondary,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: TextField(
                                                    controller:
                                                        _couponController,
                                                    enabled: !_couponApplied,
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          "Enter coupon code",
                                                      hintStyle: TextStyle(
                                                          color:
                                                              Colors.white54),
                                                      filled: true,
                                                      fillColor: Colors.black,
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        borderSide: BorderSide(
                                                            color: Colors
                                                                .deepPurple
                                                                .shade200),
                                                      ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                        borderSide: BorderSide(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary),
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        _couponApplied
                                                            ? Colors.green
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .primary,
                                                    foregroundColor:
                                                        Colors.white,
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
                                                  : "Reveal your skin's secrets with our in-depth analysis — just ₹499",
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
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary,
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
                            ],
                          ),
                        ));
                  },
                ),
              ),
      ),
    );
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
}
