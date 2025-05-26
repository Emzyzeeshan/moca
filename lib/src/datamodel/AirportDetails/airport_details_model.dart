class AirportDetailsModel {
  String? airportName;
  String? airportOwnedBy;
  String? operatedBy;
  List<String>? runways;
  String? nightLanding;
  String? digiYatra;
  String? mRO;
  String? airportType;
  String? passengerTerminalBuildingAreaInSqm;
  String? fieldType;
  String? existingLandInAcres;
  String? watchHours;

  AirportDetailsModel(
      {this.airportName,
        this.airportOwnedBy,
        this.operatedBy,
        this.runways,
        this.nightLanding,
        this.digiYatra,
        this.mRO,
        this.airportType,
        this.passengerTerminalBuildingAreaInSqm,
        this.fieldType,
        this.existingLandInAcres,
        this.watchHours});

  AirportDetailsModel.fromJson(Map<String, dynamic> json) {
    airportName = json['Airport Name'];
    airportOwnedBy = json['Airport Owned By'];
    operatedBy = json['Operated By'];
    runways = json['Runways'].cast<String>();
    nightLanding = json['Night Landing'];
    digiYatra = json['Digi Yatra'];
    mRO = json['MRO'];
    airportType = json['Airport Type'];
    passengerTerminalBuildingAreaInSqm =
    json['Passenger Terminal Building (Area)(In Sqm)'];
    fieldType = json['Field Type'];
    existingLandInAcres = json['Existing Land (In Acres)'];
    watchHours = json['Watch Hours'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Airport Name'] = this.airportName;
    data['Airport Owned By'] = this.airportOwnedBy;
    data['Operated By'] = this.operatedBy;
    data['Runways'] = this.runways;
    data['Night Landing'] = this.nightLanding;
    data['Digi Yatra'] = this.digiYatra;
    data['MRO'] = this.mRO;
    data['Airport Type'] = this.airportType;
    data['Passenger Terminal Building (Area)(In Sqm)'] =
        this.passengerTerminalBuildingAreaInSqm;
    data['Field Type'] = this.fieldType;
    data['Existing Land (In Acres)'] = this.existingLandInAcres;
    data['Watch Hours'] = this.watchHours;
    return data;
  }
}
