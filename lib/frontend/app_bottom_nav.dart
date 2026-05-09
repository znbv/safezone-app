import 'package:flutter/material.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final navColor = const Color.fromARGB(106, 56, 182, 255); // same blue, slightly transparent

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: navColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem(
            icon: Icons.home_rounded,
            index: 0,
            isActive: currentIndex == 0,
          ),
          _buildItem(
            icon: Icons.wifi_tethering_rounded,
            index: 1,
            isActive: currentIndex == 1,
          ),
          _buildItem(
            icon: Icons.warning_amber_rounded,
            index: 2,
            isActive: currentIndex == 2,
          ),
          _buildItem(
            icon: Icons.add_circle_outline_rounded,
            index: 3,
            isActive: currentIndex == 3,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required int index,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.black87,
            size: 24,
          ),
          const SizedBox(height: 4),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? Colors.red : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}