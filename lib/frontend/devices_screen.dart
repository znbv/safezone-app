import 'package:flutter/material.dart';
import 'app_bottom_nav.dart';
import 'home_screen.dart';
import 'live_monitoring_screen.dart';
import 'alerts_history_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final devices = [
      {'name': 'Living Room Monitor', 'code': 'LDRY3152'},
      {'name': 'Kitchen Monitor', 'code': 'DNH6859'},
      {'name': "Yara's Bedroom Monitor", 'code': 'EBOY1952'},
      {'name': "Saad's Bedroom Monitor", 'code': 'DNH6859'},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
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
                  'DEVICES',
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
                child: ListView.separated(
                  itemCount: devices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return _buildDeviceCard(
                      name: device['name']!,
                      code: device['code']!,
                    );
                  },
                ),
              ),

              SizedBox(height: h * 0.015),

              Center(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38B6FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Add a new Device',
                      style: TextStyle(fontSize: 13),
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

  Widget _buildDeviceCard({
    required String name,
    required String code,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFBFE8FF),
            child: Icon(
              Icons.wifi_tethering_rounded,
              color: Colors.blue.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Name: $name',
                  style: const TextStyle(
                    color: Color(0xFF222741),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Code: $code',
                  style: const TextStyle(
                    color: Color(0xFFACAEBE),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.edit_outlined, size: 20),
            color: Colors.black87,
            splashRadius: 20,
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.delete_outline, size: 20),
            color: Colors.pink,
            splashRadius: 20,
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AlertsHistoryScreen()),
      );
    } else if (index == 3) {
      return;
    }
  }
}