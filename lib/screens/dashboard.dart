import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 650;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? constraints.maxWidth * 0.15 : 16,
                ),
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
                                  fontSize: 22,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "Skin Age, 23 y.o",
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          radius: 21,
                          backgroundImage: AssetImage("assets/profile_pic.png"),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[200],
                          ),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.settings_outlined),
                            iconSize: 22,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Track Journey Card
                    Container(
                      width: double.infinity,
                      height: isWide ? 120 : 92,
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                          Padding(
                            padding: const EdgeInsets.only(right: 10, left: 0),
                            child: CircleAvatar(
                              radius: isWide ? 44 : 32,
                              backgroundColor: Colors.white,
                              backgroundImage:
                                  AssetImage("assets/track_journey.png"),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: CircleAvatar(
                              backgroundColor: const Color(0xFF7C6CC6),
                              radius: isWide ? 20 : 16,
                              child: const Icon(Icons.arrow_forward,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Skin Health Summary Section
                    const Text(
                      "Skin Health Summary",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        _summaryStat("Moisture", "76%", Icons.water_drop, Colors.blue),
                        _summaryStat("Firmness", "87%", Icons.eco, Colors.green),
                        _summaryStat("Texture", "58%", Icons.spa, Colors.orange),
                        _summaryStat("Pores", "63%", Icons.blur_on, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Care Tracking
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Care Tracking",
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
                      height: 65,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _careTrackingItem("Week 1", "😊", true),
                          _careTrackingItem("Week 2", "🙂", true),
                          _careTrackingItem("Week 3", "😍", true),
                          _careTrackingItem("Week 4", "😐", false),
                          _careTrackingItem("Week 5", "😶", false),
                          _careTrackingItem("Week 6", "😃", false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Personalized Recommendations Section
                    const Text(
                      "Personalized Recommendations",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _recoTab(label: "All", selected: true),
                        _recoTab(label: "Skincare"),
                        _recoTab(label: "Makeup"),
                        _recoTab(label: "Lifestyle"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF5F8),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "✨ Your skin is unique! Use gentle, hydrating products and avoid harsh scrubs. Drink plenty of water, use sunscreen daily, and explore your AI-powered recommendations for best results.",
                        style: TextStyle(fontSize: 14, color: Color(0xFF393939)),
                      ),
                    ),

                    // Your Skin Journey
                    const Text(
                      "Your Skin Journey",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _journeyProgressBar(0.74),
                    ),
                    const SizedBox(height: 2),

                    // AI Recommendations (Doctors)
                    const Text(
                      "AI Recommended Doctors",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: isWide ? 140 : 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _aiRecommendationCard(
                            doctorName: "Dr. Jenny Gray",
                            specialty: "Cosmetic Dermatologist",
                            rating: "4.8",
                            reviews: "2.3K",
                            matchPercent: "99.15%",
                            isFamous: true,
                            img: "assets/doctor1.png",
                          ),
                          const SizedBox(width: 12),
                          _aiRecommendationCard(
                            doctorName: "Dr. Anna Rose",
                            specialty: "Aesthetic Physician",
                            rating: "4.7",
                            reviews: "1.9K",
                            matchPercent: "98.76%",
                            isFamous: true,
                            img: "assets/doctor2.png",
                          ),
                          const SizedBox(width: 12),
                          _aiRecommendationCard(
                            doctorName: "Dr. Sam Reed",
                            specialty: "Dermatology Expert",
                            rating: "4.6",
                            reviews: "1.5K",
                            matchPercent: "97.54%",
                            isFamous: false,
                            img: "assets/doctor3.png",
                          ),
                          const SizedBox(width: 12),
                          _aiRecommendationCard(
                            doctorName: "Dr. Priya Desai",
                            specialty: "Skin Specialist",
                            rating: "4.9",
                            reviews: "3.1K",
                            matchPercent: "99.65%",
                            isFamous: true,
                            img: "assets/doctor4.png",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Recent Checks
                    const Text(
                      "Recent Skin Checks",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _recentCheckCard(
                              context,
                              "18 Jul",
                              "Moisture: 73%",
                              "assets/skin1.png",
                              isWide: isWide),
                          _recentCheckCard(
                              context,
                              "10 Jul",
                              "Moisture: 69%",
                              "assets/skin2.png",
                              isWide: isWide),
                          _recentCheckCard(
                              context,
                              "03 Jul",
                              "Moisture: 80%",
                              "assets/skin3.png",
                              isWide: isWide),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Trending Articles
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Trending Articles",
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
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
                      height: 92,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _articleCard("assets/article1.png"),
                          _articleCard("assets/article2.png"),
                          _articleCard("assets/article3.png"),
                          _articleCard("assets/article4.png"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Daily Routine Tracker
                    const Text(
                      "Daily Routine Tracker",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    const SizedBox(height: 8),
                    _dailyRoutineChecklist(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summaryStat(String label, String value, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
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
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 22),
            radius: 20,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _recoTab({required String label, bool selected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold)),
        selected: selected,
        onSelected: (_) {},
        selectedColor: const Color(0xFF22223B),
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  Widget _journeyProgressBar(double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Progress toward healthy skin",
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8)),
            ),
            Container(
              height: 8,
              width: 260 * value,
              decoration: BoxDecoration(
                  color: const Color(0xFF7C6CC6),
                  borderRadius: BorderRadius.circular(8)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('${(value * 100).toInt()}% completed',
            style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    );
  }

  Widget _careTrackingItem(String title, String emoji, bool active) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: active ? const Color(0xFFF7F4FF) : Colors.grey[200],
          borderRadius: BorderRadius.circular(13),
          border: active
              ? Border.all(color: const Color(0xFF7C6CC6), width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _aiRecommendationCard({
    required String doctorName,
    required String specialty,
    required String rating,
    required String reviews,
    required String matchPercent,
    required bool isFamous,
    required String img,
  }) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 3),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: isFamous
            ? Border.all(color: const Color(0xFF7C6CC6), width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 33,
            backgroundImage: AssetImage(img),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      doctorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(width: 4),
                    if (isFamous)
                      const Icon(Icons.verified,
                          color: Color(0xFF7C6CC6), size: 18),
                  ],
                ),
                Text(
                  specialty,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.orange, size: 15),
                    const SizedBox(width: 3),
                    Text(rating,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                    const SizedBox(width: 3),
                    Text("· $reviews",
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      margin: const EdgeInsets.only(top: 2, right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAEAFF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "AI Match",
                        style:
                            TextStyle(fontSize: 10, color: Color(0xFF7C6CC6)),
                      ),
                    ),
                    Text(
                      matchPercent,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54),
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

  Widget _recentCheckCard(BuildContext context, String date, String summary,
      String img, {required bool isWide}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Container(
        width: isWide ? 120 : 95,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                img,
                height: isWide ? 50 : 34,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 6),
            Text(date,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7C6CC6),
                    fontSize: 13)),
            Text(summary,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }

  Widget _articleCard(String img) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 105,
          height: 82,
          color: Colors.grey[300],
          child: Image.asset(
            img,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _dailyRoutineChecklist() {
    final items = [
      {"label": "Cleansed", "done": true},
      {"label": "Moisturized", "done": false},
      {"label": "SPF Applied", "done": false},
      {"label": "Drank Water", "done": true},
      {"label": "No Touching Face", "done": true},
    ];
    return Column(
      children: items
          .map(
            (item) => Row(
              children: [
                Checkbox(
                  value: item["done"] as bool,
                  onChanged: (_) {},
                  activeColor: const Color(0xFF7C6CC6),
                ),
                Text(
                  item["label"] as String,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}