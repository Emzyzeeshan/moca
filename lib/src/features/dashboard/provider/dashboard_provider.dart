import 'package:hive/hive.dart';
import 'package:mocadb/src/datamodel/AirportDetails/cargo_tonnage_model.dart';

import '../../../../common_imports.dart';
import '../../../core/constants/constant_text.dart';
import '../../../core/network/network_index.dart';
import '../../../datamodel/AirportDetails/FilterParamsModel.dart';
import '../../../datamodel/AirportDetails/airport_details_model.dart';
import '../../../datamodel/AirportDetails/arrival_schedule_model.dart';
import '../../../datamodel/AirportDetails/departure_schedule_model.dart';
import '../../../datamodel/AirportDetails/movement_details_model.dart';
import '../../../datamodel/AirportDetails/passenger_footfall_model.dart';
import '../../../datamodel/airports_model.dart';
import '../../../datamodel/filter_airport_model.dart';
import '../../../datamodel/groups_Model.dart';
import '../../../datamodel/state_wise_airport_model.dart';
import '../../../datamodel/states_model.dart';
import '../ui/AirportListScreen.dart';
import 'monitor_provider.dart';

class DashboardProvider extends ChangeNotifier {
  bool isLoading = false;
  late Box box;
  late String airportCode;
  Map<String, dynamic>? combinedOtp;
  void isLoadData(bool isLoading) {
    this.isLoading = isLoading;
    //  notifyListeners();
  }
  bool showMonitorAndDirectoryButtons = true;
  void _updateCombinedOtp() {
    if (selectedOtp != null || selectedOtpDep != null) {
      combinedOtp = {
        'arrival': selectedOtp ?? {},
        'departure': selectedOtpDep ?? {},
      };
      notifyListeners();
    }
  }
  FilterParamsModel? _filterParams;

  FilterParamsModel? get filterParams => _filterParams;

  void setFilterParams(FilterParamsModel params) {
    _filterParams = params;
    notifyListeners();
  }

  void clearFilterParams() {
    _filterParams = null;
    notifyListeners();
  }
  void toggleMonitorAndDirectoryVisibility() {
    showMonitorAndDirectoryButtons = !showMonitorAndDirectoryButtons;
    notifyListeners();
  }
  final TextEditingController AirportNameController = TextEditingController();
  final FocusNode AirportNameFocusNode = FocusNode();
//********************************PUT FILTER AIRPORT API CALL**********************************//
  Future<List<StateWiseAirportModel>?> postFilterAirportListApiCall(
      FilterAirportsModel postData, DashboardProvider dashboardProvider, BuildContext context) async {
    final HTTPResponse<dynamic> response = await ApiCalling.callApi(
      apiUrl: AppUrls.postFilterAirportUrl,
      apiFunType: APITypes.post,
      sendingData: postData.toJson(),
    );

    if (response.statusCode == 200) {
      List<dynamic> responseList = response.body;
      List<StateWiseAirportModel> stateWiseAirports =
      responseList.map((json) => StateWiseAirportModel.fromJson(json)).toList();
      notifyToAllValues();
      return stateWiseAirports;
    } else {
      String errorMessage = response.body;
      if (errorMessage.isEmpty) {
        errorMessage = ConstantMessage.somethingWentWrongPleaseTryAgain;
      }
      EasyLoading.showError(errorMessage);
      return null;
    }
  }


  //********************************GET ALL AIRPORTS LIST API CALL**********************************//
  AllAirportsModel? selectedAllAirports;
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
          selectedAllAirports = allAirportsList.first;
          // Do NOT call other APIs here.
        }
      }
    } catch (e) {
      debugPrint("Airport fetch error: $e");
    }
    isLoadData(false);
  }



  //********************************GET ALL STATES LIST API CALL**********************************//
  AllStatesModel? selectedAllStates;
  List<AllStatesModel> allStatesList = [];
  Future<void> getAllStatesListApiCall() async {
    isLoadData(true);
    selectedAllStates = null;
    final HTTPResponse<dynamic> response = await ApiCalling.callApi(
      isLoading: false,
      apiUrl: AppUrls.getAllStatesUrl,
      apiFunType: APITypes.get,
    );
    if (response.statusCode == 200) {
      allStatesList = (response.body as List<dynamic>)
          .map((e) => AllStatesModel.fromJson(e))
          .toList();
      // schemaGetModel = schemaCodeList.first;
      print('Water Size List loaded: $allStatesList');
    }
    isLoadData(false);
    notifyToAllValues();
  }


  //********************************GET STATE WISE AIRPORT API CALL**********************************//
  StateWiseAirportModel? selectedStateWiseAirport;
  List<StateWiseAirportModel> StateWiseAirportList = <StateWiseAirportModel>[];
  Future<void> getStateWiseAirportListApiCall(String stateName) async {
    isLoadData(true);
    StateWiseAirportList = <StateWiseAirportModel>[];
    selectedStateWiseAirport = null;

    // Find the state object from the list
    selectedAllStates = allStatesList.firstWhere(
          (state) => state.statename == stateName,
      orElse: () => AllStatesModel(statecode: ""),
    );

    if (selectedAllStates?.statecode == "") {
      print("Error: State code not found for $stateName");
      isLoadData(false);
      return;
    }

    final HTTPResponse<dynamic> response = await ApiCalling.callApi(
      apiUrl: AppUrls.getStateWiseAirportsUrl,
      apiFunType: APITypes.post,
      sendingData: <String, dynamic>{
        'statecode': selectedAllStates?.statecode,
      },
    );

    if (response.statusCode == 200) {
      StateWiseAirportList = (response.body as List<dynamic>)
          .map((e) => StateWiseAirportModel.fromJson(e))
          .toList();
      selectedStateWiseAirport = StateWiseAirportList.firstOrNull;
    }
    isLoadData(false);
    notifyToAllValues();
  }

//********************************GET GROUPS API CALL**********************************//
  GroupsModel? selectedGroups;
  List<GroupsModel> groupsList = [];
  Future<List<Map<String, dynamic>>?> getGroupsListApiCall() async {
    isLoadData(true);
    selectedGroups = null;

      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getGroupsUrl,
        apiFunType: APITypes.get,
      );


      print(response.statusCode);
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> groupsData = (response.body as List<dynamic>)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        groupsList = groupsData.map((e) => GroupsModel.fromJson(e)).toList();
        print('✅ Groups List loaded: $groupsList');
        groupsList.forEach((g) => print(g.toJson()));

        isLoadData(false);
        notifyToAllValues();
        return groupsData; // ✅ Returning the data
      } else {
        if(box != null) {
          List airports = box.get('airports');
          if(airports.isNotEmpty) {
            List<Map<String, dynamic>> groupsData = (airports.first[1]['groupsList'] as List<dynamic>)
                .map((e) => Map<String, dynamic>.from(e))
                .toList();

            groupsList = groupsData.map((e) => GroupsModel.fromJson(e)).toList();
            print('✅ Groups List loaded from hive: $groupsList');
            groupsList.forEach((g) => print(g.toJson()));

            isLoadData(false);
            notifyToAllValues();
            return groupsData;
          }
        }
      }

    isLoadData(false);
    print('null groups');
    return null; // If API call fails
  }
  //********************************GET AIRPORT DETAILS API CALL**********************************//
  AirportDetailsModel? selectedAirportDetails;
  List<AirportDetailsModel> airportDetailsList = [];
  //List<String> allAirportsImagesList = [];
  Future<void> getAirportDetailsListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getAirportDetailsUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;

        if (data is Map<String, dynamic>) {
          // Parse JSON into model
          selectedAirportDetails = AirportDetailsModel.fromJson(data);
          notifyListeners(); // Notify UI update
        } else {
          print("⚠ Unexpected API response format: $data");
          selectedAirportDetails = null;
        }
      } else {
        print("❌ Failed to fetch airport details. Status Code: ${response.statusCode}");
        selectedAirportDetails = null;
        print('selectedAirportDetails airportCd');
        print(airportCd);
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            print(selectedAirport['Airport Details']);
            selectedAirportDetails = AirportDetailsModel.fromJson(selectedAirport['Airport Details']);
            notifyListeners(); // Notify UI update
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching airport details: $e");
      selectedAirportDetails = null;
    }
  }


  //********************************GET PASSENGER PEAK API CALL**********************************//
  Map<String, dynamic>? selectedPassengerPeak;
  List<Map<String, dynamic>> passengerPeakList = [];

  Future<void> getPassengerPeakListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getPassengerPeakUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List && data.isNotEmpty) {
          passengerPeakList = data.cast<Map<String, dynamic>>();
          selectedPassengerPeak = passengerPeakList.first;
          print("✅ Passenger Peak Data Set: $selectedPassengerPeak");
        } else {
          print("⚠ Unexpected API response format or empty list.");
          passengerPeakList.clear();
          selectedPassengerPeak = null;
        }
      } else {
        print("❌ Failed to fetch passenger peak data. Status Code: ${response.statusCode}");
        passengerPeakList.clear();
        selectedPassengerPeak = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedPassengerPeak = (selectedAirport['Passenger Footfall']);
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching passenger peak data: $e");
      passengerPeakList.clear();
      selectedPassengerPeak = null;
    }

    notifyListeners(); // Notify UI about the update
  }


  //********************************GET PASSENGER MPPA API CALL**********************************//
  Map<String, dynamic>? selectedPassengerMppa;
  List<Map<String, dynamic>> passengerMppaList = [];

  Future<void> getPassengerMppaListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getPassengerMPPAUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;

        if (data is List && data.isNotEmpty) {
          passengerMppaList = data.cast<Map<String, dynamic>>();
          selectedPassengerMppa = passengerMppaList.first; // Select the first item by default
        } else {
          print("⚠ Unexpected API response format or empty list: $data");
          passengerMppaList.clear();
          selectedPassengerMppa = null;
        }
      } else {
        print("❌ Failed to fetch passenger MPPA data. Status Code: ${response.statusCode}");
        passengerMppaList.clear();
        selectedPassengerMppa = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedPassengerMppa = selectedAirport['Total Handling Capacity (MPPA)'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching passenger MPPA data: $e");
      passengerMppaList.clear();
      selectedPassengerMppa = null;
    }

    notifyListeners(); // Notify UI about the update
  }


  //********************************GET PASSENGER FOOTFALL API CALL**********************************//
  PassengerFootFallModel? selectedPassengerFootfall;
  List<PassengerFootFallModel> passengerFootFallList = [];

  Future<void> getPassengerFootFallListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getPassengerFootFallUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is Map<String, dynamic> && data.containsKey('financialData')) {
          passengerFootFallList = [
            PassengerFootFallModel.fromJson(data as Map<String, dynamic>)
          ];
          selectedPassengerFootfall = passengerFootFallList.first;
          print("✅ Parsed Passenger FootFall: ${selectedPassengerFootfall?.financialData.length}");
        } else if (data is List) {
          passengerFootFallList = data
              .map((e) => PassengerFootFallModel.fromJson(e as Map<String, dynamic>))
              .toList();
          selectedPassengerFootfall = passengerFootFallList.isNotEmpty ? passengerFootFallList.first : null;
        } else {
          print("⚠ API returned an incorrect format.");
          passengerFootFallList.clear();
          selectedPassengerFootfall = null;
        }
      } else {
        print("❌ Failed to fetch passenger footfall data. Status Code: ${response.statusCode}");
        passengerFootFallList.clear();
        selectedPassengerFootfall = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedPassengerFootfall = PassengerFootFallModel.fromJson(selectedAirport['Passenger Trends']);
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching passenger footfall data: $e");
      passengerFootFallList.clear();
      selectedPassengerFootfall = null;
    }

    notifyListeners(); // Notify UI about the update
  }


//********************************GET CONNECTIVITY API CALL**********************************//
  Map<String, dynamic>? selectedConnectivity;
  List<Map<String, dynamic>> connectivityList = [];

  Future<void> getConnectivityListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getConnectivityUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          connectivityList = data.cast<Map<String, dynamic>>();
          selectedConnectivity = connectivityList.isNotEmpty ? connectivityList.first : null;
          print("✅ Parsed Connectivity: $selectedConnectivity");
        } else {
          print("⚠ API returned an incorrect format.");
          connectivityList.clear();
          selectedConnectivity = null;
        }
      } else {
        print("❌ Failed to fetch connectivity data. Status Code: ${response.statusCode}");
        connectivityList.clear();
        selectedConnectivity = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedConnectivity = selectedAirport['Connectivity'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching connectivity data: $e");
      connectivityList.clear();
      selectedConnectivity = null;
    }

    notifyListeners(); // Notify UI about the update
  }


//********************************GET DESTINATION API CALL**********************************//
  Map<String, dynamic>? selectedDestinations;
  List<Map<String, dynamic>> destinationsList = [];

  Future<void> getDestinationListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getDestinationUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("\ud83d\udd0d API Response: \$data"); // Debugging

        if (data is List) {
          destinationsList = data.cast<Map<String, dynamic>>();
          selectedDestinations = destinationsList.isNotEmpty ? destinationsList.first : null;
          print("✅ Parsed Destinations: \$selectedDestinations");
        } else {
          print("⚠ API returned an incorrect format.");
          destinationsList.clear();
          selectedDestinations = null;
        }
      } else {
        print("❌ Failed to fetch destination data. Status Code: \${response.statusCode}");
        destinationsList.clear();
        selectedDestinations = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedDestinations = selectedAirport['Destinations'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching destination data: \$e");
      destinationsList.clear();
      selectedDestinations = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET RCS CONNECTIVITY API CALL**********************************//
  Map<String, dynamic>? selectedRcsConnectivity;
  List<Map<String, dynamic>> rcsConnectivityList = [];

  Future<void> getRcsConnectivityListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getRcsConnectivityUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          rcsConnectivityList = data.cast<Map<String, dynamic>>();
          selectedRcsConnectivity = rcsConnectivityList.isNotEmpty ? rcsConnectivityList.first : null;
          print("✅ Parsed RCS Connectivity: $selectedRcsConnectivity");
        } else {
          print("⚠ API returned an incorrect format.");
          rcsConnectivityList.clear();
          selectedRcsConnectivity = null;
        }
      } else {
        print("❌ Failed to fetch RCS connectivity data. Status Code: ${response.statusCode}");
        rcsConnectivityList.clear();
        selectedRcsConnectivity = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedRcsConnectivity = selectedAirport['RCS Connectivity'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching RCS connectivity data: $e");
      rcsConnectivityList.clear();
      selectedRcsConnectivity = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET RCS ROUTE AND OPERATOR API CALL**********************************//
  Map<String, dynamic>? selectedRCSRouteAndOperator;
  List<Map<String, dynamic>> RCSRouteAndOperatorList = [];

  Future<void> getRCSRouteAndOperatorListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getRcsRouteOperatorUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          RCSRouteAndOperatorList = data.cast<Map<String, dynamic>>();
          selectedRCSRouteAndOperator = RCSRouteAndOperatorList.isNotEmpty ? RCSRouteAndOperatorList.first : null;
          print("✅ Parsed RCS Route And Operator: $selectedRCSRouteAndOperator");
        } else {
          print("⚠ API returned an incorrect format.");
          RCSRouteAndOperatorList.clear();
          selectedRCSRouteAndOperator = null;
        }
      } else {
        print("❌ Failed to fetchRCS Route And Operator data. Status Code: ${response.statusCode}");
        RCSRouteAndOperatorList.clear();
        selectedRCSRouteAndOperator = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedRCSRouteAndOperator = selectedAirport['RCS Route And Operator'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching RCS Route And Operator data: $e");
      RCSRouteAndOperatorList.clear();
      selectedRCSRouteAndOperator = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET PEAK PERIOD API CALL**********************************//
  Map<String, dynamic>? selectedPeakPeriod;
  List<Map<String, dynamic>> PeakPeriodList = [];

  Future<void> getPeakPeriodListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getPeakPeriodUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          PeakPeriodList = data.cast<Map<String, dynamic>>();
          selectedPeakPeriod = PeakPeriodList.isNotEmpty ? PeakPeriodList.first : null;
          print("✅ Parsed Peak Period: $selectedPeakPeriod");
        } else {
          print("⚠ API returned an incorrect format.");
          PeakPeriodList.clear();
          selectedPeakPeriod = null;
        }
      } else {
        print("❌ Failed to fetch Peak Period data. Status Code: ${response.statusCode}");
        PeakPeriodList.clear();
        selectedPeakPeriod = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedPeakPeriod = selectedAirport['Peak Period'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Peak Period data: $e");
      PeakPeriodList.clear();
      selectedPeakPeriod = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET AVERAGE PER DAY FOOTFALL API CALL**********************************//
  Map<String, dynamic>? selectedAveragePerDayFootFall;
  List<Map<String, dynamic>> AveragePerDayFootFallList = [];

  Future<void> getAveragePerDayFootFallListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getAvgPerDayFootfallUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          AveragePerDayFootFallList = data.cast<Map<String, dynamic>>();
          selectedAveragePerDayFootFall = AveragePerDayFootFallList.isNotEmpty ? AveragePerDayFootFallList.first : null;
          print("✅ Parsed Average Per Day Footfall: $selectedAveragePerDayFootFall");
        } else {
          print("⚠ API returned an incorrect format.");
          AveragePerDayFootFallList.clear();
          selectedAveragePerDayFootFall = null;
        }
      } else {
        print("❌ Failed to fetch Average Per Day Footfall data. Status Code: ${response.statusCode}");
        AveragePerDayFootFallList.clear();
        selectedAveragePerDayFootFall = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedAveragePerDayFootFall = selectedAirport['Average Per Day Footfall'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Average Per Day Footfall data: $e");
      AveragePerDayFootFallList.clear();
      selectedAveragePerDayFootFall = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET CARGO CAPACITY API CALL**********************************//
  Map<String, dynamic>? selectedCargoCapacity;
  List<Map<String, dynamic>> cargoCapacityList = [];

  Future<void> getCargoCapacityApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getCargoCapacityUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          cargoCapacityList = data.cast<Map<String, dynamic>>();
          selectedCargoCapacity = cargoCapacityList.isNotEmpty ? cargoCapacityList.first : null;
          print("✅ Parsed Cargo Capacity: $selectedCargoCapacity");
        } else {
          print("⚠ API returned an incorrect format.");
          cargoCapacityList.clear();
          selectedCargoCapacity = null;
        }
      } else {
        print("❌ Failed to fetch Cargo Capacity data. Status Code: ${response.statusCode}");
        cargoCapacityList.clear();
        selectedCargoCapacity = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedCargoCapacity = selectedAirport['Cargo - Capacity (MTPA)'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Cargo Capacity data: $e");
      cargoCapacityList.clear();
      selectedCargoCapacity = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET CARGO OPERATOR API CALL**********************************//
  Map<String, dynamic>? selectedCargoOperator;
  List<Map<String, dynamic>> cargoOperatorList = [];

  Future<void> getCargoOperatorApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getCargoOperatorUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          cargoOperatorList = data.cast<Map<String, dynamic>>();
          selectedCargoOperator = cargoOperatorList.isNotEmpty ? cargoOperatorList.first : null;
          print("✅ Parsed Cargo Operator: $selectedCargoOperator");
        } else {
          print("⚠ API returned an incorrect format.");
          cargoOperatorList.clear();
          selectedCargoOperator = null;
        }
      } else {
        print("❌ Failed to fetch Cargo Operator data. Status Code: ${response.statusCode}");
        cargoOperatorList.clear();
        selectedCargoOperator = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedCargoOperator = selectedAirport['Cargo Operator'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Cargo Operator data: $e");
      cargoOperatorList.clear();
      selectedCargoOperator = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET APD DETAILS API CALL**********************************//
  Map<String, dynamic>? selectedApdDetails;
  List<Map<String, dynamic>> apdDetailsList = [];

  Future<void> getApdDetailsApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getAPDUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          apdDetailsList = data.cast<Map<String, dynamic>>();
          selectedApdDetails = apdDetailsList.isNotEmpty ? apdDetailsList.first : null;
          print("✅ Parsed APD Details: $selectedApdDetails");
        } else {
          print("⚠ API returned an incorrect format.");
          apdDetailsList.clear();
          selectedApdDetails = null;
        }
      } else {
        print("❌ Failed to fetch APD Details data. Status Code: ${response.statusCode}");
        apdDetailsList.clear();
        selectedApdDetails = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedApdDetails = selectedAirport['APD Details'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching APD Details data: $e");
      apdDetailsList.clear();
      selectedApdDetails = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET WORK IN PROGRESS API CALL**********************************//
  List<Map<String, dynamic>> workInProgressList = [];

  Future<void> getWorkInProgressApiCall({
    required String airportCd,
    dynamic box,
  }) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getWorkUrl,
        apiFunType: APITypes.post,
        sendingData: {"airportCd": airportCd},
      );

      if (response.statusCode == 200 && response.body is List) {
        workInProgressList = response.body.cast<Map<String, dynamic>>();
      } else {
        // Fallback to Hive
        if (box != null) {
          final airports = box.get('airports');
          final matching = airports.firstWhere((a) => a[0] == airportCd, orElse: () => null);
          if (matching != null) {
            final offlineData = Map<String, dynamic>.from(
              (matching[1] as Map).map((key, value) => MapEntry(key.toString(), value)),
            );

            final list = offlineData['Work In Progress'];
            if (list is List) {
              workInProgressList = List<Map<String, dynamic>>.from(
                list.map((item) => Map<String, dynamic>.from(
                  (item as Map).map((k, v) => MapEntry(k.toString(), v)),
                )),
              );
              debugPrint('📦 Fallback WIP loaded from Hive');
            }
          }
        }
      }
    } catch (e) {
      debugPrint("🚨 WIP Exception: $e");
      workInProgressList = [];

      // Load from box if available
      if (box != null) {
        final airports = box.get('airports');
        final matching = airports.firstWhere((a) => a[0] == airportCd, orElse: () => null);
        if (matching != null) {
          final offlineData = Map<String, dynamic>.from(
            (matching[1] as Map).map((key, value) => MapEntry(key.toString(), value)),
          );

          final list = offlineData['Work In Progress'];
          if (list is List) {
            workInProgressList = List<Map<String, dynamic>>.from(
              list.map((item) => Map<String, dynamic>.from(
                (item as Map).map((k, v) => MapEntry(k.toString(), v)),
              )),
            );
            debugPrint('📦 Fallback WIP loaded from Hive');
          }
        }
      }

    }

    notifyListeners();
  }




  //********************************GET WORK PLANNED API CALL**********************************//
  List<Map<String, dynamic>> workPlannedList = [];

  Future<void> getWorkPlannedApiCall({required String airportCd, dynamic box}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getWorkPlanUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{"airportCd": airportCd},
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data");

        if (data is List) {
          workPlannedList = data.cast<Map<String, dynamic>>();
        } else {
          print("⚠ API returned an incorrect format.");
          workPlannedList.clear();
        }
      } else {
        print("❌ Failed to fetch Work Planned data. Status Code: ${response.statusCode}");
        workPlannedList.clear();

        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            final matching = airports.firstWhere((a) => a[0] == airportCd, orElse: () => null);
            if (matching != null) {
              final offlineData = Map<String, dynamic>.from(
                (matching[1] as Map).map((k, v) => MapEntry(k.toString(), v)),
              );
              final list = offlineData['Works Planned'];
              if (list is List) {
                workPlannedList = List<Map<String, dynamic>>.from(
                  list.map((item) => Map<String, dynamic>.from(
                    (item as Map).map((k, v) => MapEntry(k.toString(), v)),
                  )),
                );
                debugPrint('📦 Fallback WP loaded from Hive');
              }
            }

          }
        }
      }
    } catch (e) {
      debugPrint("🚨 WP Exception: $e");
      if (box != null) {
        List airports = box.get('airports');
        final matching = airports.firstWhere((a) => a[0] == airportCd, orElse: () => null);
        if (matching != null) {
          final offlineData = Map<String, dynamic>.from(
            (matching[1] as Map).map((k, v) => MapEntry(k.toString(), v)),
          );
          final list = offlineData['Works Planned'];
          if (list is List) {
            workPlannedList = List<Map<String, dynamic>>.from(
              list.map((item) => Map<String, dynamic>.from(
                (item as Map).map((k, v) => MapEntry(k.toString(), v)),
              )),
            );
          }
        }
      }

    }

    notifyListeners();
  }


  //********************************GET COMPLETED WORKS API CALL**********************************//
  List<Map<String, dynamic>> completedWorksList = [];

  Future<void> getCompletedWorksApiCall({required String airportCd, dynamic box}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getWorkCompleteUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{"airportCd": airportCd},
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data");

        if (data is List) {
          completedWorksList = data.cast<Map<String, dynamic>>();
        } else {
          print("⚠ API returned an incorrect format.");
          completedWorksList.clear();
        }
      } else {
        print("❌ Failed to fetch Completed Works data. Status Code: ${response.statusCode}");
        completedWorksList.clear();

        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            final matching = airports.firstWhere((a) => a[0] == airportCd, orElse: () => null);
            if (matching != null) {
              final offlineData = Map<String, dynamic>.from(
                (matching[1] as Map).map((k, v) => MapEntry(k.toString(), v)),
              );
              final list = offlineData['Completed Works'];
              if (list is List) {
                completedWorksList = List<Map<String, dynamic>>.from(
                  list.map((item) => Map<String, dynamic>.from(
                    (item as Map).map((k, v) => MapEntry(k.toString(), v)),
                  )),
                );

              }
            }

          }
        }
      }
    } catch (e) {
      debugPrint("🚨 work complete Exception: $e");
      if (box != null) {
        debugPrint("🚨 work complete Exception: $e");
        List airports = box.get('airports');
        final matching = airports.firstWhere((a) => a[0] == airportCd, orElse: () => null);
        if (matching != null) {
          final offlineData = Map<String, dynamic>.from(
            (matching[1] as Map).map((k, v) => MapEntry(k.toString(), v)),
          );
          final list = offlineData['Completed Works'];
          if (list is List) {
            completedWorksList = List<Map<String, dynamic>>.from(
              list.map((item) => Map<String, dynamic>.from(
                (item as Map).map((k, v) => MapEntry(k.toString(), v)),
              )),
            );
            debugPrint('📦 Fallback work complete loaded from Hive');
          }
        }
      }

    }

    notifyListeners();
  }


  //********************************GET ASSISTANCE REQUIRED API CALL**********************************//
  List<Map<String, dynamic>> assistanceRequiredList = [];

  Future<void> getAssistanceRequiredApiCall({required String airportCd, dynamic box}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getAssistanceUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{"airportCd": airportCd},
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data");

        if (data is List) {
          assistanceRequiredList = data.cast<Map<String, dynamic>>();
        } else {
          print("⚠ API returned an incorrect format.");
          assistanceRequiredList.clear();
        }
      } else {
        print("❌ Failed to fetch Assistance Required data. Status Code: ${response.statusCode}");
        assistanceRequiredList.clear();

        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            final matching = airports.firstWhere((a) => a[0] == airportCd, orElse: () => null);
            if (matching != null) {
              final offlineData = Map<String, dynamic>.from(
                (matching[1] as Map).map((k, v) => MapEntry(k.toString(), v)),
              );
              final list = offlineData['Assistance Required'];
              if (list is List) {
                assistanceRequiredList = List<Map<String, dynamic>>.from(
                  list.map((item) => Map<String, dynamic>.from(
                    (item as Map).map((k, v) => MapEntry(k.toString(), v)),
                  )),
                );
              }
            }
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Assistance Required data: $e");
      assistanceRequiredList.clear();
    }

    notifyListeners();
  }


  //********************************GET GREEN INITIATIVE API CALL**********************************//
  Map<String, dynamic>? selectedGreenInitiative;
  List<Map<String, dynamic>> greenInitiativeList = [];

  Future<void> getGreenInitiativeApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getGreenInitiativeUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        // Instead of checking if data is List, check if it's a Map.
        if (data is Map<String, dynamic>) {
          // If it's a valid Map, assign it to greenInitiativeList and selectedGreenInitiative
          greenInitiativeList = [data];  // Wrap the object in a list as it's being treated as a list
          selectedGreenInitiative = greenInitiativeList.isNotEmpty ? greenInitiativeList.first : null;
          print("✅ Parsed Green Initiative: $selectedGreenInitiative");
        } else {
          print("⚠ API returned an incorrect format. Expected a Map.");
          greenInitiativeList.clear();
          selectedGreenInitiative = null;
        }
      } else {
        print("❌ Failed to fetch Green Initiative data. Status Code: ${response.statusCode}");
        greenInitiativeList.clear();
        selectedGreenInitiative = null;

        // Fallback to box storage if available
        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedGreenInitiative = selectedAirport['Green Initiative'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Green Initiative data: $e");
      greenInitiativeList.clear();
      selectedGreenInitiative = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET TARIFF DETAILS API CALL**********************************//
  Map<String, dynamic>? selectedTariff;
  List<Map<String, dynamic>> tariffList = [];

  Future<void> getTariffDetialsApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getTariffUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        // Instead of checking if data is List, check if it's a Map.
        if (data is Map<String, dynamic>) {
          // If it's a valid Map, assign it to greenInitiativeList and selectedGreenInitiative
          tariffList = [data];  // Wrap the object in a list as it's being treated as a list
          selectedTariff = tariffList.isNotEmpty ? tariffList.first : null;
          print("✅ Parsed Tariff Details: $selectedTariff");
        } else {
          print("⚠ API returned an incorrect format. Expected a Map.");
          tariffList.clear();
          selectedTariff = null;
        }
      } else {
        print("❌ Failed to fetch Tariff Details data. Status Code: ${response.statusCode}");
        tariffList.clear();
        selectedTariff = null;

        // Fallback to box storage if available
        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedTariff = selectedAirport['Tariff Details'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Tariff Details data: $e");
      tariffList.clear();
      selectedTariff = null;
    }

    notifyListeners(); // Notify UI about the update
  }


  //********************************GET RATING API CALL**********************************//
  Map<String, dynamic>? selectedRating;
  List<Map<String, dynamic>> ratingList = [];

  Future<void> getRatingApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getRatingUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        // Instead of checking if data is List, check if it's a Map.
        if (data is Map<String, dynamic>) {
          // If it's a valid Map, assign it to greenInitiativeList and selectedGreenInitiative
          ratingList = [data];  // Wrap the object in a list as it's being treated as a list
          selectedRating = ratingList.isNotEmpty ? ratingList.first : null;
          print("✅ Parsed Rating: $selectedRating");
        } else {
          print("⚠ API returned an incorrect format. Expected a Map.");
          ratingList.clear();
          selectedRating = null;
        }
      } else {
        print("❌ Failed to fetch Rating data. Status Code: ${response.statusCode}");
        ratingList.clear();
        selectedRating = null;

        // Fallback to box storage if available
        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedRating = selectedAirport['Rating'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Rating data: $e");
      ratingList.clear();
      selectedRating = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET TECH INITIATIVE API CALL**********************************//
  List<Map<String, dynamic>>? selectedTechInitiative;

  List<Map<String, dynamic>> techInitiativeList = [];

  Future<void> getTechInitiativeApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getTechInitiativeUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data");

        if (data is List) {
          // Safe cast each item to Map<String, dynamic>
          techInitiativeList = List<Map<String, dynamic>>.from(data);
          selectedTechInitiative = techInitiativeList;
          print("✅ Parsed Technology Initiative: $selectedTechInitiative");
        } else {
          print("⚠ API returned an incorrect format. Expected a List.");
          techInitiativeList.clear();
          selectedTechInitiative = null;
        }
      } else {
        print("❌ Failed to fetch Technology Initiative data. Status Code: ${response.statusCode}");
        techInitiativeList.clear();
        selectedTechInitiative = null;

        // Optional: fallback from local storage if available
        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedTechInitiative = List<Map<String, dynamic>>.from(
              selectedAirport['Technology Initiative'] ?? [],
            );
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Technology Initiative data: $e");
      techInitiativeList.clear();
      selectedTechInitiative = null;
    }

    notifyListeners(); // Notify UI
  }

  //********************************GET OTP ARRIVAL  API CALL**********************************//
  Map<String, dynamic>? selectedOtp;
  List<Map<String, dynamic>> otpList = [];

  Future<void> getOtpArrivalApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getOTPUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
          "Type":"ARR",
          "Date":"02/APR/2025"
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        // Instead of checking if data is List, check if it's a Map.
        if (data is Map<String, dynamic>) {
          // If it's a valid Map, assign it to greenInitiativeList and selectedGreenInitiative
          otpList = [data];  // Wrap the object in a list as it's being treated as a list
          selectedOtp = otpList.isNotEmpty ? otpList.first : null;
          _updateCombinedOtp();
          print("✅ Parsed OTP: $selectedOtp");
        } else {
          print("⚠ API returned an incorrect format. Expected a Map.");
          otpList.clear();
          selectedOtp = null;
        }
      } else {
        print("❌ Failed to fetch OTP data. Status Code: ${response.statusCode}");
        otpList.clear();
        selectedOtp = null;

        // Fallback to box storage if available
        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedOtp = selectedAirport['OTP'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching OTP data: $e");
      otpList.clear();
      selectedOtp = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET OTP DEPARTURE  API CALL**********************************//
  Map<String, dynamic>? selectedOtpDep;
  List<Map<String, dynamic>> otpDepList = [];

  Future<void> getOtpDepartureApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getOTPUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
          "Type":"DEP",
          "Date":"02/APR/2025"
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        // Instead of checking if data is List, check if it's a Map.
        if (data is Map<String, dynamic>) {
          otpDepList = [data];  // ✅ correct list for departure
          selectedOtpDep = otpDepList.isNotEmpty ? otpDepList.first : null;
          _updateCombinedOtp(); // if this uses both arrival and departure, it's okay
          print("✅ Parsed Departure OTP: $selectedOtpDep");
        }
        else {
          print("⚠ API returned an incorrect format. Expected a Map.");
          otpList.clear();
          selectedOtp = null;
        }
      } else {
        print("❌ Failed to fetch OTP data. Status Code: ${response.statusCode}");
        otpList.clear();
        selectedOtp = null;

        // Fallback to box storage if available
        if (box != null) {
          List airports = box.get('airports');
          if (airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedOtp = selectedAirport['OTP'];
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching OTP data: $e");
      otpList.clear();
      selectedOtp = null;
    }

    notifyListeners(); // Notify UI about the update
  }


  //********************************GET PROJECT INCHARGE API CALL**********************************//
  Map<String, dynamic>? selectedProjectIncharge;
  List<Map<String, dynamic>> projectInchargeList = [];

  Future<void> getProjectInchargeApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getInChargeUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is List) {
          projectInchargeList = data.cast<Map<String, dynamic>>();
          selectedProjectIncharge = projectInchargeList.isNotEmpty ? projectInchargeList.first : null;
          print("✅ Parsed Project InCharge: $selectedProjectIncharge");
        } else {
          print("⚠ API returned an incorrect format.");
          projectInchargeList.clear();
          selectedProjectIncharge = null;
          if(box != null) {
            List airports = box.get('airports');
            if(airports.any((a) => a[0] == airportCd)) {
              var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
              selectedProjectIncharge = selectedAirport['Project Incharge'];
            }
          }
        }
      } else {
        print("❌ Failed to fetch Project InCharge data. Status Code: ${response.statusCode}");
        projectInchargeList.clear();
        selectedProjectIncharge = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedProjectIncharge = selectedAirport['Project Incharge'];
          }
        }

      }
    } catch (e) {
      print("🚨 Error fetching Project InCharge data: $e");
      projectInchargeList.clear();
      selectedProjectIncharge = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET MOVEMENT DETAILS API CALL**********************************//
  MovemenetDetailsModel? selectedMovementDetails;
  List<MovemenetDetailsModel> movementDetailsList = [];

  Future<void> getMovementDetailsListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getMovementDetailsUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is Map<String, dynamic> && data.containsKey('financialData')) {
          movementDetailsList = [
            MovemenetDetailsModel.fromJson(data as Map<String, dynamic>)
          ];
          selectedMovementDetails = movementDetailsList.first;
          print("✅ Parsed Movement Details: ${selectedMovementDetails?.financialData?.length}");
        } else if (data is List) {
          movementDetailsList = data
              .map((e) => MovemenetDetailsModel.fromJson(e as Map<String, dynamic>))
              .toList();
          selectedMovementDetails = movementDetailsList.isNotEmpty ? movementDetailsList.first : null;
        } else {
          print("⚠ API returned an incorrect format.");
          movementDetailsList.clear();
          selectedMovementDetails = null;
        }
      } else {
        print("❌ Failed to fetch passenger footfall data. Status Code: ${response.statusCode}");
        movementDetailsList.clear();
        selectedMovementDetails = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedMovementDetails = MovemenetDetailsModel.fromJson(selectedAirport['Movement Details']);
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching passenger footfall data: $e");
      movementDetailsList.clear();
      selectedMovementDetails = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET CARGO TONNAGE API CALL**********************************//
  CargoTonnageModel? selectedCargoTonnage;
  List<CargoTonnageModel> cargoTonnageList = [];

  Future<void> getCargoTonnageListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getCargoTonnageUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is Map<String, dynamic> && data.containsKey('financialData')) {
          cargoTonnageList = [
            CargoTonnageModel.fromJson(data as Map<String, dynamic>)
          ];
          selectedCargoTonnage = cargoTonnageList.first;
          print("✅ Parsed Cargo Tonnage Details: ${selectedCargoTonnage?.financialData?.length}");
        } else if (data is List) {
          cargoTonnageList = data
              .map((e) => CargoTonnageModel.fromJson(e as Map<String, dynamic>))
              .toList();
          selectedCargoTonnage = cargoTonnageList.isNotEmpty ? cargoTonnageList.first : null;
        } else {
          print("⚠ API returned an incorrect format.");
          cargoTonnageList.clear();
          selectedCargoTonnage = null;
        }
      } else {
        print("❌ Failed to fetch cargo Tonnage data. Status Code: ${response.statusCode}");
        cargoTonnageList.clear();
        selectedCargoTonnage = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedCargoTonnage = CargoTonnageModel.fromJson(selectedAirport['Cargo Tonnage(MT)']);
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching passenger footfall data: $e");
      cargoTonnageList.clear();
      selectedCargoTonnage = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET ARRIVAL SCHEDULE API CALL**********************************//
  ArrivalSchedulesModel? selectedArrivalSchedules;
  List<ArrivalSchedulesModel> arrivalSchedulesList = [];

  Future<void> getArrivalSchedulesListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getArrSchedulesUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
          "ArrDate":"14 MAY 2025"
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is Map<String, dynamic> && data.containsKey('ArrivalSchedules')) {
          arrivalSchedulesList = [
            ArrivalSchedulesModel.fromJson(data as Map<String, dynamic>)
          ];
          selectedArrivalSchedules = arrivalSchedulesList.first;
          print("✅ Parsed Arrival Schedule Details: ${selectedArrivalSchedules?.arrivalSchedules?.length}");
        } else if (data is List) {
          arrivalSchedulesList = data
              .map((e) => ArrivalSchedulesModel.fromJson(e as Map<String, dynamic>))
              .toList();
          selectedArrivalSchedules = arrivalSchedulesList.isNotEmpty ? arrivalSchedulesList.first : null;
        } else {
          print("⚠ API returned an incorrect format.");
          arrivalSchedulesList.clear();
          selectedArrivalSchedules = null;
        }
      } else {
        print("❌ Failed to fetch Arrival Schedule data. Status Code: ${response.statusCode}");
        arrivalSchedulesList.clear();
        selectedArrivalSchedules = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedArrivalSchedules = ArrivalSchedulesModel.fromJson(selectedAirport['Arrival Flight Schedules']);
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Arrival Schedule data: $e");
      arrivalSchedulesList.clear();
      selectedArrivalSchedules = null;
    }

    notifyListeners(); // Notify UI about the update
  }

  //********************************GET DEPARTURE SCHEDULE API CALL**********************************//
  DepartureSchedulesModel? selectedDepartureSchedules;
  List<DepartureSchedulesModel> departureSchedulesList = [];

  Future<void> getDepartureSchedulesListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
        isLoading: false,
        apiUrl: AppUrls.getDepSchedulesUrl,
        apiFunType: APITypes.post,
        sendingData: <String, dynamic>{
          "airportCd": airportCd,
          "DepDate":"14 MAY 2025"
        },
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        print("🔍 API Response: $data"); // Debugging

        if (data is Map<String, dynamic> && data.containsKey('DepartureSchedules')) {
          departureSchedulesList = [
            DepartureSchedulesModel.fromJson(data)
          ];
          selectedDepartureSchedules = departureSchedulesList.first;
          print("✅ Parsed Departure Schedule Details: ${selectedDepartureSchedules?.departureSchedules?.length}");
        } else if (data is List) {
          departureSchedulesList = data
              .map((e) => DepartureSchedulesModel.fromJson(e as Map<String, dynamic>))
              .toList();
          selectedDepartureSchedules = departureSchedulesList.isNotEmpty ? departureSchedulesList.first : null;
        } else {
          print("⚠ API returned an incorrect format.");
          departureSchedulesList.clear();
          selectedDepartureSchedules = null;
        }
      } else {
        print("❌ Failed to fetch Departure Schedule data. Status Code: ${response.statusCode}");
        departureSchedulesList.clear();
        selectedDepartureSchedules = null;
        if(box != null) {
          List airports = box.get('airports');
          if(airports.any((a) => a[0] == airportCd)) {
            var selectedAirport = jsonDecode(jsonEncode(airports.firstWhere((a) => a[0] == airportCd)[1]));
            selectedDepartureSchedules = DepartureSchedulesModel.fromJson(selectedAirport['Departure Flight Schedules']);
          }
        }
      }
    } catch (e) {
      print("🚨 Error fetching Departure Schedule data: $e");
      departureSchedulesList.clear();
      selectedDepartureSchedules = null;
    }

    notifyListeners(); // Notify UI about the update
  }


  //********************************GET ALL AIRPORT IMAGES API CALL**********************************//
  // List<AllAirportsImagesModel> allAirportsImagesList =
  // <AllAirportsImagesModel>[];
  List<String> allAirportsImagesList = [];
  Future<void> getAllAirportsImagesListApiCall({required String airportCd}) async {
    try {
      final HTTPResponse<dynamic> response = await ApiCalling.callApi(
          isLoading: false,
          apiUrl: AppUrls.getAllAirportsImagesUrl,
          apiFunType: APITypes.post,
          sendingData: <String?, dynamic>{
            "airportCd": airportCd
          }
      );

      if (response.statusCode == 200) {
        final dynamic data = response.body;
        // print("data: $data");

        if (data.containsKey('imagePath') && data['imagePath'] is List) {
          final List<dynamic> imagesList = data['imagePath']; // Extract list
          // print("object: $imagesList");


          allAirportsImagesList = imagesList
              .map((e) => e.toString()) // Convert each element to String
              .toList();

          // Ensure all elements in the list are Strings before mapping
          // allAirportsImagesList = imagesList
          //     .whereType<String>() // Filter only strings
          //     .map((item) => AllAirportsImagesModel(imagePath: item))
          //     .toList();

          // print("object2: ${allAirportsImagesList}");
        } else {
          print("⚠ API response does not contain 'imagePath' as a list");
          allAirportsImagesList = [];
        }
      } else {
        print("❌ Failed to fetch images. Status Code: ${response.statusCode}");
        allAirportsImagesList = [];
      }

      //   }
      // } else {
      //   print("❌ Failed to fetch images. Status Code: ${response.statusCode}");
      //   allAirportsImagesList = [];
      // }
    } catch (e) {
      print("🚨 Error fetching airport images: $e");
      allAirportsImagesList = [];
    }
  }
  void notifyToAllValues() => notifyListeners();
}
