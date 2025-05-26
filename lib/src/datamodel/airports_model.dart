class AllAirportsModel {
  String? airportCd;
  String? airportName;

  AllAirportsModel({this.airportCd, this.airportName});

  AllAirportsModel.fromJson(Map<String, dynamic> json) {
    airportCd = json['airportCd'];
    airportName = json['airportName'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['airportCd'] = this.airportCd;
    data['airportName'] = this.airportName;
    return data;
  }
}
