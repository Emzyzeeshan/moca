import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/routes.dart';
import '../../../datamodel/airports_model.dart';
import '../provider/map_provider.dart';
import 'AirportsViewTappedScreen.dart'; // adjust path

class IndiaMapWidget extends StatefulWidget {
  const IndiaMapWidget({super.key});

  @override
  State<IndiaMapWidget> createState() => _IndiaMapWidgetState();
}

class _IndiaMapWidgetState extends State<IndiaMapWidget> {
  int _selectedTab = 1;
  bool _showLegend = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      print("Calling API...");
      Provider.of<MapProvider>(context, listen: false).postMapLatLngApiCall();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);

    return Stack(
      children: [
        _selectedTab == 1 ? _buildMapView(mapProvider) : _buildMonitorView(),
        Positioned(
          top: 20,
          right: 20,
          child: Row(
            children: [
              _buildToggleButton("Monitor", 0),
              const SizedBox(width: 8),
              _buildToggleButton("Directory", 1),
            ],
          ),
        ),
        // Legend toggle and panel
    if (_selectedTab == 1)
    Positioned(
    bottom: 20,
    left: 20,
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    GestureDetector(
    onTap: () => setState(() => _showLegend = !_showLegend),
    child: Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(6),
    boxShadow: [
    BoxShadow(color: Colors.black26, blurRadius: 4),
    ],
    ),
    child: Icon(
    _showLegend
    ? Icons.keyboard_arrow_down
        : Icons.keyboard_arrow_up,
    size: 24,
    ),
    ),
    ),
    const SizedBox(height: 6),
    if (_showLegend)
    Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
    BoxShadow(color: Colors.black26, blurRadius: 6)
    ],
    ),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
    const Text("Legend",
    style: TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    _legendItem(Colors.red, "International"),
    _legendItem(Colors.blue, "Domestic"),
    _legendItem(Colors.green, "Civil Enclave"),
    _legendItem(Colors.orange, "Custom"),
    _legendItem(Colors.black, "Under Construction"),

    ],
    ))]))]);
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.location_on, color: color, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, int index) {
    final bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[600],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildMapView(MapProvider provider) {
    final List<Marker> markers = [];

    for (var mapModel in provider.allMapLatLngList) {
      if (mapModel.mapMarkers != null) {
        for (var marker in mapModel.mapMarkers!) {
          try {
            final double lat =
                double.parse(marker.lat!.replaceAll(RegExp(r'[^\d\.\-]'), ''));
            final double lng =
                double.parse(marker.lng!.replaceAll(RegExp(r'[^\d\.\-]'), ''));

            // Determine color based on type
            Color markerColor = Colors.grey; // default color
            final type = marker.airportType
                ?.toLowerCase(); // Adjust field name accordingly

            if (type != null) {
              if (type.contains('international')) {
                markerColor = Colors.red;
              } else if (type.contains('domestic')) {
                markerColor = Colors.blue;
              } else if (type.contains('civil')) {
                markerColor = Colors.green;
              } else if (type.contains('custom')) {
                markerColor = Colors.orange;
              } else if (type.contains('under construction')) {
                markerColor = Colors.black;
              }
            }

            markers.add(
              Marker(
                point: LatLng(lat, lng),
                width: 20,
                height: 20,
                child: GestureDetector(
                    onTap: () async {
                      final airportData = AllAirportsModel(
                        airportName: marker.airportName,
                        airportCd: marker.airportCd,
                        // Add other fields if available
                      );

                      await NavigateRoutes.navigatePush(
                        widget: AirportsViewTappedScreen(data: airportData),
                        context: context,
                      );
                    },

                    child:
                        Icon(Icons.location_on, color: markerColor, size: 20)),
              ),
            );
          } catch (e) {
            debugPrint('Error parsing lat/lng for ${marker.airportCd}: $e');
          }
        }
      }
    }

    return SizedBox.expand(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(22.5937, 78.9629),
          initialZoom: 4.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  Widget _buildMonitorView() {
    return const Center(
      child: Text(
        "Monitor Screen",
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    );
  }
}
