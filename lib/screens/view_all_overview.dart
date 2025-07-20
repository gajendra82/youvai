import 'package:flutter/material.dart';

class SkinOverviewPage extends StatelessWidget {
  const SkinOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          "Results",
          style: TextStyle(
            color: Color(0xFF22223B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(
                  child: Text(
                    "The analysis of your skin is complete ✅",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Color(0xFF22223B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Analysis Grid
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.8,
                children: const [
                  _SkinAnalysisStat(
                    icon: Icons.water_drop_outlined,
                    label: "Moisture Level",
                    value: 76,
                    color: Color(0xFF4FC3F7),
                  ),
                  _SkinAnalysisStat(
                    icon: Icons.eco_outlined,
                    label: "Firmness",
                    value: 87,
                    color: Color(0xFF43A047),
                  ),
                  _SkinAnalysisStat(
                    icon: Icons.spa_outlined,
                    label: "Texture",
                    value: 58,
                    color: Color(0xFFFFB74D),
                  ),
                  _SkinAnalysisStat(
                    icon: Icons.blur_on_outlined,
                    label: "Pore visibility",
                    value: 63,
                    color: Color(0xFFAB47BC),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Personalized Recommendations
            const Text(
              "Personalized recommendations:",
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF22223B)),
            ),
            const SizedBox(height: 10),
            // Category Tabs
            Row(
              children: [
                _RecoTab(label: "All", selected: true),
                _RecoTab(label: "Skincare"),
                _RecoTab(label: "Makeup"),
              ],
            ),
            const SizedBox(height: 18),

            // Attractive Recommendation Card
            Row(
              children: [
                // Left image card
                Expanded(
                  child: Container(
                    height: 160,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: const DecorationImage(
                        image: AssetImage('assets/fruit_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                // Center main recommendation card with play button and guide
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          image: const DecorationImage(
                            image: AssetImage('assets/skin_face_sample.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withOpacity(0.85),
                          child: Icon(Icons.play_arrow_rounded,
                              color: Colors.black87, size: 28),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.86),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Guide to properly washing your face:",
                            style: TextStyle(
                                color: Color(0xFF22223B),
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Right image card (e.g., product)
                Expanded(
                  child: Container(
                    height: 160,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: const DecorationImage(
                        image: AssetImage('assets/product_bg.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // More Personal Recommendation Text
            const Text(
              "✨ Your skin is unique! Try to use gentle, hydrating products and avoid harsh scrubs. If you want glowing results, drink plenty of water and use sunscreen every day. For custom tips, explore your skincare analysis below.",
              style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF484848),
                  fontWeight: FontWeight.w500,
                  height: 1.5),
            ),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _SkinAnalysisStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _SkinAnalysisStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(7.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: const Color(0xFFF8F7FA),
        ),
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "$value%",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      _CircleProgressBar(percent: value / 100, color: color),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleProgressBar extends StatelessWidget {
  final double percent;
  final Color color;
  const _CircleProgressBar({required this.percent, required this.color});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percent,
            strokeWidth: 4,
            backgroundColor: color.withOpacity(0.16),
            color: color,
          ),
        ],
      ),
    );
  }
}

class _RecoTab extends StatelessWidget {
  final String label;
  final bool selected;
  const _RecoTab({required this.label, this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
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
}