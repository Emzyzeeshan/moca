class FilterAirportsModel {
  String? airportName;
  String? regionName;
  int? state;
  String? airportType;
  String? fieldType;

  FilterAirportsModel(
      {this.airportName,
        this.regionName,
        this.state,
        this.airportType,
        this.fieldType});

  FilterAirportsModel.fromJson(Map<String, dynamic> json) {
    airportName = json['airportName'];
    regionName = json['regionName'];
    state = json['state'];
    airportType = json['airportType'];
    fieldType = json['fieldType'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['airportName'] = this.airportName;
    data['regionName'] = this.regionName;
    data['state'] = this.state;
    data['airportType'] = this.airportType;
    data['fieldType'] = this.fieldType;
    return data;
  }
}
