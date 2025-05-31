

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';

import '../../../core/network/network_index.dart';
import '../../../datamodel/Map/map_direction_model.dart';
import '../../../datamodel/Map/map_model.dart';

class MapProvider extends ChangeNotifier {
  bool isLoading = false;
  late Box box;
  late String airportCode;
  void isLoadData(bool isLoading) {
    this.isLoading = isLoading;
    notifyListeners();
  }

//********************************MAP LAT LNG API CALL**********************************//
  MapModel? selectedMapLatLng;
  List<MapModel> allMapLatLngList = [];
  Future<void> postMapLatLngApiCall() async{
    isLoadData(true);
    selectedMapLatLng = null;
    final HTTPResponse<dynamic> response = await ApiCalling.callApi(
      isLoading: false,
      apiUrl: AppUrls.getMapLatLngUrl,
      apiFunType: APITypes.get,
    );
    if (response.statusCode == 200) {
      final body = response.body;

      if (body is List) {
        allMapLatLngList = body.map((e) => MapModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (body is Map) {
        allMapLatLngList = [MapModel.fromJson(Map<String, dynamic>.from(body))];
      } else {
        debugPrint("Unexpected response body: $body");
      }

      debugPrint("MapLatLng Loaded: ${allMapLatLngList.length}");
      for (var m in allMapLatLngList) {
        debugPrint("Markers in model: ${m.mapMarkers?.length}");
      }
    }


    isLoadData(false);
    notifyToAllValues();
  }
  //********************************MAP LAT LNG DIRECTION API CALL**********************************//
  MapDirectionModel? selectedMapLatLngDirection;
  List<MapDirectionModel> allMapLatLngDirectionList = [];
  Future<void> postMapLatLngDirectionApiCall({required String airportCd}) async{
    isLoadData(true);
    selectedMapLatLngDirection = null;
    final HTTPResponse<dynamic> response = await ApiCalling.callApi(
      isLoading: false,
      apiUrl: AppUrls.getMapLatLngDirectionUrl,
      apiFunType: APITypes.post,
      sendingData: <String, dynamic>{
        "airportCd": airportCd,
      },
    );
    if (response.statusCode == 200) {
      final body = response.body;

      if (body is List) {
        allMapLatLngDirectionList = body.map((e) => MapDirectionModel.fromJson(Map<String, dynamic>.from(e))).toList();
      } else if (body is Map) {
        allMapLatLngDirectionList = [MapDirectionModel.fromJson(Map<String, dynamic>.from(body))];
      } else {
        debugPrint("Unexpected response body: $body");
      }

      debugPrint("MapLatLng Loaded: ${allMapLatLngDirectionList.length}");
      for (var m in allMapLatLngDirectionList) {
        debugPrint("Markers in model: ${m.mapMarkers?.length}");
      }
    }


    isLoadData(false);
    notifyToAllValues();
  }

  void notifyToAllValues() => notifyListeners();
}