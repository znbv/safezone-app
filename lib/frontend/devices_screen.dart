import 'package:flutter/material.dart';
import 'app_bottom_nav.dart';
import 'home_screen.dart';
import 'live_monitoring_screen.dart';
import 'alerts_history_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchText = '';

  final List<Map<String, String>> _devices = [
    {
      'name': 'Living Room Camera',
      'location': 'Living Room',
      'status': 'Online',
    },
    {
      'name': 'Bedroom Camera',
      'location': 'Bedroom',
      'status': 'Online',
    },
    {
      'name': 'Play Area Camera',
      'location': 'Play Area',
      'status': 'Offline',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredDevices {
    if (_searchText.trim().isEmpty) {
      return _devices;
    }

    final query = _searchText.trim().toLowerCase();

    return _devices.where((device) {
      final name = device['name']!.toLowerCase();
      final location = device['location']!.toLowerCase();
      final status = device['status']!.toLowerCase();

      return name.contains(query) ||
          location.contains(query) ||
          status.contains(query);
    }).toList();
  }

  void _showDeviceDialog({
    Map<String, String>? device,
    int? index,
  }) {
    final nameController = TextEditingController(
      text: device?['name'] ?? '',
    );
    final locationController = TextEditingController(
      text: device?['location'] ?? '',
    );

    String selectedStatus = device?['status'] ?? 'Online';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                device == null ? 'Add Device' : 'Edit Device',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Device Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Online',
                          child: Text('Online'),
                        ),
                        DropdownMenuItem(
                          value: 'Offline',
                          child: Text('Offline'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() {
                          selectedStatus = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final location = locationController.text.trim();

                    if (name.isEmpty || location.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      if (device == null) {
                        _devices.add({
                          'name': name,
                          'location': location,
                          'status': selectedStatus,
                        });
                      } else if (index != null) {
                        _devices[index] = {
                          'name': name,
                          'location': location,
                          'status': selectedStatus,
                        };
                      }
                    });

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38B6FF),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(device == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteDevice(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Device?'),
          content: const Text(
            'Are you sure you want to delete this device?',
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

    if (confirm != true) return;

    setState(() {
      _devices.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Device deleted successfully'),
      ),
    );
  }

  int _getRealIndex(Map<String, String> device) {
    return _devices.indexOf(device);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final w = size.width;
    final h = size.height;

    final filteredDevices = _filteredDevices;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AppBottomNav(
        currentIndex: 3,
        onTap: (index) => _handleBottomNav(context, index),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showDeviceDialog(),
        backgroundColor: const Color(0xFF38B6FF),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
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
                child: filteredDevices.isEmpty
                    ? Center(
                        child: Text(
                          _searchText.trim().isEmpty
                              ? 'No devices added yet.'
                              : 'No devices found for "$_searchText".',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredDevices.length,
                        itemBuilder: (context, index) {
                          final device = filteredDevices[index];
                          final realIndex = _getRealIndex(device);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildDeviceCard(
                              device: device,
                              index: realIndex,
                            ),
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
        hintText: 'Search by name, location, or status',
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

  Widget _buildDeviceCard({
    required Map<String, String> device,
    required int index,
  }) {
    final status = device['status'] ?? 'Offline';
    final isOnline = status == 'Online';

    final statusColor = isOnline
        ? const Color(0xFF4CAF50)
        : const Color(0xFFFF4C4C);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: statusColor.withOpacity(0.15),
            child: Icon(
              Icons.videocam_outlined,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device['name'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF222741),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  device['location'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: statusColor,
                      size: 9,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () {
              _showDeviceDialog(
                device: device,
                index: index,
              );
            },
            icon: Icon(
              Icons.edit_outlined,
              size: 19,
              color: Colors.grey.shade700,
            ),
          ),

          IconButton(
            onPressed: () => _deleteDevice(index),
            icon: const Icon(
              Icons.delete_outline,
              size: 19,
              color: Colors.red,
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AlertsHistoryScreen()),
      );
    } else if (index == 3) {
      return;
    }
  }
}