import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 18),
                // Greeting Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Hello, Jenny",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            "Skin Age, 23 y.o",
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Profile Pic
                    CircleAvatar(
                      radius: 19,
                      backgroundImage: AssetImage("assets/profile_pic.png"),
                    ),
                    const SizedBox(width: 8),
                    // Settings Icon
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[200],
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.settings_outlined),
                        iconSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Track Journey Card
                Container(
                  width: double.infinity,
                  height: 92,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEAFE),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 18, horizontal: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Track Your Journey",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Skin test with help of AI to monitor",
                                style: TextStyle(
                                    fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Example: Placeholder image for Track Journey (excluding blurred face)
                      Padding(
                        padding: const EdgeInsets.only(right: 10, left: 0),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.white,
                          backgroundImage:
                              AssetImage("assets/track_journey.png"),
                        ),
                      ),
                      // Arrow button
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF7C6CC6),
                          radius: 16,
                          child: const Icon(Icons.arrow_forward,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // Care Tracking
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Care Tracking",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "Show All →",
                        style: TextStyle(
                          color: Color(0xFF7C6CC6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _careTrackingItem("Week 1", "😊", true),
                      _careTrackingItem("Week 2", "🙂", true),
                      _careTrackingItem("Week 3", "😍", true),
                      _careTrackingItem("Week 4", "😐", false),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                // AI Recommendation
                const Text(
                  "AI Recommendation",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 98,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _aiRecommendationCard(),
                      const SizedBox(width: 10),
                      // Add more cards if needed
                      _aiRecommendationCard(isSecond: true),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Articles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Articles",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        "View All →",
                        style: TextStyle(
                          color: Color(0xFF7C6CC6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 78,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _articleCard("assets/article1.png"),
                      _articleCard("assets/article2.png"),
                      _articleCard("assets/article3.png"),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _careTrackingItem(String title, String emoji, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        width: 65,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF7F4FF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(11),
          border: active
              ? Border.all(color: const Color(0xFF7C6CC6), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _aiRecommendationCard({bool isSecond = false}) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage(
                isSecond ? "assets/doctor2.png" : "assets/doctor1.png"),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      isSecond ? "Dr. Anna Rose" : "Dr. Jenny Gray",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.verified,
                        color: Color(0xFF7C6CC6), size: 17),
                  ],
                ),
                const Text(
                  "Cosmetic Dermatologist",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Row(
                  children: const [
                    Icon(Icons.star, color: Colors.orange, size: 15),
                    SizedBox(width: 3),
                    Text("4.0",
                        style: TextStyle(fontSize: 12, color: Colors.black87)),
                    SizedBox(width: 3),
                    Text("· 1.2K",
                        style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      margin: const EdgeInsets.only(top: 2, right: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEAFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "SkinSavvy AI Match",
                        style:
                            TextStyle(fontSize: 10, color: Color(0xFF7C6CC6)),
                      ),
                    ),
                    const Text(
                      "99.15%",
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _articleCard(String img) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 90,
          height: 70,
          color: Colors.grey[300],
          child: Image.asset(
            img,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }


}
