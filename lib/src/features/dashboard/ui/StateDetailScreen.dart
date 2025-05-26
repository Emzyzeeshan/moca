import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mocadb/src/core/theme/colors.dart';
import 'package:provider/provider.dart';
import '../../../datamodel/airports_model.dart';
import '../../../datamodel/state_wise_airport_model.dart';
import '../provider/dashboard_provider.dart';
import 'AirportsViewTappedScreen.dart';

class StateDetailScreen extends StatefulWidget {
  final String stateName;

  StateDetailScreen({required this.stateName});

  @override
  _StateDetailScreenState createState() => _StateDetailScreenState();
}

class _StateDetailScreenState extends State<StateDetailScreen> {
  late DashboardProvider dashboardProvider;
  bool isLoading = true;
  List<StateWiseAirportModel> airportList = [];

  @override
  void initState() {
    super.initState();
    dashboardProvider = Provider.of<DashboardProvider>(context, listen: false);
    fetchAirports();
  }

  /// Fetches the airport list for the selected state
  Future<void> fetchAirports() async {
    setState(() => isLoading = true);

    await dashboardProvider.getStateWiseAirportListApiCall(widget.stateName);

    setState(() {
      airportList = dashboardProvider.StateWiseAirportList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    String stateImagePath = _getStateImagePath(widget.stateName);

    return Scaffold(
      appBar: AppBar(title: Text(widget.stateName)),
      body: Column(
        children: [
          // State Image
          Center(
            child: SvgPicture.asset(
              stateImagePath,
              width: double.infinity,
              height: 300,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),

          // Display Airports
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : airportList.isEmpty
                ? const Center(child: Text("No airports found"))
                : ListView.builder(
              itemCount: airportList.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: ThemeColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      airportList[index].airportName.toString(),
                      style: TextStyle(color: ThemeColors.whiteColor),
                    ),
                    onTap: () {
                      final AllAirportsModel convertedData = AllAirportsModel(
                        airportCd: airportList[index].airportCd,
                        airportName: airportList[index].airportName,
                        // Add other fields if necessary
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AirportsViewTappedScreen(
                            data: convertedData, // Now passing AllAirportsModel
                          ),
                        ),
                      );
                    },



                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the correct SVG file path for each state
  String _getStateImagePath(String stateName) {
    return 'assets/svg/Indian_States/$stateName.svg';
  }
}
