import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/style.dart';
import '../../../core/constants/constant_text.dart';
import '../../../datamodel/airports_model.dart';
import '../../../datamodel/state_wise_airport_model.dart';
import '../../../features/widgets/custom_text.dart';
import '../../../features/widgets/custom_text_form.dart';
import 'AirportsViewTappedScreen.dart';
import 'airport_flight_map_screen.dart';

class AirportListScreen extends StatefulWidget {
  final List<StateWiseAirportModel> airportList;

  const AirportListScreen({Key? key, required this.airportList}) : super(key: key);

  @override
  State<AirportListScreen> createState() => _AirportListScreenState();
}

class _AirportListScreenState extends State<AirportListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<StateWiseAirportModel> _filteredAirports = [];

  @override
  void initState() {
    super.initState();
    _filteredAirports = widget.airportList;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredAirports = query.isNotEmpty
          ? widget.airportList.where((airport) {
        final name = airport.airportName?.toLowerCase() ?? '';
        return name.contains(query);
      }).toList()
          : widget.airportList;
    });
  }

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Airports List")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomTextFormField(
              controller: _searchController,
              focusNode: _searchFocus,
              labelText: "Search Airport Name",
              onChanged: (_) => setState(() {}),
              inputFormatters: [LengthLimitingTextInputFormatter(30)],
              suffixIcon: _searchController.text.isEmpty
                  ? const Icon(Icons.search)
                  : IconButton(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.cancel_outlined, color: ThemeColors.orangeColor),
              ),
            ),
          ),
          Expanded(
            child: _filteredAirports.isEmpty
                ? const Center(child: Text("No airports available."))
                : ListView.builder(
              itemCount: _filteredAirports.length,
              itemBuilder: (context, index) {
                final airport = _filteredAirports[index];

                final allAirportsModel = AllAirportsModel(
                  airportCd: airport.airportCd,
                  airportName: airport.airportName,
                );

                return GestureDetector(
                  onTap: () => _showOptionsDialog(context, allAirportsModel),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        airport.airportName ?? 'Unnamed Airport',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
