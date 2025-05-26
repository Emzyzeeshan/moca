class PassengerPeakModel {
  int? domestic;
  int? international;

  PassengerPeakModel({this.domestic, this.international});

  PassengerPeakModel.fromJson(Map<String, dynamic> json) {
    domestic = json['Domestic'];
    international = json['International'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['Domestic'] = this.domestic;
    data['International'] = this.international;
    return data;
  }
}
