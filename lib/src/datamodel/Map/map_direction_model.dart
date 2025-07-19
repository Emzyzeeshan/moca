class MapDirectionModel {
  List<FromLocation>? fromLocation;
  List<ToLocations>? toLocations;

  MapDirectionModel({this.fromLocation, this.toLocations});

  MapDirectionModel.fromJson(Map<String, dynamic> json) {
    if (json['From Location'] != null) {
      fromLocation = <FromLocation>[];
      json['From Location'].forEach((v) {
        fromLocation!.add(new FromLocation.fromJson(v));
      });
    }
    if (json['To Locations'] != null) {
      toLocations = <ToLocations>[];
      json['To Locations'].forEach((v) {
        toLocations!.add(new ToLocations.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.fromLocation != null) {
      data['From Location'] =
          this.fromLocation!.map((v) => v.toJson()).toList();
    }
    if (this.toLocations != null) {
      data['To Locations'] = this.toLocations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class FromLocation {
  String? fROMLOCATION;
  String? fROMLOCATIONNAME;
  String? fROMLAT;
  String? fROMLNG;
  String? aIRPORTTYPE;

  FromLocation(
      {this.fROMLOCATION,
        this.fROMLOCATIONNAME,
        this.fROMLAT,
        this.fROMLNG,
        this.aIRPORTTYPE});

  FromLocation.fromJson(Map<String, dynamic> json) {
    fROMLOCATION = json['FROMLOCATION'];
    fROMLOCATIONNAME = json['FROMLOCATIONNAME'];
    fROMLAT = json['FROMLAT'];
    fROMLNG = json['FROMLNG'];
    aIRPORTTYPE = json['AIRPORTTYPE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['FROMLOCATION'] = this.fROMLOCATION;
    data['FROMLOCATIONNAME'] = this.fROMLOCATIONNAME;
    data['FROMLAT'] = this.fROMLAT;
    data['FROMLNG'] = this.fROMLNG;
    data['AIRPORTTYPE'] = this.aIRPORTTYPE;
    return data;
  }
}

class ToLocations {
  String? tOLOCATION;
  String? tOLOCATIONNAME;
  String? tOLAT;
  String? tOLNG;
  String? aIRPORTTYPE;

  ToLocations(
      {this.tOLOCATION,
        this.tOLOCATIONNAME,
        this.tOLAT,
        this.tOLNG,
        this.aIRPORTTYPE});

  ToLocations.fromJson(Map<String, dynamic> json) {
    tOLOCATION = json['TOLOCATION'];
    tOLOCATIONNAME = json['TOLOCATIONNAME'];
    tOLAT = json['TOLAT'];
    tOLNG = json['TOLNG'];
    aIRPORTTYPE = json['AIRPORTTYPE'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['TOLOCATION'] = this.tOLOCATION;
    data['TOLOCATIONNAME'] = this.tOLOCATIONNAME;
    data['TOLAT'] = this.tOLAT;
    data['TOLNG'] = this.tOLNG;
    data['AIRPORTTYPE'] = this.aIRPORTTYPE;
    return data;
  }
}
