import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:latlong2/latlong.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../provider/dashboard_provider.dart';

class IndiaMapWidget extends StatefulWidget {
  final Function(String) onStateSelected;

  IndiaMapWidget({super.key, required this.onStateSelected});

  @override
  State<IndiaMapWidget> createState() => _IndiaMapWidgetState();
}

class _IndiaMapWidgetState extends State<IndiaMapWidget> {
  // Geo-coordinates for each state's approximate location
  late DashboardProvider dashboardProvider;
  final Map<String, LatLng> stateGeoCoordinates = {
    "Andaman and Nicobar": LatLng(2.0, 89.0),
    "Lakshadweep": LatLng(1.00,  68.00),
    "Jammu And Kashmir": LatLng(23.8, 70.0),
    "Ladakh": LatLng(24.5, 75.0),
    "Punjab": LatLng(20.95, 73.5),
    "Himachal Pradesh": LatLng(21.8, 73.5),
    "Uttarakhand": LatLng(20.6, 76.0),
    "Haryana": LatLng(18.7, 74.0),
    "Delhi": LatLng(18.2, 75.2),
    "Uttar Pradesh": LatLng(16.8, 78.5),
    "Bihar": LatLng(15.0, 83.8),
    "Jharkhand": LatLng(13.0, 82.6),
    "West Bengal": LatLng(13.0, 85.4),
    "Rajasthan": LatLng(16.5, 70.5),
    "Madhya Pradesh": LatLng(13.0, 75.0),
    "Chhattisgarh": LatLng(11.5, 79.0),
    "Orissa": LatLng(10.5, 82.5),
    "Telangana": LatLng(8,76.5),
    "Andra Pradesh": LatLng(5.5, 76.0),
    "Tamilnadu": LatLng(1.0, 76.0),
    "Karnataka": LatLng(5.5, 72.5),
    "Kerala": LatLng(1.0, 74.0),
    "Maharashtra": LatLng(9.5, 72.2),
    "Gujarat": LatLng(13.0, 69.0),
    "Goa": LatLng(5.2, 72.2),
    "Assam": LatLng(16.0, 90.9),
    "Meghalaya": LatLng(15.0, 89.2),
    "Tripura": LatLng(13.0, 90.0),
    "Manipur": LatLng(14.0, 92.2),
    "Nagaland": LatLng(15.8, 92.6),
    "Mizoram": LatLng(12.5, 91.0),
    "Arunachal Pradesh": LatLng(18.2, 91.7),
    "Sikkim": LatLng(17, 86.8),
    "Pondicherry": LatLng(2.8, 77.0),
  };

  @override
  void initState() {
    super.initState();
    dashboardProvider = Provider.of(context, listen: false);
    fetchData();
  }

  Future<void> fetchData() async {
    EasyLoading.show(status: Constants.loading);
    await dashboardProvider.getAllStatesListApiCall();
    await dashboardProvider
        .getStateWiseAirportListApiCall(widget.onStateSelected as String);
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            GestureDetector(
              onTapUp: (TapUpDetails details) async {
                LatLng tappedLocation =
                    _convertXYtoGeo(details.localPosition, constraints);
                String selectedState = _detectState(tappedLocation);

                /*if (selectedState.isNotEmpty) {
                  widget.onStateSelected(selectedState);

                  // Call API to fetch airports
                  await dashboardProvider
                      .getStateWiseAirportListApiCall(selectedState);
                }*/
              },
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InteractiveViewer(
                    child: Container(
                        child: Stack(
                      children: [
                        SvgPicture.asset(
                          'assets/svg/india_map/Indiamap.svg',
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          fit: BoxFit.contain,
                        ),
                        ..._buildStateMarkers(constraints)
                      ],
                    )),
                  )
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Converts pixel position (x, y) to latitude & longitude
  LatLng _convertXYtoGeo(Offset position, BoxConstraints constraints) {
    double mapWidth = constraints.maxWidth;
    double mapHeight = mapWidth * 650 / 579;

    // Adjusted min/max latitudes and longitudes for India
    double minLat = 6.5;
    double maxLat = 37.1;
    double minLon = 67.0;
    double maxLon = 97.4;

    double longitude = minLon + (position.dx / mapWidth) * (maxLon - minLon);
    double latitude = maxLat - (position.dy / mapHeight) * (maxLat - minLat);

    return LatLng(latitude, longitude);
  }

  /// Finds the closest state based on tapped location
  String _detectState(LatLng tappedLocation) {
    double minDistance = double.infinity;
    String closestState = "";

    final Distance distance = Distance();
    for (var entry in stateGeoCoordinates.entries) {
      double dist =
          distance.as(LengthUnit.Kilometer, tappedLocation, entry.value);
      if (dist < minDistance) {
        minDistance = dist;
        closestState = entry.key;
      }
    }
    return closestState;
  }

  /// Builds red dot markers for states with **responsive scaling**
  List<Widget> _buildStateMarkers(BoxConstraints constraints) {
    double markerSize =
        constraints.maxWidth * 0.015; // Adjust based on map size
    double fontSize = constraints.maxWidth * 0.02; // Scale text size

    return stateGeoCoordinates.entries.map((entry) {
      Offset position = _convertGeoToXY(entry.value, constraints);
      String state = stateGeoCoordinates.entries.firstWhere((coords) => coords.value.latitude==entry.value.latitude && coords.value.longitude == entry.value.longitude).key;

      return Positioned(
        left: position.dx - (markerSize / 2), // Center the marker
        top: position.dy - (markerSize / 2),
        child: GestureDetector(
            behavior: HitTestBehavior.translucent,
          onTap: () => widget.onStateSelected(state),
          child: Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.transparent,width: 1)),
            child: Padding(
              padding: EdgeInsets.all(5),
              // padding: statePadding[state],
              child: Column(
                children: [
                    Container(
                      width: markerSize,
                      height: markerSize,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  SizedBox(height: markerSize * 0.5), // Spacing
                  Text(
                    entry.key,
                    style: TextStyle(fontSize: fontSize, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// Converts latitude & longitude to pixel position (x, y)
  Offset _convertGeoToXY(LatLng location, BoxConstraints constraints) {
    double mapWidth = constraints.maxWidth;
    double mapHeight = mapWidth * 650 / 579;

    // Adjusted boundary values for better fit
    double minLat = 5.5;
    double maxLat = 36.0;
    double minLon = 66.5;
    double maxLon = 98.0;

    double x = ((location.longitude - minLon) / (maxLon - minLon)) * mapWidth;
    double y = ((maxLat - location.latitude) / (maxLat - minLat)) * mapHeight;

    return Offset(x, y);
  }
}
