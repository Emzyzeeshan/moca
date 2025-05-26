import 'package:flutter/material.dart';
import '../../../datamodel/airports_model.dart';
import '../../../datamodel/state_wise_airport_model.dart';
import 'AirportsViewTappedScreen.dart'; // Import the target screen

class AirportListScreen extends StatelessWidget {
  final List<StateWiseAirportModel> airportList;

  const AirportListScreen({Key? key, required this.airportList}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Airports List")),
      body: airportList.isEmpty
          ? const Center(child: Text("No airports available."))
          : ListView.builder(
        itemCount: airportList.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // You may need to fetch AllAirportsModel using airport data
              final allAirportsModel = AllAirportsModel(
                airportCd: airportList[index].airportCd, // Adjust accordingly
                airportName: airportList[index].airportName,
                // Add other required fields here if necessary
              );

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AirportsViewTappedScreen(data: allAirportsModel),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(
                  airportList[index].airportName.toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
