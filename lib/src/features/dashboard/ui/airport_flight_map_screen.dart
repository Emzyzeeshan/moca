import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocadb/src/features/dashboard/provider/map_provider.dart';
import '../../../../common_imports.dart';
import '../../../datamodel/Map/map_direction_model.dart';
import '../../../datamodel/airports_model.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
      mapProvider = Provider.of<MapProvider>(context, listen: false);
      dashboardProvider.airportCode = widget.sourceAirport.airportCd!;
      mapProvider.postMapLatLngDirectionApiCall(airportCd: widget.sourceAirport.airportCd!,);
      mapProvider.postMapLatLngApiCall();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LatLng get sourceLatLng {
    final directionList = mapProvider.allMapLatLngDirectionList;

    for (final model in directionList) {
      final marker = model.mapMarkers?.firstWhere(
            (m) => m.fromLocation == widget.sourceAirport.airportCd,
        orElse: () => MapMarkers(),
      );

      final lat = double.tryParse(marker?.lat?.replaceAll("lat:", "").trim() ?? '');
      final lng = double.tryParse(marker?.lng?.replaceAll("lng:", "").trim() ?? '');

      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }

    return const LatLng(0.0, 0.0);
  }


  @override
  Widget build(BuildContext context) {
    mapProvider = Provider.of<MapProvider>(context, listen: false);
    final directionList = mapProvider.allMapLatLngDirectionList;

    // Collect all destination markers
    final List<LatLng> destinationMarkers = [];
    for (final model in directionList) {
      if (model.mapMarkers != null) {
        for (final marker in model.mapMarkers!) {
          final lat = double.tryParse(marker.lat?.replaceAll('lat:', '').trim() ?? '');
          final lng = double.tryParse(marker.lng?.replaceAll('lng:', '').trim() ?? '');
          if (lat != null && lng != null) {
            destinationMarkers.add(LatLng(lat, lng));
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.sourceAirport.airportName ?? 'Map')),
      body: FlutterMap(
        options: MapOptions(initialCenter: sourceLatLng, initialZoom: 5),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),

          // Source + Destination Markers
          MarkerLayer(
            markers: [
              Marker(
                point: sourceLatLng,
                width: 40,
                height: 40,
                child: const Icon(Icons.flight_takeoff, color: Colors.red),
              ),
              ...destinationMarkers.map((dest) => Marker(
                point: dest,
                width: 30,
                height: 30,
                child: const Icon(Icons.flight_land, color: Colors.green),
              )),
            ],
          ),

          // Animated Polyline Layer
          // Animated Polyline Layer using extracted logic
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final List<Polyline> animatedPolylines = [];

              for (final model in directionList) {
                if (model.mapMarkers == null) continue;

                final fromMarker = model.mapMarkers!.firstWhere(
                      (m) => m.fromLocation == widget.sourceAirport.airportCd,
                  orElse: () => MapMarkers(),
                );

                final fromLat = double.tryParse(fromMarker.lat?.replaceAll("lat:", "").trim() ?? '');
                final fromLng = double.tryParse(fromMarker.lng?.replaceAll("lng:", "").trim() ?? '');

                if (fromLat == null || fromLng == null) continue;

                final fromPoint = LatLng(fromLat, fromLng);

                // Find all destinations from this source
                final destinations = model.mapMarkers!
                    .where((m) =>
                m.fromLocation == widget.sourceAirport.airportCd &&
                    m.toLocation != widget.sourceAirport.airportCd)
                    .toList();

                for (final destMarker in destinations) {
                  final toLat = double.tryParse(destMarker.lat?.replaceAll("lat:", "").trim() ?? '');
                  final toLng = double.tryParse(destMarker.lng?.replaceAll("lng:", "").trim() ?? '');

                  if (toLat == null || toLng == null) continue;

                  final toPoint = LatLng(toLat, toLng);

                  final animatedPoint = LatLng(
                    fromPoint.latitude + (toPoint.latitude - fromPoint.latitude) * _animation.value,
                    fromPoint.longitude + (toPoint.longitude - fromPoint.longitude) * _animation.value,
                  );

                  animatedPolylines.add(
                    Polyline(
                      points: [fromPoint, animatedPoint],
                      strokeWidth: 3,
                      color: Colors.blue.withOpacity(0.85),
                    ),
                  );
                }
              }

              return PolylineLayer(polylines: animatedPolylines);
            },
          ),
        ],
      ),
    );
  }
}
