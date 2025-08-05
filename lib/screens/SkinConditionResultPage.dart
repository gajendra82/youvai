import 'dart:convert';
import 'dart:js' as js;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_web/razorpay_web.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skin_assessment/utils/app_routes.dart';
import 'package:skin_assessment/widgets/doctor_card.dart';
import 'package:http/http.dart' as http;
import 'package:skin_assessment/widgets/CustomSpiderChart.dart'; // <-- Import your spider chart

class SkinConditionResultPage extends StatefulWidget {
  final Map<String, dynamic> gradioResult;
  final Map<String, dynamic>? patchJson;

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
  String paymentStatus = "";

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
  }

  void checkSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isSubscribed = prefs.getBool('isSubscribe') ?? false;
    setState(() {
      _hasPaid = isSubscribed;
    });
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
    js.context.callMethod('openRazorpayCheckout', [
      "rzp_live_jBXpBOtKrydrbs",
      "rzp_live_jBXpBOtKrydrbs",
      "49900",
    ]);
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text("Payment failed or cancelled. Please try again.")),
    );
  }

  List<Map<String, dynamic>> extractSkinSummaries(
      dynamic gradioResult, dynamic patchJson) {
    try {
      print("Gradio Result page: $gradioResult");
      final List<dynamic> outputs = List.from(gradioResult['data']);
      print("Outputs: $outputs");
      if (outputs.isEmpty) {
        print("No skin condition data found.");
        return [];
      }
      // patchJson is ignored here for simplicity, add your patchStats logic if needed
      return outputs
          .where((o) => o['analysis'] != null)
          .map<Map<String, dynamic>>((result) {
        String analysis = jsonEncode(result['analysis']);
        List<Map<String, String>> percentages = [];
        if (analysis.trim().startsWith('[')) {
          try {
            final decoded = json.decode(analysis);
            if (decoded is List) {
              for (var item in decoded) {
                final lines = item.toString().split(RegExp(r'[,\n]'));
                for (var line in lines) {
                  final match =
                      RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
                  if (match != null) {
                    final condition = match.group(1)!.trim();
                    percentages.add(
                        {'condition': condition, 'percent': match.group(2)!});
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
                percentages
                    .add({'condition': condition, 'percent': match.group(2)!});
              }
            }
          }
        } else {
          for (var line in analysis.split('\n')) {
            final match =
                RegExp(r'([A-Za-z ]+)[(:]\s*([\d.]+)%').firstMatch(line);
            if (match != null) {
              final condition = match.group(1)!.trim();
              percentages
                  .add({'condition': condition, 'percent': match.group(2)!});
            }
          }
        }

        // String output = result['output'];
        // String mainDiagnosis = '';
        // final diagnosisRegex = RegExp(
        //     r'Initial Diagnosis[:\s]*([\s\S]*?)(\n\n|$)',
        //     caseSensitive: false);
        // final diagnosisMatch = diagnosisRegex.firstMatch(output);
        // if (diagnosisMatch != null) {
        //   mainDiagnosis = diagnosisMatch.group(1)!.trim();
        // } else {
        //   mainDiagnosis = output.split('\n').first.trim();
        // }

        // String recommendations = '';
        // final recRegex =
        //     RegExp(r'Recommended Medicines[:\s]*([\s\S]*)', caseSensitive: false);
        // final recMatch = recRegex.firstMatch(output);
        // if (recMatch != null) {
        //   recommendations = recMatch.group(1)!.trim();
        // } else {
        //   recommendations = output.trim();
        // }

        return {
          'percentages': percentages,
          'mainDiagnosis': "mainDiagnosis",
          'recommendations': "recommendations",
          'fullOutput': "output",
          'assessment': '', // not used here
          'scoreOutOf10': 0.0, // not used here
          'primaryCondition': '',
          'imageUrl': result['url'],
          'attractivenessScore': 0.0, // not used here
        };
      }).toList();
    } catch (e) {
      print("Error extracting skin summaries: $e");
      return [];
    }
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
    if (cond.contains('skin redness')) return Icons.warning;
    return Icons.info_outline;
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
    if (cond.contains('skin redness')) return 20;
    return 20;
  }

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
      onTap: () {},
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
              backgroundColor: (color ?? Colors.grey).withOpacity(0.15),
              child: Icon(icon ?? Icons.info_outline,
                  color: color ?? Colors.grey, size: 22),
              radius: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    final summaries =
        extractSkinSummaries(widget.gradioResult, widget.patchJson);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Skin Analysis Results',
          style: TextStyle(
            fontFamily: 'SansSerif',
          ),
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
                  final mainDiagnosis = summary['mainDiagnosis'] as String;
                  final fullOutput = summary['fullOutput'] as String;

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
                    "skin redness": 20.0,
                    "eye pouch": 20.0,
                    "nasolabial fold": 20.0,
                    "pigmentation": 20.0,
                  };

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
                            const SizedBox(height: 24),
                            CustomSpiderChart(
                              data: chartData,
                              averageMap: averageMap,
                              chartRadius: 120.0,
                              tickCount: 5,
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
                            const SizedBox(height: 20),
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
                                      margin: const EdgeInsets.only(right: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
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
                                  ],
                                ),
                              ),
                            const Divider(height: 24),
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
                                      // Celebration animation and congratulation message
                                      Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                                      child: Column(
                                        children: [
                                        // You can use a Lottie animation for celebration if you have the package and asset
                                        // Example:
                                        // Lottie.asset('assets/celebration.json', height: 120),
                                        Icon(Icons.emoji_events, color: Colors.amber, size: 60),
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
                                SizedBox(
                                  height: 300,
                                  child: ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(right: 16),
                                    scrollDirection: Axis.horizontal,
                                    itemCount: doctorList.length,
                                    itemBuilder: (context, index) {
                                      final doctor = doctorList[index];
                                      return DoctorCard(
                                        title: doctor["name"],
                                        speciality:
                                            doctor["speciality"].toString(),
                                        stars: doctor["reviewStars"].toString(),
                                        totalReviews:
                                            doctor["totalReviews"].toString(),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
