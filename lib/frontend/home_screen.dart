import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_bottom_nav.dart';
import 'devices_screen.dart';
import 'live_monitoring_screen.dart';
import 'alerts_history_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = false;

  String? _result;
  String? _hazardImageBase64;
  String? _alertReason;
  String? _alertStatus;
  String? _riskLevel;
  String? _detectedHazardName;

  String? _childAction;
  String? _childActionType;
  double? _childActionConfidence;

  final ImagePicker _picker = ImagePicker();

  final PageController _homeMonitorController = PageController();
  int _homeMonitorIndex = 0;

  final List<Map<String, String>> _homeMonitors = [
    {
      'title': 'Living Room Monitor',
      'status': 'No hazards detected',
      'image': 'assets/images/video_stream.jpg',
    },
    {
      'title': 'Bedroom Monitor',
      'status': 'No hazards detected',
      'image': 'assets/images/bedroom_stream.png',
    },
    {
      'title': 'Playroom Monitor',
      'status': 'No hazards detected',
      'image': 'assets/images/playroom_stream.png',
    },
  ];

  @override
  void dispose() {
    _homeMonitorController.dispose();
    super.dispose();
  }

  Future<void> pickVideoAndAnalyze() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.gallery,
    );

    if (video == null) return;

    setState(() {
      _loading = true;
      _result = null;
      _hazardImageBase64 = null;
      _alertReason = null;
      _alertStatus = null;
      _riskLevel = null;
      _detectedHazardName = null;

      _childAction = null;
      _childActionType = null;
      _childActionConfidence = null;
    });

    try {
      var request = http.MultipartRequest(
        "POST",
        Uri.parse("http://192.168.100.7:5000/analyze"),
      );

      request.files.add(
        await http.MultipartFile.fromPath("video", video.path),
      );

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      final data = jsonDecode(responseData.body);

      setState(() {
        _result = data.toString();
        _hazardImageBase64 = data['hazard_image_base64'];

        final decision = data['final_decision'];
        if (decision != null) {
          _alertStatus = decision['final_status'];
          _alertReason = decision['reason'];
          _riskLevel = decision['risk_level'];
        }

        final hazardDetection = data['hazard_detection'];
        if (hazardDetection != null &&
            hazardDetection['hazard_detected'] == true) {
          final hazards = hazardDetection['detected_hazards'] as List?;
          if (hazards != null && hazards.isNotEmpty) {
            _detectedHazardName = hazards[0]['object'];
          }
        }

        final childact = data['childact'];
        if (childact != null) {
          _childAction = childact['prediction'];
          _childActionType = childact['likely_action_type'];

          final conf = childact['confidence'];
          if (conf != null) {
            _childActionConfidence = double.tryParse(conf.toString());
          }
        }
      });

      await _showRealAlertNotification();
      await _saveAlertToFirestore();
    } catch (e) {
      setState(() {
        _result = "Error: $e";
      });
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _showRealAlertNotification() async {
    final status = (_alertStatus ?? '').trim().toUpperCase();

    print("NOTIFICATION CHECK STATUS: $status");
    print("NOTIFICATION HAZARD OBJECT: $_detectedHazardName");

    if (status == 'ALERT') {
      await NotificationService.showHazardNotification(
        title: 'Danger Detected',
        body: _detectedHazardName != null && _detectedHazardName!.isNotEmpty
            ? 'Hazardous object detected in a child scene: $_detectedHazardName.'
            : (_alertReason ?? 'A hazardous situation was detected.'),
      );
    } else if (status == 'MONITOR') {
      await NotificationService.showHazardNotification(
        title: 'Monitor Warning',
        body: _alertReason ?? 'Possible unsafe condition detected.',
      );
    }
  }

  Future<void> _saveAlertToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    final status = (_alertStatus ?? '').trim().toUpperCase();

    if (user == null || status.isEmpty) return;

    if (status == 'NO ALERT' || status == 'WAIT') return;

    await FirebaseFirestore.instance
        .collection('alerts')
        .doc(user.uid)
        .collection('userAlerts')
        .add({
      'title': status == 'ALERT' ? 'Danger Detected' : 'Monitor Warning',
      'reason': _alertReason ?? '',
      'status': 'ACTIVE',
      'riskLevel': _riskLevel ?? '',
      'hazardObject': _detectedHazardName ?? '',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

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
              SizedBox(height: h * 0.025),

              Center(
                child: ElevatedButton(
                  onPressed: _loading ? null : pickVideoAndAnalyze,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Select Video & Analyze",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              SizedBox(height: h * 0.025),

              if (_alertStatus != null) _buildResultCard(w),

              SizedBox(height: h * 0.03),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonitorCard(double w, double h) {
    return SizedBox(
      width: double.infinity,
      height: h * 0.45,
      child: PageView.builder(
        controller: _homeMonitorController,
        itemCount: _homeMonitors.length,
        onPageChanged: (index) {
          setState(() {
            _homeMonitorIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final monitor = _homeMonitors[index];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    monitor['image']!,
                    fit: BoxFit.cover,
                  ),

                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.05),
                            Colors.black.withOpacity(0.35),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 14,
                    right: 14,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LiveMonitoringScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.open_in_full,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),

                  if (_homeMonitorIndex > 0)
                    Positioned(
                      left: 8,
                      top: h * 0.18,
                      child: GestureDetector(
                        onTap: () {
                          _homeMonitorController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                  if (_homeMonitorIndex < _homeMonitors.length - 1)
                    Positioned(
                      right: 8,
                      top: h * 0.18,
                      child: GestureDetector(
                        onTap: () {
                          _homeMonitorController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.35),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 28,
                          ),
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
                        color: Colors.black.withOpacity(0.48),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  monitor['title']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
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
                          Text(
                            monitor['status']!,
                            style: const TextStyle(
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
        },
      ),
    );
  }

  Widget _buildResultCard(double w) {
    Color cardColor;
    IconData cardIcon;
    String statusTitle;

    switch (_riskLevel) {
      case 'High':
        cardColor = const Color(0xFFE53935);
        cardIcon = Icons.warning_amber_rounded;
        statusTitle = 'Danger Detected';
        break;
      case 'Medium':
        cardColor = const Color(0xFFFF9800);
        cardIcon = Icons.visibility_outlined;
        statusTitle = 'Monitor Warning';
        break;
      case 'Low':
        cardColor = const Color(0xFF38B6FF);
        cardIcon = Icons.check_circle_outline;
        statusTitle = 'Safe Condition';
        break;
      default:
        cardColor = Colors.grey;
        cardIcon = Icons.info_outline;
        statusTitle = _alertStatus ?? 'Analysis Result';
    }

    String hazardName =
        _detectedHazardName != null && _detectedHazardName!.isNotEmpty
            ? '${_detectedHazardName![0].toUpperCase()}${_detectedHazardName!.substring(1)}'
            : 'Not detected';

    String proximity = 'Unknown';

    if (_alertReason != null && _alertReason!.contains('Proximity:')) {
      proximity = _alertReason!
          .split('Proximity:')
          .last
          .replaceAll('.', '')
          .trim();
    }

    final confidencePercent = _childActionConfidence != null
        ? '${(_childActionConfidence! * 100).toStringAsFixed(2)}%'
        : 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hazardImageBase64 != null && _detectedHazardName != null) ...[
          const SizedBox(height: 14),
          Text(
            'Detected Hazard',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.memory(
                  base64Decode(_hazardImageBase64!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.70),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    child: Text(
                      '$hazardName detected',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: cardColor.withOpacity(0.45),
              width: 1.4,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: cardColor.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      cardIcon,
                      color: cardColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusTitle,
                          style: TextStyle(
                            color: cardColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_alertStatus ?? 'Result'} · ${_riskLevel ?? 'Unknown'} Risk',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Divider(
                color: Colors.grey.shade200,
                thickness: 1,
              ),

              const SizedBox(height: 10),

              _resultRow(
                icon: Icons.dangerous_outlined,
                label: 'Hazard Object',
                value: hazardName,
              ),

              const SizedBox(height: 8),

              _resultRow(
                icon: Icons.social_distance_outlined,
                label: 'Object Proximity',
                value: proximity,
              ),

              const SizedBox(height: 8),

              _resultRow(
                icon: Icons.pan_tool_alt_outlined,
                label: 'Detected Gesture',
                value: _childAction ?? 'Not detected',
              ),

              const SizedBox(height: 8),

              _resultRow(
                icon: Icons.accessibility_new_outlined,
                label: 'Action Type',
                value: _childActionType ?? 'Unknown',
              ),

              const SizedBox(height: 8),

              _resultRow(
                icon: Icons.analytics_outlined,
                label: 'Action Confidence',
                value: confidencePercent,
              ),

              const SizedBox(height: 8),

              _resultRow(
                icon: Icons.notifications_active_outlined,
                label: 'Recommended Action',
                value: _alertStatus == 'ALERT'
                    ? 'Send alert immediately'
                    : _alertStatus == 'MONITOR'
                        ? 'Continue monitoring'
                        : 'No action required',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

    if (!mounted) return;

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
        Expanded(
          child: Text(
            'Hi, ${FirebaseAuth.instance.currentUser?.displayName ?? 'User'} 👋',
            style: TextStyle(
              fontSize: w * 0.07,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
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

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _homeMonitors.length,
        (index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: _dot(active: index == _homeMonitorIndex),
        ),
      ),
    );
  }

  Widget _dot({required bool active}) {
    return Container(
      width: active ? 8 : 6,
      height: active ? 8 : 6,
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.grey.shade400,
        shape: BoxShape.circle,
      ),
    );
  }
}