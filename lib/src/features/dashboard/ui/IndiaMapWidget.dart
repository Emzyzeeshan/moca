import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class IndiaMapWidget extends StatefulWidget {
  const IndiaMapWidget({super.key});

  @override
  State<IndiaMapWidget> createState() => _IndiaMapWidgetState();
}

class _IndiaMapWidgetState extends State<IndiaMapWidget> {
  int _selectedTab = 1; // 1 = Directory (default), 0 = Monitor

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Screen switching logic
        _selectedTab == 1 ? _buildMapView() : _buildMonitorView(),

        // Top-right toggle buttons
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                _buildToggleButton("Monitor", 0),
                const SizedBox(width: 8),
                _buildToggleButton("Directory", 1),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the toggle button with styling and onTap functionality
  Widget _buildToggleButton(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[600],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Map view (Directory)
  Widget _buildMapView() {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(22.5937, 78.9629),
        initialZoom: 4.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
      ],
    );
  }

  /// Monitor screen placeholder
  Widget _buildMonitorView() {
    return Center(
      child: Text(
        "Monitor Screen",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
