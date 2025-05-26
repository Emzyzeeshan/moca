class FilterAirportsModel {
  String? airportName;
  String? regionName;
  String? nightLanding;
  int? state;
  String? landFrom;
  String? landTo;
  String? watch;
  String? cargo;

  FilterAirportsModel(
      {this.airportName,
        this.regionName,
        this.nightLanding,
        this.state,
        this.landFrom,
        this.landTo,
        this.watch,
        this.cargo});

  FilterAirportsModel.fromJson(Map<String, dynamic> json) {
    airportName = json['airportName'];
    regionName = json['regionName'];
    nightLanding = json['nightLanding'];
    state = json['state'];
    landFrom = json['landFrom'];
    landTo = json['landTo'];
    watch = json['watch'];
    cargo = json['cargo'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['airportName'] = this.airportName;
    data['regionName'] = this.regionName;
    data['nightLanding'] = this.nightLanding;
    data['state'] = this.state;
    data['landFrom'] = this.landFrom;
    data['landTo'] = this.landTo;
    data['watch'] = this.watch;
    data['cargo'] = this.cargo;
    return data;
  }
}
