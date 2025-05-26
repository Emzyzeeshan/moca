class StateWiseAirportModel {
  String? airportName;
  String? stateName;
  String? stateCode;
  String? airportCd;

  StateWiseAirportModel(
      {this.airportName, this.stateName, this.stateCode, this.airportCd});

  StateWiseAirportModel.fromJson(Map<String, dynamic> json) {
    airportName = json['airportName'];
    stateName = json['stateName'];
    stateCode = json['stateCode'];
    airportCd = json['airportCd'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['airportName'] = this.airportName;
    data['stateName'] = this.stateName;
    data['stateCode'] = this.stateCode;
    data['airportCd'] = this.airportCd;
    return data;
  }
}
