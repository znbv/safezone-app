import 'package:flutter/material.dart';
import 'app_bottom_nav.dart';
import 'home_screen.dart';
import 'devices_screen.dart';
import 'live_monitoring_screen.dart';

class AlertsHistoryScreen extends StatelessWidget {
  const AlertsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final todayAlerts = [
      {
        'title': 'Danger Detected',
        'device': 'Living Room Monitor',
        'status': 'ACTIVE',
        'time': '11:00 AM',
      },
      {
        'title': 'Danger Detected',
        'device': 'Living Room Monitor',
        'status': 'RESOLVED',
        'time': '9:00 AM',
      },
    ];

    final yesterdayAlerts = [
      {
        'title': 'Danger Detected',
        'device': 'Living Room Monitor',
        'status': 'RESOLVED',
        'time': '6:00 PM',
      },
    ];

    final earlierAlerts = [
      {
        'title': 'Danger Detected',
        'device': 'Bed Room Monitor',
        'status': 'RESOLVED',
        'time': '1:00 PM',
      },
      {
        'title': 'Danger Detected',
        'device': 'Living Room Monitor',
        'status': 'RESOLVED',
        'time': '1:00 PM',
      },
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
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
              SizedBox(height: h * 0.02),

              Center(
                child: Text(
                  'ALERT HISTORY',
                  style: TextStyle(
                    color: const Color(0xFFCD6B94),
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              SizedBox(height: h * 0.02),

              _buildSearchField(),

              SizedBox(height: h * 0.025),

              Expanded(
                child: ListView(
                  children: [
                    _buildSectionTitle('TODAY'),
                    const SizedBox(height: 10),
                    ...todayAlerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAlertCard(
                            title: alert['title']!,
                            device: alert['device']!,
                            status: alert['status']!,
                            time: alert['time']!,
                          ),
                        )),

                    const SizedBox(height: 10),
                    _buildSectionTitle('YESTERDAY'),
                    const SizedBox(height: 10),
                    ...yesterdayAlerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAlertCard(
                            title: alert['title']!,
                            device: alert['device']!,
                            status: alert['status']!,
                            time: alert['time']!,
                          ),
                        )),

                    const SizedBox(height: 10),
                    _buildSectionTitle('EARLIER'),
                    const SizedBox(height: 10),
                    ...earlierAlerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAlertCard(
                            title: alert['title']!,
                            device: alert['device']!,
                            status: alert['status']!,
                            time: alert['time']!,
                          ),
                        )),
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

  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: Icon(
          Icons.cancel,
          size: 18,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF38B6FF),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFACAEBE),
        fontSize: 13,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.6,
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String device,
    required String status,
    required String time,
  }) {
    final bool isActive = status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFFFE4EC),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.pink.shade300,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF222741),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  device,
                  style: const TextStyle(
                    color: Color(0xFF222741),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: TextStyle(
                    color: isActive ? Colors.red : Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    color: Color(0xFFACAEBE),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LiveMonitoringScreen()),
      );
    } else if (index == 2) {
      return;
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DevicesScreen()),
      );
    }
  }
}