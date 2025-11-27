import 'package:flutter/material.dart';

class BookAppointmentPage extends StatefulWidget {
  const BookAppointmentPage({super.key});

  @override
  State<BookAppointmentPage> createState() => _BookAppointmentPageState();
}

class _BookAppointmentPageState extends State<BookAppointmentPage> {
  int selectedDoctorIdx = 0;
  int selectedDateIdx = 2;
  int selectedTimeIdx = 2;

  final List<Map<String, String>> doctors = [
    {
      "name": "Dr. Jenny Gray",
      "specialty": "Cosmetic Dermatologist",
    },
    {
      "name": "Dr. Anna Rose",
      "specialty": "Aesthetic Physician",
    },
    {
      "name": "Dr. Sam Reed",
      "specialty": "Dermatology Expert",
    },
    {
      "name": "Dr. Priya Desai",
      "specialty": "Skin Specialist",
    },
  ];

  final List<Map<String, String>> weekDates = [
    {"label": "MON", "date": "16"},
    {"label": "TUE", "date": "17"},
    {"label": "WED", "date": "18"},
    {"label": "THU", "date": "19"},
    {"label": "FRI", "date": "20"},
    {"label": "SAT", "date": "21"},
  ];

  final List<String> timeSlots = [
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "12:00 PM",
    "12:30 PM",
    "01:00 PM",
    "01:30 PM",
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;
    final double sheetRadius = isWide ? 54 : 32;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWide ? 500 : double.infinity,
          ),
          child: Column(
            children: [
              // Top App Bar
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.black87),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          "Consultant Detail",
                          style: TextStyle(
                              color: Color(0xFF232336),
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                      Icon(Icons.more_vert, color: Colors.black54),
                    ],
                  ),
                ),
              ),

              // Doctor selection
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isWide ? 40 : 18,
                  vertical: isWide ? 16 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Doctor",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF232336),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: List.generate(doctors.length, (i) {
                        final selected = selectedDoctorIdx == i;
                        return ChoiceChip(
                          label: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctors[i]["name"]!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: selected
                                      ? Colors.white
                                      : const Color(0xFF232336),
                                ),
                              ),
                              Text(
                                doctors[i]["specialty"]!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected
                                      ? Colors.white70
                                      : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => selectedDoctorIdx = i);
                          },
                          selectedColor: const Color(0xFF7C6CC6),
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          labelPadding: EdgeInsets.zero,
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // Appointment Bottom Sheet (fixed to bottom)
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(sheetRadius)),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 18,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(
                        isWide ? 38 : 18, 22, isWide ? 38 : 18, isWide ? 40 : 26),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Date selector
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Select Date & Time",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                  color: Color(0xFF232336)),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 66,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(weekDates.length, (i) {
                                final selected = selectedDateIdx == i;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedDateIdx = i);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    width: 54,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF7C6CC6)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          weekDates[i]["label"]!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selected
                                                ? Colors.white
                                                : const Color(0xFF92929D),
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          weekDates[i]["date"]!,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: selected
                                                ? Colors.white
                                                : const Color(0xFF232336),
                                            fontSize: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // Time slots
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              alignment: WrapAlignment.center,
                              children: List.generate(timeSlots.length, (i) {
                                final selected = selectedTimeIdx == i;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => selectedTimeIdx = i);
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? const Color(0xFF7C6CC6)
                                          : Colors.white,
                                      border: Border.all(
                                        color: selected
                                            ? const Color(0xFF7C6CC6)
                                            : const Color(0xFFEEEAFE),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(13),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 12),
                                    child: Text(
                                      timeSlots[i],
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : const Color(0xFF232336),
                                        fontWeight: FontWeight.w600,
                                        fontSize: isWide ? 17 : 15,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Make Appointment Button (a bit higher for visual balance)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // Add appointment booking logic here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Appointment booked with ${doctors[selectedDoctorIdx]["name"]} on ${weekDates[selectedDateIdx]["label"]}, ${weekDates[selectedDateIdx]["date"]} at ${timeSlots[selectedTimeIdx]}.",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    backgroundColor: const Color(0xFF7C6CC6),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF232336),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                    vertical: isWide ? 22 : 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWide ? 19 : 17),
                              ),
                              child: const Text("Make appointment"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}