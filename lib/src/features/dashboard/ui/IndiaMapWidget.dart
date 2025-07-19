import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocadb/src/core/theme/colors.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../../../core/utils/routes.dart';
import '../../../datamodel/Map/map_model.dart';
import '../../../datamodel/airports_model.dart';
import '../provider/map_provider.dart';
import '../provider/dashboard_provider.dart';
import '../provider/monitor_provider.dart';
import 'AirportsViewTappedScreen.dart';
import 'MonitorScreen.dart';
import 'airport_flight_map_screen.dart';
import 'filter_screen.dart'; // <-- Import your filter screen

class IndiaMapWidget extends StatefulWidget {
  const IndiaMapWidget({super.key});

  @override
  State<IndiaMapWidget> createState() => _IndiaMapWidgetState();
}

class _IndiaMapWidgetState extends State<IndiaMapWidget> {
  String? selectedAirport;
  String? selectedState;
  String? selectedRegion;
  String? selectedFieldType;
  String? selectedAirportType;

  int _selectedTab = 1;
  bool _showLegend = true;
  late Future<List<Polyline>> polylineFuture;
  List<AllAirportsModel> filteredAirports = [];

  Map<String, int> legendCounts = {};
  Set<String> activeTypes = {
    'international',
    'domestic',
    'civil',
    'custom',
    'under construction'
  };
  bool hasCustomFilter = false;

  @override
  void initState() {
    super.initState();
    polylineFuture = loadIndiaBoundaries();
    final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    final filters = dashboardProvider.filterParams;
    if (filters != null) {
      selectedAirport = filters.airportName;
      selectedState = filters.stateName;
      selectedRegion = filters.regionName;
      selectedFieldType = filters.fieldType;
      selectedAirportType = filters.airportType;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);

      // 🛠️ Avoid reloading if already loaded
      if (mapProvider.allMapLatLngList.isEmpty) {
        await mapProvider.postMapLatLngApiCall();
      }

      // Recalculate legend counts from existing data
      Map<String, int> tempCounts = {
        'international': 0,
        'domestic': 0,
        'civil': 0,
        'custom': 0,
        'under construction': 0,
      };

      for (var model in mapProvider.allMapLatLngList) {
        model.mapMarkers?.forEach((marker) {
          final type = marker.airportType?.toLowerCase() ?? '';
          if (type.contains('international'))
            tempCounts['international'] = tempCounts['international']! + 1;
          else if (type.contains('domestic'))
            tempCounts['domestic'] = tempCounts['domestic']! + 1;
          else if (type.contains('civil'))
            tempCounts['civil'] = tempCounts['civil']! + 1;
          else if (type.contains('custom'))
            tempCounts['custom'] = tempCounts['custom']! + 1;
          else if (type.contains('under construction'))
            tempCounts['under construction'] =
                tempCounts['under construction']! + 1;
        });
      }

      setState(() {
        legendCounts = tempCounts;
      });

      final monitorProvider =
      Provider.of<MonitorProvider>(context, listen: false);
      await monitorProvider.getAllAirportListApiCall();

      final chennaiAirport = monitorProvider.allAirportsList.firstWhere(
            (airport) =>
            (airport.airportName?.toLowerCase() ?? '').contains('chennai'),
        orElse: () => AllAirportsModel(),
      );

      if (chennaiAirport.airportCd != null &&
          chennaiAirport.airportCd!.isNotEmpty) {
        await monitorProvider.postDateApi(airportCd: chennaiAirport.airportCd!);
        debugPrint("✅ Date API Fetched: ${monitorProvider.apiSelectedDate}");
      } else {
        debugPrint("❌ Chennai airport not found in list.");
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    final mapProvider = Provider.of<MapProvider>(context);
    final dashboardProvider = Provider.of<DashboardProvider>(context);

    return Stack(
      children: [
        _selectedTab == 1 ? _buildMapView(mapProvider) : const MonitorScreen(),

        // Monitor & Directory toggle
        if (dashboardProvider.showMonitorAndDirectoryButtons)
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

        // Filter Button
        if (_selectedTab == 1)
          Positioned(
            top: 20,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'filterBtn',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () async {
                final result = await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) {
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: DraggableScrollableSheet(
                        initialChildSize: 0.75,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        expand: false,
                        builder: (context, scrollController) {
                          return Material(
                            color: Colors.white,
                            child: FilterScreen(
                              scrollController: scrollController,
                              selectedAirport: selectedAirport,
                              selectedState: selectedState,
                              selectedRegion: selectedRegion,
                              selectedFieldType: selectedFieldType,
                              selectedAirportType: selectedAirportType,// <-- pass controller
                            ),
                          );
                        },
                      ),
                    );
                  },

                );

                if (result != null && result is List<AllAirportsModel>) {
                  final List<AllAirportsModel> filtered = result;
                  final mapProvider = Provider.of<MapProvider>(context, listen: false);

                  final airportTypes = <String, int>{
                    'international': 0,
                    'domestic': 0,
                    'civil': 0,
                    'custom': 0,
                    'under construction': 0,
                  };

                  for (var airport in filtered) {
                    final marker = mapProvider.allMapLatLngList
                        .expand((model) => model.mapMarkers ?? [])
                        .firstWhere(
                          (m) => m.airportCd == airport.airportCd,
                      orElse: () => MapMarkers(),
                    );

                    final type = marker.airportType?.toLowerCase() ?? '';
                    if (type.contains('international')) {
                      airportTypes['international'] = airportTypes['international']! + 1;
                    } else if (type.contains('domestic')) {
                      airportTypes['domestic'] = airportTypes['domestic']! + 1;
                    } else if (type.contains('civil')) {
                      airportTypes['civil'] = airportTypes['civil']! + 1;
                    } else if (type.contains('custom')) {
                      airportTypes['custom'] = airportTypes['custom']! + 1;
                    } else if (type.contains('under construction')) {
                      airportTypes['under construction'] =
                          airportTypes['under construction']! + 1;
                    }
                  }

                  // ✅ Save selected filters so next time they can be restored
                  final dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
                  final filters = dashboardProvider.filterParams;
                  setState(() {
                    filteredAirports = filtered;
                    legendCounts = airportTypes;
                    activeTypes = airportTypes.entries
                        .where((entry) => entry.value > 0)
                        .map((entry) => entry.key)
                        .toSet();
                    hasCustomFilter = true;

                    // ✅ Remember filters for next time
                    selectedAirport = filters?.airportName;
                    selectedState = filters?.stateName;
                    selectedRegion = filters?.regionName;
                    selectedFieldType = filters?.fieldType;
                    selectedAirportType = filters?.airportType;
                  });
                }
              },
              child: const Icon(Icons.filter_alt, color: Colors.blue),
            ),
          ),

        // Clear Filter
        if (_selectedTab == 1 && filteredAirports.isNotEmpty)
          Positioned(
            top: 80,
            left: 20,
            child: FloatingActionButton(
              heroTag: 'clearFilterBtn',
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () async {
                final mapProvider = Provider.of<MapProvider>(context, listen: false);

                // Recalculate legend counts using full data again
                Map<String, int> refreshedLegendCounts = {
                  'international': 0,
                  'domestic': 0,
                  'civil': 0,
                  'custom': 0,
                  'under construction': 0,
                };

                for (var model in mapProvider.allMapLatLngList) {
                  model.mapMarkers?.forEach((marker) {
                    final type = marker.airportType?.toLowerCase() ?? '';
                    if (type.contains('international')) {
                      refreshedLegendCounts['international'] =
                          refreshedLegendCounts['international']! + 1;
                    } else if (type.contains('domestic')) {
                      refreshedLegendCounts['domestic'] =
                          refreshedLegendCounts['domestic']! + 1;
                    } else if (type.contains('civil')) {
                      refreshedLegendCounts['civil'] =
                          refreshedLegendCounts['civil']! + 1;
                    } else if (type.contains('custom')) {
                      refreshedLegendCounts['custom'] =
                          refreshedLegendCounts['custom']! + 1;
                    } else if (type.contains('under construction')) {
                      refreshedLegendCounts['under construction'] =
                          refreshedLegendCounts['under construction']! + 1;
                    }
                  });
                }

                setState(() {
                  filteredAirports.clear(); // 🔁 ensures all are visible
                  legendCounts = refreshedLegendCounts;
                  activeTypes = {
                    'international',
                    'domestic',
                    'civil',
                    'custom',
                    'under construction'
                  };
                  hasCustomFilter = false;

                  // Also clear saved filter UI values
                  selectedAirport = null;
                  selectedState = null;
                  selectedRegion = null;
                  selectedFieldType = null;
                  selectedAirportType = null;
                });
              },

              child: const Icon(Icons.clear, color: Colors.red),
            ),
          ),
        // 🔘 Show Filtered Airports Button (bottom right)
        if (_selectedTab == 1 && filteredAirports.isNotEmpty)
          Positioned(
            bottom: 90,
            right: 20,
            child: FloatingActionButton.extended(
              foregroundColor: ThemeColors.whiteColor,
              heroTag: 'showFilteredAirportsBtn',
              backgroundColor: Colors.indigo,
              icon: const Icon(Icons.list_alt),
              label: const Text("Filtered Airports"),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  isScrollControlled: true,
                  builder: (context) {
                    return DraggableScrollableSheet(
                      expand: false,
                      initialChildSize: 0.6,
                      minChildSize: 0.3,
                      maxChildSize: 0.95,
                      builder: (_, controller) => Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ListView.separated(
                          controller: controller,
                          itemCount: filteredAirports.length,
                          itemBuilder: (context, index) {
                            final airport = filteredAirports[index];
                            return ListTile(
                              leading: const Icon(Icons.flight),
                              title: Text(airport.airportName ?? 'Unknown'),
                              subtitle: Text("Code: ${airport.airportCd ?? '-'}"),
                              onTap: () {
                                Navigator.pop(context); // Close the bottom sheet first
                                _showOptionsDialog(context, airport);
                              },
                            );
                          },

                          separatorBuilder: (_, __) => const Divider(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),


        // Legend
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
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4)
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
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Legend",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (hasCustomFilter) _legendItem(Colors.black, "All"),
                        if (legendCounts.containsKey('international'))
                          _legendItem(Colors.red, "International"),
                        if (legendCounts.containsKey('domestic'))
                          _legendItem(Colors.blue, "Domestic"),
                        if (legendCounts.containsKey('civil'))
                          _legendItem(Colors.green, "Civil"),
                        if (legendCounts.containsKey('custom'))
                          _legendItem(Colors.orange, "Custom"),
                        if (legendCounts.containsKey('under construction'))
                          _legendItem(Colors.purple, "Under Construction"),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    final key = label.toLowerCase();
    final isActive = activeTypes.contains(key);
    final count = legendCounts[key] ?? 0;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (key == 'all') {
            activeTypes = {
              'international',
              'domestic',
              'civil',
              'custom',
              'under construction'
            };
            hasCustomFilter = false;
          } else {
            activeTypes = {key};
            hasCustomFilter = true;
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(Icons.location_on,
                color: isActive ? color : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(
              "$label (${key == 'all' ? legendCounts.values.fold(0, (a, b) => a + b) : count})",
              style: TextStyle(
                fontSize: 14,
                color: isActive ? Colors.black : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
// Your existing _showOptionsDialog function
  void _showOptionsDialog(BuildContext context, AllAirportsModel airport) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select an Option"),
        content: const Text("What would you like to view?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AirportsViewTappedScreen(data: airport),
                ),
              );
            },
            child: const Text("Airport Details"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AirportFlightMapScreen(sourceAirport: airport),
                ),
              );
            },
            child: const Text("View on Map"),
          ),
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

  Widget _buildMapView(MapProvider provider) {
    final List<Marker> markers = [];

    List<MapMarkers>? markerListToUse = [];

    if (filteredAirports.isNotEmpty) {
      for (var airport in filteredAirports) {
        final List<MapMarkers> airportMarkers = provider.allMapLatLngList
            .expand((model) => model.mapMarkers ?? [])
            .where((marker) => marker.airportCd == airport.airportCd)
            .cast<MapMarkers>() // ✅ Safely cast to correct type
            .toList();

        markerListToUse.addAll(airportMarkers);

      }
    } else {
      markerListToUse = provider.allMapLatLngList
          .expand((model) => model.mapMarkers ?? []).cast<MapMarkers>()
          .toList();
    }

    for (var marker in markerListToUse!) {
      try {
        final String? latStr = marker.lat;
        final String? lngStr = marker.lng;

        if (latStr == null || lngStr == null) continue;

        final double lat =
        double.parse(latStr.replaceAll(RegExp(r'[^\d\.\-]'), ''));
        final double lng =
        double.parse(lngStr.replaceAll(RegExp(r'[^\d\.\-]'), ''));

        final type = marker.airportType?.toLowerCase();
        if (type == null || !activeTypes.any((t) => type.contains(t))) continue;

        Color markerColor = Colors.grey;
        if (type.contains('international'))
          markerColor = Colors.red;
        else if (type.contains('domestic'))
          markerColor = Colors.blue;
        else if (type.contains('civil'))
          markerColor = Colors.green;
        else if (type.contains('custom'))
          markerColor = Colors.orange;
        else if (type.contains('under construction'))
          markerColor = Colors.purple;

        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 20,
            height: 20,
            child: GestureDetector(
              onTap: () {
                final airportData = AllAirportsModel(
                  airportName: marker.airportName,
                  airportCd: marker.airportCd,
                );

                // ✅ Prevent showing bottom sheet before layout is ready
                if (!mounted) return;

                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) =>
                      _bottomSheetForAirport(context, airportData),
                );
              },
              child: Icon(Icons.location_on, color: markerColor, size: 20),
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error parsing marker: $e');
      }
    }

    return FutureBuilder<List<Polyline>>(
      future: polylineFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(22.5937, 78.9629),
            initialZoom: 5.0,
            maxZoom: 12.0,
            minZoom: 3.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            PolylineLayer(polylines: snapshot.data!),
            MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }


  Widget _bottomSheetForAirport(
      BuildContext context, AllAirportsModel airportData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.map),
            title: const Text('View Flight Route'),
            onTap: () {
              Navigator.pop(context);
              NavigateRoutes.navigatePush(
                widget: AirportFlightMapScreen(sourceAirport: airportData),
                context: context,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              NavigateRoutes.navigatePush(
                widget: AirportsViewTappedScreen(data: airportData),
                context: context,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<List<Polyline>> loadIndiaBoundaries() async {
    final jsonStr = await rootBundle.loadString('assets/india_boundaries.json');
    final decoded = json.decode(jsonStr);
    final features = decoded['features'] as List;

    List<Polyline> polylines = [];

    for (var feature in features) {
      final geometry = feature['geometry'];
      final properties = feature['properties'];
      final coords = geometry['coordinates'];
      final type = geometry['type'];

      final isDisputed = properties['boundary'] == 'disputed';
      final color =
          isDisputed ? const Color(0xFFF2EFEA) : const Color(0xFFB9A8B9);
      final strokeWidth = isDisputed ? 2.0 : 1.0;

      if (type == 'LineString') {
        final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        polylines.add(
            Polyline(points: points, color: color, strokeWidth: strokeWidth));
      } else if (type == 'MultiLineString') {
        for (var line in coords) {
          final points = line.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          polylines.add(
              Polyline(points: points, color: color, strokeWidth: strokeWidth));
        }
      }
    }

    return polylines;
  }
}
