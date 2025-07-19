import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:mocadb/src/datamodel/Monitor/arr_dep_track_model.dart';
import 'package:mocadb/src/datamodel/Monitor/top_airlines_model.dart';
import '../../../core/network/network_index.dart';
import '../../../datamodel/Monitor/arrival_model.dart';
import '../../../datamodel/Monitor/date_model.dart';
import '../../../datamodel/Monitor/departure_model.dart';
import '../../../datamodel/Monitor/index_data_model.dart';
import '../../../datamodel/Monitor/top_route_model.dart';
import '../../../datamodel/airports_model.dart';

class MonitorProvider extends ChangeNotifier {
  bool isLoading = false;
  late Box box;
  late String airportCode;
  String? apiSelectedDate;
  DateTime? userSelectedDate;

  void isLoadData(bool isLoading) {
    this.isLoading = isLoading;
    notifyListeners();
  }
  static Future<List<String>> fetchAllAirportCodesOnly() async {
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getAllAirportsUrl,
        apiFunType: APITypes.get,
      );

      if (response.statusCode == 200 && response.body is List) {
        return (response.body as List)
            .map((e) => AllAirportsModel.fromJson(e).airportCd ?? "")
            .where((code) => code.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint("MonitorProvider fetchAllAirportCodesOnly error: $e");
    }

    return [];
  }

  //********************************GET ALL AIRPORT API CALL**********************************//
  AllAirportsModel? selectedAllAirport;
  List<AllAirportsModel> allAirportsList = [];

  Future<void> getAllAirportListApiCall() async {
    isLoadData(true);
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getAllAirportsUrl,
        apiFunType: APITypes.get,
      );

      if (response.statusCode == 200) {
        allAirportsList = (response.body as List)
            .map((e) => AllAirportsModel.fromJson(e))
            .toList();

        if (allAirportsList.isNotEmpty) {
          selectedAllAirport = allAirportsList.first;
        }
      }
    } catch (e) {
      debugPrint("Airport fetch error: $e");
    }
    isLoadData(false);
  }

  Future<void> updateSelectedAirport(AllAirportsModel newAirport) async {
    selectedAllAirport = newAirport;
    notifyListeners();
    await postDateApi(airportCd: newAirport.airportCd ?? "");
    await fetchAllApis(airportCd: newAirport.airportCd ?? "");
  }

  Future<void> fetchAllApis({required String airportCd}) async {
    final String dateToSend = userSelectedDate != null
        ? DateFormat('yyyy-MM-dd').format(userSelectedDate!)
        : apiSelectedDate ?? "";

    await postArrivalApiCall(airportCd: airportCd, selectedDate: dateToSend);
    await postDepartureApiCall(airportCd: airportCd,  selectedDate: dateToSend);
    await postTopRoutes(airportCd: airportCd, selectedDate: dateToSend);
    await postTopAirlines(airportCd: airportCd,  selectedDate: dateToSend);
    await postIndexData(airportCd: airportCd,  selectedDate: dateToSend);
    await postArrDepTrackApi(airportCd: airportCd, selectedDate: dateToSend);
  }

  //********************************GET ARRIVAL API CALL**********************************//
  ArrivalModel? selectedArrivalModel;
  List<ArrivalModel> allArrivalList = [];

  Future<void> postArrivalApiCall({required String airportCd,  required String selectedDate}) async {
    isLoadData(true);
    selectedArrivalModel = null;
    allArrivalList.clear();

    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getArrUrl,
        apiFunType: APITypes.post,
        sendingData: {
          "airportCd": airportCd,
          "Type": "ARR",
          "Date": selectedDate,
        },
      );

      if (response.statusCode == 200) {
        final body = response.body;
        if (body is List) {
          allArrivalList = body
              .map<ArrivalModel>((e) => ArrivalModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          selectedArrivalModel = allArrivalList.isNotEmpty ? allArrivalList.first : null;
        } else if (body is Map) {
          final model = ArrivalModel.fromJson(Map<String, dynamic>.from(body));
          allArrivalList = [model];
          selectedArrivalModel = model;
        }
      }
    } catch (e) {
      debugPrint("Arrival fetch error: $e");
    }
    isLoadData(false);
    notifyListeners();
  }

  //********************************GET DEPARTURE API CALL**********************************//
  DepartureModel? selectedDepartureModel;
  List<DepartureModel> allDepartureList = [];

  Future<void> postDepartureApiCall({required String airportCd,  required String selectedDate}) async {
    isLoadData(true);
    selectedDepartureModel = null;
    allDepartureList.clear();

    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getDepUrl,
        apiFunType: APITypes.post,
        sendingData: {
          "airportCd": airportCd,
          "Type": "DEP",
          "Date": selectedDate,
        },
      );

      if (response.statusCode == 200) {
        final body = response.body;
        if (body is List) {
          allDepartureList = body
              .map<DepartureModel>((e) => DepartureModel.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          selectedDepartureModel = allDepartureList.isNotEmpty ? allDepartureList.first : null;
        } else if (body is Map) {
          final model = DepartureModel.fromJson(Map<String, dynamic>.from(body));
          allDepartureList = [model];
          selectedDepartureModel = model;
        }
      }
    } catch (e) {
      debugPrint("Departure fetch error: $e");
    }
    isLoadData(false);
    notifyListeners();
  }

  //********************************GET TOP ROUTES API CALL**********************************//
  TopRouteModel? selectedTopRouteModel;

  Future<void> postTopRoutes({required String airportCd, required String selectedDate}) async {
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getTopRoutesUrl,
        apiFunType: APITypes.post,
        sendingData: {
          "airportCd": airportCd,
          "Date": selectedDate,
        },
      );

      if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
        selectedTopRouteModel = TopRouteModel.fromJson(response.body);
      } else {
        selectedTopRouteModel = TopRouteModel(topRoutes: []);
      }
    } catch (e) {
      debugPrint("Top Routes fetch error: $e");
      selectedTopRouteModel = TopRouteModel(topRoutes: []);
    }
    notifyListeners();
  }

  //********************************GET TOP AIRLINES API CALL**********************************//
  TopAirlinesModel? selectedTopAirlinesModel;

  Future<void> postTopAirlines({required String airportCd,  required String selectedDate}) async {
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getTopAirlinesUrl,
        apiFunType: APITypes.post,
        sendingData: {
          "airportCd": airportCd,
          "Date": selectedDate,
        },
      );

      if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
        selectedTopAirlinesModel = TopAirlinesModel.fromJson(response.body);
      } else {
        selectedTopAirlinesModel = TopAirlinesModel(topAirlines: []);
      }
    } catch (e) {
      debugPrint("Top Airlines fetch error: $e");
    }
    notifyListeners();
  }

  //********************************GET ARRIVAL DEPARTURE TRACK API CALL**********************************//
  ArrDepTrackModel? selectedArrDepTrackModel;

  Future<void> postArrDepTrackApi({required String airportCd, required String selectedDate}) async {
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getArrDepTrackUrl,
        apiFunType: APITypes.post,
        sendingData: {
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
        selectedArrDepTrackModel = ArrDepTrackModel.fromJson(response.body);
      } else {
        selectedArrDepTrackModel = ArrDepTrackModel(vOMMAirportArrivalsAdnDepartures: []);
      }
    } catch (e) {
      debugPrint("Arrival Departure Track fetch error: $e");
    }
    notifyListeners();
  }

  //********************************GET INDEX DATA API CALL**********************************//
  IndexDataModel? indexDataModel;

  Future<void> postIndexData({required String airportCd, required String selectedDate}) async {
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getIndexUrl,
        apiFunType: APITypes.post,
        sendingData: {
          "airportCd": airportCd,
          "Date": selectedDate,
        },
      );

      if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
        indexDataModel = IndexDataModel.fromJson(response.body);
      } else {
        indexDataModel = IndexDataModel(indexData: []);
      }
    } catch (e) {
      debugPrint("Index Data fetch error: $e");
    }
    notifyListeners();
  }

  //********************************GET DATE API CALL**********************************//
  DateModel? selectedDateModel;

  Future<void> postDateApi({required String airportCd}) async {
    try {
      final response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getDateUrl,
        apiFunType: APITypes.post,
        sendingData: {
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200 && response.body is Map<String, dynamic>) {
        final model = DateModel.fromJson(response.body);
        selectedDateModel = model;
        apiSelectedDate = model.mocadbDate;
      } else {
        selectedDateModel = DateModel(mocadbDate: "");
        apiSelectedDate = null;
      }
    } catch (e) {
      debugPrint("Date API fetch error: $e");
    }
    notifyListeners();
  }

  void notifyToAllValues() => notifyListeners();
}
