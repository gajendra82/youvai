import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: const Icon(Icons.home_max_outlined),
            onPressed: () => onItemSelected(0),
            color: selectedIndex == 0 ? const Color(0xFF7C6CC6) : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => onItemSelected(1),
            color: selectedIndex == 1 ? const Color(0xFF7C6CC6) : Colors.grey,
          ),
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selectedIndex == 2 ? const Color(0xFF7C6CC6) : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 6),
            ),
            child: IconButton(
              icon: const Icon(Icons.camera, color: Colors.white, size: 28),
              onPressed: () => onItemSelected(2),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => onItemSelected(3),
            color: selectedIndex == 3 ? const Color(0xFF7C6CC6) : Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            onPressed: () => onItemSelected(4),
            color: selectedIndex == 4 ? const Color(0xFF7C6CC6) : Colors.grey,
          ),
        ],
      ),
    );
  }
}