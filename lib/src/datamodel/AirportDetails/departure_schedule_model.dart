class DepartureSchedulesModel {
  List<DepartureSchedules>? departureSchedules;

  DepartureSchedulesModel({this.departureSchedules});

  DepartureSchedulesModel.fromJson(Map<String, dynamic> json) {
    if (json['DepartureSchedules'] != null) {
      departureSchedules = <DepartureSchedules>[];
      json['DepartureSchedules'].forEach((v) {
        departureSchedules!.add(new DepartureSchedules.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.departureSchedules != null) {
      data['DepartureSchedules'] =
          this.departureSchedules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class DepartureSchedules {
  String? flightNumber;
  String? operatorName;
  String? nature;
  String? location;

  DepartureSchedules(
      {this.flightNumber, this.operatorName, this.nature, this.location});

  DepartureSchedules.fromJson(Map<String, dynamic> json) {
    flightNumber = json['flightNumber'];
    operatorName = json['operatorName'];
    nature = json['nature'];
    location = json['location'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['flightNumber'] = this.flightNumber;
    data['operatorName'] = this.operatorName;
    data['nature'] = this.nature;
    data['location'] = this.location;
    return data;
  }
}
