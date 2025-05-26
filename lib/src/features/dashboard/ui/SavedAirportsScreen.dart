import 'package:hive/hive.dart';

import '../../../../common_imports.dart';
import '../../../core/theme/colors.dart';
import '../../../datamodel/airports_model.dart';
import 'AirportsViewTappedScreen.dart';

class SavedAirportsScreen extends StatefulWidget {
  const SavedAirportsScreen({super.key});

  @override
  State<SavedAirportsScreen> createState() => _SavedAirportsScreenState();
}

class _SavedAirportsScreenState extends State<SavedAirportsScreen> {
  List<Map<String, String>> savedAirports = [];

  Future<void> loadSavedAirports() async {
    var box = await Hive.openBox('moca');
    List<dynamic> airports = box.get('airports', defaultValue: []);
    setState(() {
      savedAirports = airports
          .map<Map<String, String>>((entry) => {
        "code": entry[0],
        "name": entry[1]['Airport Details']['Airport Name']
      })
          .toList();
    });
  }

  Future<void> deleteAirport(String code) async {
    var box = await Hive.openBox('moca');
    List<dynamic> airports = box.get('airports', defaultValue: []);
    airports.removeWhere((entry) => entry[0] == code);
    await box.put('airports', airports);
    await loadSavedAirports(); // Refresh UI
  }

  @override
  void initState() {
    super.initState();
    loadSavedAirports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: ThemeColors.whiteColor),
        title: const Text('Saved Airports', style: TextStyle(color: ThemeColors.whiteColor)),
        backgroundColor: ThemeColors.primaryColor,
      ),
      body: savedAirports.isEmpty
          ? const Center(child: Text("No saved airports."))
          : ListView.builder(
        itemCount: savedAirports.length,
        itemBuilder: (context, index) {
          final airport = savedAirports[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ThemeColors.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                airport['name'] ?? 'Unknown',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Code: ${airport['code']}',
                style: const TextStyle(color: Colors.white70),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                onPressed: () async {
                  await deleteAirport(airport['code']!);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AirportsViewTappedScreen(
                      data: AllAirportsModel(
                        airportCd: airport['code'],
                        airportName: airport['name'],
                      ),
                      isFromSavedScreen: true,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

