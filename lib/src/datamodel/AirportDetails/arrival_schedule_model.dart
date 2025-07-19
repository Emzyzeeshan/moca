class ArrivalSchedulesModel {
  List<ArrivalSchedules>? arrivalSchedules;

  ArrivalSchedulesModel({this.arrivalSchedules});

  ArrivalSchedulesModel.fromJson(Map<String, dynamic> json) {
    if (json['ArrivalSchedules'] != null) {
      arrivalSchedules = <ArrivalSchedules>[];
      json['ArrivalSchedules'].forEach((v) {
        arrivalSchedules!.add(new ArrivalSchedules.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.arrivalSchedules != null) {
      data['ArrivalSchedules'] =
          this.arrivalSchedules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class ArrivalSchedules {
  String? flightNumber;
  String? operatorName;
  String? nature;
  String? location;

  ArrivalSchedules(
      {this.flightNumber, this.operatorName, this.nature, this.location});

  ArrivalSchedules.fromJson(Map<String, dynamic> json) {
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
