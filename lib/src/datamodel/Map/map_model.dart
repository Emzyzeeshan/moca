class MapModel {
  List<MapMarkers>? mapMarkers;

  MapModel({this.mapMarkers});

  MapModel.fromJson(Map<String, dynamic> json) {
    if (json['Map Markers'] != null) {
      mapMarkers = <MapMarkers>[];
      json['Map Markers'].forEach((v) {
        mapMarkers!.add(new MapMarkers.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.mapMarkers != null) {
      data['Map Markers'] = this.mapMarkers!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class MapMarkers {
  String? airportCd;
  String? airportName;
  String? airportType;
  String? lat;
  String? lng;

  MapMarkers(
      {this.airportCd, this.airportName, this.airportType, this.lat, this.lng});

  MapMarkers.fromJson(Map<String, dynamic> json) {
    airportCd = json['airportCd'];
    airportName = json['airportName'];
    airportType = json['airportType'];
    lat = json['lat'];
    lng = json['lng'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['airportCd'] = this.airportCd;
    data['airportName'] = this.airportName;
    data['airportType'] = this.airportType;
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    return data;
  }
}
