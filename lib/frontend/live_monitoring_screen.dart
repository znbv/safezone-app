import 'package:flutter/material.dart';
import 'app_bottom_nav.dart';
import 'home_screen.dart';
import 'alerts_history_screen.dart';
import 'devices_screen.dart';

class LiveMonitoringScreen extends StatelessWidget {
  const LiveMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 1,
        onTap: (index) {
          _handleBottomNav(context, index);
        },
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: w * 0.06,
            vertical: h * 0.03,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: h * 0.03),

              Center(
                child: Text(
                  'Active Devices',
                  style: TextStyle(
                    fontSize: w * 0.075,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),

              SizedBox(height: h * 0.03),

              Expanded(
                child: Column(
                  children: [
                    _buildMonitorCard(w, h),
                    SizedBox(height: h * 0.02),
                    _buildDots(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Image.asset(
          'assets/images/blue_logo.png',
          width: 30,
          height: 30,
        ),
        const SizedBox(width: 8),
        const Text(
          'Safe Zone',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMonitorCard(double w, double h) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: h * 0.62,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Container(
              height: h * 0.58,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/video_stream.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.open_in_full,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.black.withOpacity(0.45),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Living Room Monitor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'No hazards detected',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  void _handleBottomNav(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (index == 1) {
      return;
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
  }
}