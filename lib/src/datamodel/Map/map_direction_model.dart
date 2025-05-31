class MapDirectionModel {
  List<MapMarkers>? mapMarkers;

  MapDirectionModel({this.mapMarkers});

  MapDirectionModel.fromJson(Map<String, dynamic> json) {
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
  String? lat;
  String? lng;
  String? fromLocation;
  String? toLocation;
  String? toLocationName;

  MapMarkers(
      {this.lat,
        this.lng,
        this.fromLocation,
        this.toLocation,
        this.toLocationName});

  MapMarkers.fromJson(Map<String, dynamic> json) {
    lat = json['lat'];
    lng = json['lng'];
    fromLocation = json['fromLocation'];
    toLocation = json['toLocation'];
    toLocationName = json['toLocationName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['lat'] = this.lat;
    data['lng'] = this.lng;
    data['fromLocation'] = this.fromLocation;
    data['toLocation'] = this.toLocation;
    data['toLocationName'] = this.toLocationName;
    return data;
  }
}
