import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import '../../../../common_imports.dart';
import '../../../datamodel/airports_model.dart';
import '../../../datamodel/Map/map_direction_model.dart';
import '../provider/map_provider.dart';
import '../provider/dashboard_provider.dart';

class AirportFlightMapScreen extends StatefulWidget {
  final AllAirportsModel sourceAirport;

  const AirportFlightMapScreen({super.key, required this.sourceAirport});

  @override
  State<AirportFlightMapScreen> createState() => _AirportFlightMapScreenState();
}

class _AirportFlightMapScreenState extends State<AirportFlightMapScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late DashboardProvider dashboardProvider;
  late MapProvider mapProvider;
  late Future<List<Polyline>> _indiaBoundaryPolylines;

  bool _isLoading = true;
  bool _hasDirections = false;
  LatLng _sourceLatLng = const LatLng(0.0, 0.0);
  List<_TypedMarker> _destinationMarkers = [];
  List<_FlightAnimation> _flightAnimations = [];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    // ✅ Initialize the late variable here
    _indiaBoundaryPolylines = _loadIndiaBoundaries();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      mapProvider = Provider.of<MapProvider>(context, listen: false);

      dashboardProvider.airportCode = widget.sourceAirport.airportCd!;
      await mapProvider.postMapLatLngDirectionApiCall(airportCd: widget.sourceAirport.airportCd!);
      await mapProvider.postMapLatLngApiCall();

      _extractMapData();
      setState(() => _isLoading = false);
    });
  }


  void _extractMapData() {
    final directionList = mapProvider.allMapLatLngDirectionList;
    _hasDirections = directionList.any((model) => model.fromLocation != null && model.fromLocation!.isNotEmpty);
    if (!_hasDirections) return;


    _flightAnimations.clear();
    _destinationMarkers.clear();

    for (final model in directionList) {
      if (model.fromLocation == null || model.toLocations == null) continue;

      final from = model.fromLocation!.first;
      final fromLat = double.tryParse(from.fROMLAT?.replaceAll("lat:", "").trim() ?? '');
      final fromLng = double.tryParse(from.fROMLNG?.replaceAll("lng:", "").trim() ?? '');
      if (fromLat == null || fromLng == null) continue;
      final fromPoint = LatLng(fromLat, fromLng);
      _sourceLatLng = fromPoint;

      for (final to in model.toLocations!) {
        final toLat = double.tryParse(to.tOLAT?.replaceAll('lat:', '').trim() ?? '');
        final toLng = double.tryParse(to.tOLNG?.replaceAll('lng:', '').trim() ?? '');
        if (toLat == null || toLng == null) continue;

        final toPoint = LatLng(toLat, toLng);
        _flightAnimations.add(_FlightAnimation(from: fromPoint, to: toPoint));
        _destinationMarkers.add(_TypedMarker(point: toPoint, airportType: to.aIRPORTTYPE ?? ''));
      }
    }
  }

  Marker _buildAnimatedFlightMarker(_FlightAnimation flight, double t) {
    final lat = flight.from.latitude + (flight.to.latitude - flight.from.latitude) * t;
    final lng = flight.from.longitude + (flight.to.longitude - flight.from.longitude) * t;
    final animatedPoint = LatLng(lat, lng);
    final angle = _calculateBearing(flight.from, flight.to);

    return Marker(
      point: animatedPoint,
      width: 40,
      height: 40,
      child: Transform.rotate(
        angle: angle * math.pi / 180,
        child: const Icon(Icons.airplanemode_active, color: Colors.black, size: 28),
      ),
    );
  }

  double _calculateBearing(LatLng start, LatLng end) {
    final lat1 = start.latitudeInRad;
    final lon1 = start.longitudeInRad;
    final lat2 = end.latitudeInRad;
    final lon2 = end.longitudeInRad;
    final dLon = lon2 - lon1;
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    final bearingRad = math.atan2(y, x);
    return (bearingRad * (180 / math.pi) + 360) % 360;
  }

  Color _getColorForAirportType(String? type) {
    final lower = type?.toLowerCase() ?? '';
    if (lower.contains("international")) return Colors.red;
    if (lower.contains("domestic")) return Colors.blue;
    if (lower.contains("civil")) return Colors.green;
    if (lower.contains("custom")) return Colors.orange;
    if (lower.contains("under construction")) return Colors.black;
    return Colors.grey;
  }

  Widget _legendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.sourceAirport.airportName ?? 'Map')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final animatedMarkers = _flightAnimations.map((f) => _buildAnimatedFlightMarker(f, _animation.value)).toList();
              final List<Polyline> dottedPolylines = [];

              for (final flight in _flightAnimations) {
                final segments = generateDottedLine(flight.from, flight.to);
                for (int i = 0; i < segments.length - 1; i += 2) {
                  dottedPolylines.add(Polyline(points: [segments[i], segments[i + 1]], strokeWidth: 2, color: Colors.blue.withOpacity(0.8)));
                }
              }

              return FutureBuilder<List<Polyline>>(
                future: _indiaBoundaryPolylines,
                builder: (context, snapshot) {
                  final indiaBoundaries = snapshot.data ?? [];

                  return FlutterMap(
                    options: MapOptions(initialCenter: _sourceLatLng, initialZoom: 5),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      PolylineLayer(polylines: [
                        ...indiaBoundaries,
                        ...dottedPolylines,
                      ]),
                      MarkerLayer(markers: [
                        Marker(
                          point: _sourceLatLng,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.pin_drop, color: Colors.red),
                        ),
                        ..._destinationMarkers.map((dest) => Marker(
                          point: dest.point,
                          width: 30,
                          height: 30,
                          child: Icon(Icons.pin_drop, color: _getColorForAirportType(dest.airportType)),
                        )),
                        ...animatedMarkers,
                      ]),
                    ],
                  );
                },
              );
            },
          ),


          // Legend
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem(Colors.red, "International"),
                  _legendItem(Colors.blue, "Domestic"),
                  _legendItem(Colors.green, "Civil Enclave"),
                  _legendItem(Colors.orange, "Custom"),
                  _legendItem(Colors.black, "Under Construction"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<LatLng> generateDottedLine(LatLng start, LatLng end, {int segments = 20}) {
    final List<LatLng> dottedPoints = [];
    for (int i = 0; i <= segments; i++) {
      final t = i / segments;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      dottedPoints.add(LatLng(lat, lng));
    }

    List<LatLng> dottedSegments = [];
    for (int i = 0; i < dottedPoints.length - 1; i += 2) {
      dottedSegments.add(dottedPoints[i]);
      dottedSegments.add(dottedPoints[i + 1]);
    }
    return dottedSegments;
  }
}

class _FlightAnimation {
  final LatLng from;
  final LatLng to;
  _FlightAnimation({required this.from, required this.to});
}

class _TypedMarker {
  final LatLng point;
  final String airportType;
  _TypedMarker({required this.point, required this.airportType});
}

Future<List<Polyline>> _loadIndiaBoundaries() async {
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
    final color = isDisputed ? const Color(0xFFF2EFEA) : const Color(0xFFB9A8B9);
    final strokeWidth = isDisputed ? 2.0 : 1.0;

    if (type == 'LineString') {
      final points = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
      polylines.add(Polyline(points: points, color: color, strokeWidth: strokeWidth));
    } else if (type == 'MultiLineString') {
      for (var line in coords) {
        final points = line.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        polylines.add(Polyline(points: points, color: color, strokeWidth: strokeWidth));
      }
    }
  }

  return polylines;
}
