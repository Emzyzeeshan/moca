class AirportDetailsModel {
  String? airportOwnedBy;
  List<String>? runways;
  String? nightLanding;
  String? digiYatra;
  String? apron;
  String? mRO;
  String? fieldType;
  String? watchHours;
  String? airportName;
  String? palannedInaugurationDate;
  String? operatedBy;
  String? intitialInaugurationDate;
  String? airportType;
  String? passengerTerminalBuildingAreaInSqm;
  String? existingLandInAcres;

  AirportDetailsModel(
      {this.airportOwnedBy,
        this.runways,
        this.nightLanding,
        this.digiYatra,
        this.apron,
        this.mRO,
        this.fieldType,
        this.watchHours,
        this.airportName,
        this.palannedInaugurationDate,
        this.operatedBy,
        this.intitialInaugurationDate,
        this.airportType,
        this.passengerTerminalBuildingAreaInSqm,
        this.existingLandInAcres});

  AirportDetailsModel.fromJson(Map<String, dynamic> json) {
    airportOwnedBy = json['Airport Owned By'];
    runways = json['Runways'].cast<String>();
    nightLanding = json['Night Landing'];
    digiYatra = json['Digi Yatra'];
    apron = json['Apron'];
    mRO = json['MRO'];
    fieldType = json['Field Type'];
    watchHours = json['Watch Hours'];
    airportName = json['Airport Name'];
    palannedInaugurationDate = json['Palanned Inauguration Date'];
    operatedBy = json['Operated By'];
    intitialInaugurationDate = json['Intitial Inauguration Date'];
    airportType = json['Airport Type'];
    passengerTerminalBuildingAreaInSqm =
    json['Passenger Terminal Building (Area)(In Sqm)'];
    existingLandInAcres = json['Existing Land (In Acres)'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Airport Owned By'] = this.airportOwnedBy;
    data['Runways'] = this.runways;
    data['Night Landing'] = this.nightLanding;
    data['Digi Yatra'] = this.digiYatra;
    data['Apron'] = this.apron;
    data['MRO'] = this.mRO;
    data['Field Type'] = this.fieldType;
    data['Watch Hours'] = this.watchHours;
    data['Airport Name'] = this.airportName;
    data['Palanned Inauguration Date'] = this.palannedInaugurationDate;
    data['Operated By'] = this.operatedBy;
    data['Intitial Inauguration Date'] = this.intitialInaugurationDate;
    data['Airport Type'] = this.airportType;
    data['Passenger Terminal Building (Area)(In Sqm)'] =
        this.passengerTerminalBuildingAreaInSqm;
    data['Existing Land (In Acres)'] = this.existingLandInAcres;
    return data;
  }
}
