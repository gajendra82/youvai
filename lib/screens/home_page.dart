import 'package:flutter/material.dart';
import 'package:skin_assessment/screens/appointment.dart';
import 'package:skin_assessment/screens/chat_page.dart';
import 'package:skin_assessment/screens/dashboard.dart';
import 'package:skin_assessment/screens/camera_tab.dart';
import 'package:skin_assessment/widgets/custom_bottom_navbar.dart';
// Add your other screen imports here

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    BookAppointmentPage(),
    CameraTabScreen(),
    Center(child: Text('Analytics')),
    ChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // The main content, scrollable
          Positioned.fill(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          // Bottom Navigation Bar (overlay, always visible)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: false,
              child: CustomBottomNavBar(
                selectedIndex: _selectedIndex,
                onItemSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
