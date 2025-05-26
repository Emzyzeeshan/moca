class PassengerMPPAModel {
  int? domestic;
  int? international;

  PassengerMPPAModel({this.domestic, this.international});

  PassengerMPPAModel.fromJson(Map<String, dynamic> json) {
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
