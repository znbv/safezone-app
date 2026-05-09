import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_bottom_nav.dart';
import 'devices_screen.dart';
import 'live_monitoring_screen.dart';
import 'alerts_history_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            return;
          } else if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const LiveMonitoringScreen()),
            );
          } else if (index == 2) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AlertsHistoryScreen()),
            );
          } else if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const DevicesScreen()),
            );
          }
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.06,
            vertical: h * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(context, w),
              SizedBox(height: h * 0.03),
              _buildGreeting(context, w),
              SizedBox(height: h * 0.015),
              Align(
                alignment: Alignment.centerRight,
                child: _buildAlertsButton(context),
              ),
              SizedBox(height: h * 0.025),
              _buildMonitorCard(w, h),
              SizedBox(height: h * 0.02),
              _buildDots(),
              SizedBox(height: h * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/images/blue_logo.png',
              width: 30,
              height: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              'Safe Zone',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        GestureDetector(
          onTap: () async {
            await _logout(context);
          },
          child: Icon(
            Icons.logout,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
  Future<void> _logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
      ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Logout successful")),
      );
  }

  Widget _buildGreeting(BuildContext context, double w) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Hi, ${FirebaseAuth.instance.currentUser?.displayName ?? 'User'} 👋',
          style: TextStyle(
            fontSize: w * 0.07,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(),
              ),
            );
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade300,
            child: const Icon(Icons.person, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AlertsHistoryScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF38B6FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'View Alerts',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildMonitorCard(double w, double h) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Container(
            height: h * 0.45,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/video_stream.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        'Living Room Monitor',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.circle, color: Colors.green, size: 15),
                          SizedBox(width: 6),
                          Icon(Icons.open_in_full, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'No hazards detected',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _dot(active: true),
        const SizedBox(width: 6),
        _dot(active: false),
      ],
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }
}