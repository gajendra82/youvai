import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/doctor_bookappoitment.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        gradient:  LinearGradient(
          colors: [
            Theme.of(context).primaryColor, // Primary color
            Theme.of(context).primaryColor, // Primary color

            Theme.of(context).colorScheme.secondary, // Soft purple
            Theme.of(context).colorScheme.secondary, // Soft purple
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Person Icon (replace image with icon)
          Center(
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Dr. Leah\nZane",
            style: TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Dermatology\nSpecialist",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              const Text(
                "5.0",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 3),
              const Text(
                "(1,952)",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
            ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF9575CD),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              ),
              padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorAppointmentPage(),
                ),
              );
            },
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 14,
              child: const Icon(Icons.calendar_month,
                size: 16, color: Color(0xFF9575CD)),
            ),
            label: const Text(
              "Booking",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            ),
        ],
      ),
    );
  }
}
