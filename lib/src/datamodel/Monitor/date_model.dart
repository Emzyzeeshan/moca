class DateModel {
  String? mocadbDate;

  DateModel({this.mocadbDate});

  DateModel.fromJson(Map<String, dynamic> json) {
    mocadbDate = json['mocadbDate'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['mocadbDate'] = this.mocadbDate;
    return data;
  }
}
