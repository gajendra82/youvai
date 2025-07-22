import 'package:flutter/material.dart';
import 'package:skin_assessment/widgets/expandeble_text.dart';

class DoctorAppointmentPage extends StatelessWidget {
  const DoctorAppointmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8F5FE8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {},
          child: const Text(
            "Book Appointment",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Doctors",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card at the top
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF9575CD), // Darker purple
                    Color(0xFF9575CD), // Darker purple
                    Color(0xFFB39DDB), // Soft purple
                    Color.fromARGB(255, 213, 207, 224), // Soft purple
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              padding: const EdgeInsets.all(30),
              child: Row(
                children: [
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Dr. Leah Zane",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Dermatology Specialist",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: Colors.white70, size: 16),
                            const SizedBox(width: 3),
                            const Text(
                              "Mumbai, India",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 3),
                            const Text(
                              "5.0",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoTag(label: "150\nReviews"),
                            const SizedBox(width: 6),
                            _InfoTag(label: "10\nYears exp."),
                            const SizedBox(width: 6),
                            _InfoTag(label: "1550\nPatients"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Person Icon
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person,
                        size: 55, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Demography
            const Text(
              "Demography",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ExpandableRichText(
                fullText:
                    "Dr. Leah Zane is a 38-year-old female dermatologist with over 10 years of clinical experience in the field. She holds a medical degree from a prestigious university and completed her specialization in derm..."),

            const SizedBox(height: 24),

            // Schedules
            const Text(
              "Schedules",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 55,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _ScheduleDay(isSelected: true, day: "Mon", date: "11"),
                  _ScheduleDay(isSelected: false, day: "Tue", date: "12"),
                  _ScheduleDay(isSelected: false, day: "Wed", date: "13"),
                  _ScheduleDay(isSelected: false, day: "Thu", date: "14"),
                  _ScheduleDay(isSelected: false, day: "Fri", date: "15"),
                  _ScheduleDay(isSelected: false, day: "Sat", date: "16"),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Choose time
            const Text(
              "Choose time",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.7,
              children: [
                _TimeChip(label: "09.00 am"),
                _TimeChip(label: "10.00 am"),
                _TimeChip(label: "11.00 am"),
                _TimeChip(label: "12.00 pm"),
                _TimeChip(label: "02.00 pm"),
                _TimeChip(label: "03.00 pm"),
              ],
            ),
            const SizedBox(height: 30),

            // Book appointment button

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  final String label;
  const _InfoTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      // width: 62,
      // height: 44,
      alignment: Alignment.center,
      padding: EdgeInsets.all(17),
      decoration: BoxDecoration(
        // color: Colors.white24,
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF8F5FE8),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          height: 1.3,
        ),
      ),
    );
  }
}

class _ScheduleDay extends StatelessWidget {
  final bool isSelected;
  final String day;
  final String date;
  const _ScheduleDay(
      {required this.isSelected, required this.day, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF8F5FE8) : const Color(0xFFEAEAF1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            day,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            date,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  const _TimeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F0F7),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
            color: Color(0xFF8F5FE8),
            fontWeight: FontWeight.bold,
            fontSize: 13),
      ),
    );
  }
}
