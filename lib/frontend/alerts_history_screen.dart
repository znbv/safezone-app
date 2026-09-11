import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_bottom_nav.dart';
import 'home_screen.dart';
import 'devices_screen.dart';
import 'live_monitoring_screen.dart';

class AlertsHistoryScreen extends StatefulWidget {
  const AlertsHistoryScreen({super.key});

  @override
  State<AlertsHistoryScreen> createState() => _AlertsHistoryScreenState();
}

class _AlertsHistoryScreenState extends State<AlertsHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matchesSearch(QueryDocumentSnapshot doc) {
    if (_searchText.trim().isEmpty) return true;

    final data = doc.data() as Map<String, dynamic>;

    final title = (data['title'] ?? '').toString().toLowerCase();
    final reason = (data['reason'] ?? '').toString().toLowerCase();
    final riskLevel = (data['riskLevel'] ?? '').toString().toLowerCase();
    final hazardObject = (data['hazardObject'] ?? '').toString().toLowerCase();

    final query = _searchText.trim().toLowerCase();

    return title.contains(query) ||
        reason.contains(query) ||
        riskLevel.contains(query) ||
        hazardObject.contains(query);
  }

  Future<void> _deleteSingleAlert(QueryDocumentSnapshot doc) async {
    await doc.reference.delete();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert deleted successfully'),
      ),
    );
  }

  Future<void> _deleteAllAlerts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete All Alerts?'),
          content: const Text(
            'Are you sure you want to delete all alert history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete All',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('alerts')
        .doc(user.uid)
        .collection('userAlerts')
        .get();

    if (snapshot.docs.isEmpty) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No alerts to delete'),
        ),
      );
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All alerts deleted successfully'),
      ),
    );
  }

  Future<bool> _confirmDeleteOne() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Alert?'),
          content: const Text(
            'Are you sure you want to delete this alert?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    return confirm == true;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 2,
        onTap: (index) => _handleBottomNav(context, index),
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text(
                    'ALERT HISTORY',
                    style: TextStyle(
                      color: const Color(0xFFCD6B94),
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  IconButton(
                    onPressed: _deleteAllAlerts,
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.red,
                      size: 22,
                    ),
                    tooltip: 'Delete all alerts',
                  ),
                ],
              ),

              SizedBox(height: h * 0.02),
              _buildSearchField(),
              SizedBox(height: h * 0.025),

              Expanded(
                child: user == null
                    ? const Center(child: Text('Not logged in'))
                    : StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('alerts')
                            .doc(user.uid)
                            .collection('userAlerts')
                            .orderBy('timestamp', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text(
                                'No alerts yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          final docs = snapshot.data!.docs
                              .where((doc) => _matchesSearch(doc))
                              .toList();

                          if (docs.isEmpty) {
                            return Center(
                              child: Text(
                                _searchText.trim().isEmpty
                                    ? 'No alerts yet.'
                                    : 'No alerts found for "$_searchText".',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          final now = DateTime.now();
                          final todayAlerts = <QueryDocumentSnapshot>[];
                          final yesterdayAlerts = <QueryDocumentSnapshot>[];
                          final earlierAlerts = <QueryDocumentSnapshot>[];

                          for (final doc in docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            final ts = data['timestamp'] as Timestamp?;

                            if (ts == null) {
                              earlierAlerts.add(doc);
                              continue;
                            }

                            final dt = ts.toDate();

                            final today = DateTime(
                              now.year,
                              now.month,
                              now.day,
                            );

                            final alertDate = DateTime(
                              dt.year,
                              dt.month,
                              dt.day,
                            );

                            final difference =
                                today.difference(alertDate).inDays;

                            if (difference == 0) {
                              todayAlerts.add(doc);
                            } else if (difference == 1) {
                              yesterdayAlerts.add(doc);
                            } else {
                              earlierAlerts.add(doc);
                            }
                          }

                          return ListView(
                            children: [
                              if (todayAlerts.isNotEmpty) ...[
                                _buildSectionTitle('TODAY'),
                                const SizedBox(height: 10),
                                ...todayAlerts.map(
                                  (doc) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _buildAlertCard(doc),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (yesterdayAlerts.isNotEmpty) ...[
                                _buildSectionTitle('YESTERDAY'),
                                const SizedBox(height: 10),
                                ...yesterdayAlerts.map(
                                  (doc) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _buildAlertCard(doc),
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (earlierAlerts.isNotEmpty) ...[
                                _buildSectionTitle('EARLIER'),
                                const SizedBox(height: 10),
                                ...earlierAlerts.map(
                                  (doc) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 12),
                                    child: _buildAlertCard(doc),
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final title = (data['title'] ?? 'Alert').toString();
    final riskLevel = (data['riskLevel'] ?? '').toString();
    final reason = (data['reason'] ?? '').toString();
    final hazardObject = (data['hazardObject'] ?? '').toString();
    final ts = data['timestamp'] as Timestamp?;

    String timeStr = '';
    if (ts != null) {
      final dt = ts.toDate();
      final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      timeStr = '$hour:$minute $period';
    }

    Color accentColor;
    switch (riskLevel) {
      case 'High':
        accentColor = const Color(0xFFFF4C4C);
        break;
      case 'Medium':
        accentColor = const Color(0xFFFF9800);
        break;
      default:
        accentColor = const Color(0xFF38B6FF);
    }

    return Dismissible(
      key: ValueKey(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (_) async {
        final confirm = await _confirmDeleteOne();

        if (confirm == true) {
          await _deleteSingleAlert(doc);
          return true;
        }

        return false;
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(14),
          border: Border(
            left: BorderSide(
              color: accentColor,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: accentColor.withOpacity(0.15),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: accentColor,
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
                  if (hazardObject.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      '⚠️ ${hazardObject[0].toUpperCase()}${hazardObject.substring(1)} detected',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 9,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Color(0xFFACAEBE),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                final confirm = await _confirmDeleteOne();

                if (confirm == true) {
                  await _deleteSingleAlert(doc);
                }
              },
              icon: Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
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
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchText = value;
        });
      },
      decoration: InputDecoration(
        hintText: 'Search by object, risk, title, or reason',
        prefixIcon: const Icon(Icons.search, size: 20),
        suffixIcon: _searchText.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.cancel,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchText = '';
                  });
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFFFAFAFA),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF38B6FF)),
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