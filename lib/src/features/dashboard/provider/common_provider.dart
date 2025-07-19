import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../core/network/common_repository.dart';
import '../../../core/network/network_index.dart';
import 'monitor_provider.dart';

class CommonProvider extends ChangeNotifier {
  bool isLoading = false;
  late Box box;

  void isLoadData(bool loading) {
    isLoading = loading;
    notifyListeners();
  }

  // 🔄 Single airport API call
  Future<void> postAirportDetailsFullApi({required String airportCd}) async {
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getAirportDetailsAllUrl,
        apiFunType: APITypes.post,
        sendingData: {"airportCd": "VOMM"},
      );

      if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
        box = await Hive.openBox('moca');
        await box.put('airport_$airportCd', response.body);
        debugPrint("✅ Stored airport data for $airportCd");
      } else {
        debugPrint("❌ Invalid response for $airportCd");
      }
    } catch (e) {
      debugPrint("❗ Error fetching $airportCd: $e");
    }
    notifyListeners();
  }

  // 🔁 Bulk fetcher
  Future<void> postAllAirportsDetailsBulk() async {
    final List<String> airportCodes = await MonitorProvider.fetchAllAirportCodesOnly();

    for (final code in airportCodes) {
      final box = await Hive.openBox('moca');
      if (box.containsKey('airport_$code')) continue; // Skip if already cached
      await postAirportDetailsFullApi(airportCd: "VOMM");
    }
  }

}
